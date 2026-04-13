import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { GeoFirestore } from 'geofirestore';
import * as geofire from 'geofire-common';

admin.initializeApp();
const db = admin.firestore();
const geoFirestore = new GeoFirestore(db);

// Sri Lankan service zones (matching your app constants)
const SERVICE_ZONES = {
    'col_03_04': { center: { lat: 6.8940, lng: 79.8580 }, radiusKm: 2.5 },
    'col_07': { center: { lat: 6.9119, lng: 79.8716 }, radiusKm: 3.0 },
    'rajagiriya': { center: { lat: 6.9108, lng: 79.8927 }, radiusKm: 2.0 }
};

interface WorkerLocation {
    workerId: string;
    lat: number;
    lng: number;
    skills: string[];
    lastJobCompletedAt: admin.firestore.Timestamp | null;
    homeLocation: { latitude: number; longitude: number };
    rating: number;
}

interface JobRequest {
    jobId: string;
    customerId: string;
    serviceType: string;
    zoneId: string;
    location: admin.firestore.GeoPoint;
    houseNumber: string;
    landmark?: string;
    estimatedEarnings: number;
    createdAt: admin.firestore.Timestamp;
}

/**
 * Main Dispatch Function - Triggered when customer creates job
 * Picks top 3 workers and broadcasts simultaneously
 */
export const dispatchJob = functions.firestore
    .document('job_requests/{jobId}')
    .onCreate(async (snap, context) => {
        const job = snap.data() as JobRequest;
        const jobId = context.params.jobId;

        console.log(`🚀 Dispatching job ${jobId} for ${job.serviceType} in ${job.zoneId}`);

        try {
            // 1. Validate zone
            if (!SERVICE_ZONES[job.zoneId]) {
                console.error('Invalid zone:', job.zoneId);
                await snap.ref.update({ status: 'failed', error: 'Invalid zone' });
                return;
            }

            // 2. Find online workers with matching skills in zone
            const candidates = await findEligibleWorkers(job);

            if (candidates.length === 0) {
                console.log('❌ No workers available');
                await snap.ref.update({
                    status: 'no_workers_available',
                    searchable: false
                });

                // Notify customer
                await notifyCustomerNoWorkers(job.customerId, jobId);
                return;
            }

            // 3. Score and rank candidates (PickMe algorithm)
            const scoredWorkers = scoreWorkers(candidates, job);
            const top3 = scoredWorkers.slice(0, 3);

            console.log(`📋 Top candidates: ${top3.map(w => w.workerId).join(', ')}`);

            // 4. Create job offer documents (race condition setup)
            const offers = top3.map((worker, index) => ({
                jobId: jobId,
                workerId: worker.workerId,
                status: 'pending', // pending -> accepted | rejected | timeout
                offeredAt: admin.firestore.FieldValue.serverTimestamp(),
                expiresAt: admin.firestore.Timestamp.fromMillis(
                    Date.now() + 30000 // 30 seconds to accept
                ),
                priority: index + 1, // 1 = first choice
                estimatedEarnings: job.estimatedEarnings,
                distanceKm: worker.distanceToCustomer,
                customerLocation: job.location,
                serviceType: job.serviceType,
                houseNumber: job.houseNumber,
                landmark: job.landmark || ''
            }));

            // 5. Write offers to Firestore (triggers push notifications)
            const batch = db.batch();
            offers.forEach((offer, idx) => {
                const ref = db.collection('job_offers').doc(`${jobId}_${top3[idx].workerId}`);
                batch.set(ref, offer);
            });

            // Update job status
            batch.update(snap.ref, {
                status: 'dispatching',
                dispatchedTo: top3.map(w => w.workerId),
                dispatchedAt: admin.firestore.FieldValue.serverTimestamp(),
                offerCount: offers.length
            });

            await batch.commit();

            // 6. Schedule cleanup job (if no one accepts in 35s)
            setTimeout(async () => {
                await handleOfferTimeout(jobId, top3.map(w => w.workerId));
            }, 35000);

        } catch (error) {
            console.error('Dispatch error:', error);
            await snap.ref.update({ status: 'error', error: error.message });
        }
    });

/**
 * Find workers who are online, verified, in correct zone, with matching skills
 */
async function findEligibleWorkers(job: JobRequest): Promise<WorkerLocation[]> {
    const zone = SERVICE_ZONES[job.zoneId];

    // Query: Online workers in geohash range (approximate, then filter precisely)
    const center = [zone.center.lat, zone.center.lng];
    const radiusInM = zone.radiusKm * 1000;

    // Get bounds for geohash query
    const bounds = geofire.geohashQueryBounds(center, radiusInM);
    const promises = bounds.map(b => {
        return db.collection('worker_locations')
            .where('status', '==', 'online')
            .where('geohash', '>=', b[0])
            .where('geohash', '<=', b[1])
            .get();
    });

    const snapshots = await Promise.all(promises);
    const candidates: WorkerLocation[] = [];

    snapshots.forEach(snap => {
        snap.docs.forEach(doc => {
            const data = doc.data() as any;

            // Precise distance calculation
            const distanceInKm = geofire.getDistance(
                [data.lat, data.lng],
                [job.location.latitude, job.location.longitude]
            ) / 1000;

            // Filters
            if (distanceInKm > 5) return; // Max 5km from customer
            if (!data.skills.includes(job.serviceType)) return;
            if (!data.isVerified) return;

            candidates.push({
                workerId: doc.id,
                lat: data.lat,
                lng: data.lng,
                skills: data.skills,
                lastJobCompletedAt: data.lastJobCompletedAt,
                homeLocation: data.homeLocation,
                rating: data.rating || 4.0,
                distanceToCustomer: distanceInKm
            } as WorkerLocation);
        });
    });

    return candidates;
}

/**
 * Score workers by: proximity (50%), idle time (30%), home distance (20%)
 */
function scoreWorkers(workers: WorkerLocation[], job: JobRequest) {
    return workers.map(worker => {
        // Factor 1: Distance to customer (closer = better)
        const distanceScore = 1 / (worker.distanceToCustomer + 0.1); // +0.1 avoid div by zero

        // Factor 2: Idle time (workers who just finished get priority - PickMe style)
        let idleScore = 0;
        if (worker.lastJobCompletedAt) {
            const idleMinutes = (Date.now() - worker.lastJobCompletedAt.toMillis()) / 60000;
            idleScore = Math.min(idleMinutes / 60, 2); // Cap at 2 hours
        } else {
            idleScore = 2; // Never worked = high priority
        }

        // Factor 3: Distance from home (don't send too far from home base)
        const homeDistKm = geofire.getDistance(
            [worker.lat, worker.lng],
            [worker.homeLocation.latitude, worker.homeLocation.longitude]
        ) / 1000;
        const homeScore = 1 / (homeDistKm + 0.1);

        // Weighted score
        const finalScore = (distanceScore * 0.5) + (idleScore * 0.3) + (homeScore * 0.2);

        return { ...worker, score: finalScore, distanceToCustomer: worker.distanceToCustomer };
    }).sort((a, b) => b.score - a.score);
}

/**
 * Handle worker accepting job (race condition resolver)
 */
export const acceptJob = functions.https.onCall(async (data, context) => {
    const { jobId, workerId } = data;

    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Login required');
    }

    const jobRef = db.collection('job_requests').doc(jobId);
    const offerRef = db.collection('job_offers').doc(`${jobId}_${workerId}`);

    return db.runTransaction(async (transaction) => {
        const jobDoc = await transaction.get(jobRef);
        const offerDoc = await transaction.get(offerRef);

        if (!jobDoc.exists) throw new Error('Job not found');
        if (!offerDoc.exists) throw new Error('Offer not found');

        const jobData = jobDoc.data() as JobRequest;
        const offerData = offerDoc.data() as any;

        // Check if already assigned
        if (jobData.status === 'assigned' || jobData.status === 'accepted') {
            throw new functions.https.HttpsError('failed-precondition', 'Job already taken');
        }

        // Check offer expiration
        if (offerData.status !== 'pending') {
            throw new functions.https.HttpsError('failed-precondition', 'Offer expired');
        }

        // WINNER! Assign job to this worker
        transaction.update(jobRef, {
            status: 'assigned',
            assignedWorkerId: workerId,
            assignedAt: admin.firestore.FieldValue.serverTimestamp(),
            acceptedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        transaction.update(offerRef, { status: 'accepted' });

        // Cancel other offers
        const otherOffers = await db.collection('job_offers')
            .where('jobId', '==', jobId)
            .where('status', '==', 'pending')
            .get();

        otherOffers.docs.forEach(doc => {
            if (doc.id !== `${jobId}_${workerId}`) {
                transaction.update(doc.ref, { status: 'rejected', reason: 'another_worker_accepted' });
            }
        });

        // Update worker status to busy
        transaction.update(db.collection('workers').doc(workerId), {
            currentJobId: jobId,
            isAvailable: false
        });

        // Notify customer
        await notifyCustomerWorkerAssigned(jobData.customerId, workerId, jobId);

        return { success: true, message: 'Job assigned' };
    });
});

/**
 * Handle timeout - if no one accepts, extend radius or notify customer
 */
async function handleOfferTimeout(jobId: string, workerIds: string[]) {
    const jobRef = db.collection('job_requests').doc(jobId);
    const job = await jobRef.get();

    if (!job.exists) return;
    const jobData = job.data() as JobRequest;

    // If already assigned, do nothing
    if (jobData.status === 'assigned') return;

    console.log(`⏰ Job ${jobId} timed out, attempting retry...`);

    // Mark offers as expired
    const batch = db.batch();
    workerIds.forEach(id => {
        const ref = db.collection('job_offers').doc(`${jobId}_${id}`);
        batch.update(ref, { status: 'expired' });
    });

    // Try to find more workers (wider radius) or fail
    if (jobData.offerCount < 6) { // Max 2 rounds of dispatch
        batch.update(jobRef, {
            status: 'searching_extended',
            retryCount: (jobData.retryCount || 0) + 1
        });
        await batch.commit();

        // Trigger new search with wider radius (implementation omitted for brevity)
    } else {
        batch.update(jobRef, { status: 'no_workers_available' });
        await batch.commit();
        await notifyCustomerNoWorkers(jobData.customerId, jobId);
    }
}

/**
 * SMS Fallback for workers without data (Sri Lanka specific)
 */
async function notifyViaSMS(phoneNumber: string, message: string) {
    // Integration with Notify.lk or similar Sri Lankan gateway
    console.log(`📱 SMS to ${phoneNumber}: ${message}`);
    // Implementation: Call Notify.lk API here
}

async function notifyCustomerNoWorkers(customerId: string, jobId: string) {
    await db.collection('notifications').add({
        userId: customerId,
        type: 'no_workers_available',
        title: 'No helpers available',
        body: 'We could not find available workers in your area. Please try again later.',
        jobId: jobId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false
    });
}

async function notifyCustomerWorkerAssigned(customerId: string, workerId: string, jobId: string) {
    const worker = await db.collection('workers').doc(workerId).get();
    const workerData = worker.data();

    await db.collection('notifications').add({
        userId: customerId,
        type: 'worker_assigned',
        title: 'Helper found!',
        body: `${workerData?.fullName} is on the way`,
        jobId: jobId,
        workerId: workerId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false
    });
}
// Export PayHere webhook
export { payhereNotify, checkPaymentStatus } from "./payhereWebhook";

// Sprint 5: Security Hardening - Rate Limiting
export { 
  requestOTP, 
  createJob,
  checkRateLimit,
  withRateLimit,
  withHttpRateLimit 
} from "./rateLimit";

// Sprint 5: Security Hardening - Scheduled Functions
export {
  cleanupRateLimitsDaily,
  cleanupExpiredOTPs,
  cleanupOldJobOffers,
  cleanupOldMessages,
  archiveOldJobs,
  detectSuspiciousActivity,
} from "./securityScheduled";

// Phase 6: DevOps & Monitoring - Backup Functions
export {
  scheduledFirestoreBackup,
  manualBackup,
  listBackups,
  restoreFromBackup,
} from "./backup";

// Phase 6: DevOps & Monitoring - Health Check Functions
export {
  healthCheck,
  getSystemHealth,
  ping,
  ready,
  live,
} from "./health";

// Phase 7: Business Features - Referral System
export {
  processReferralOnSignup,
  completeReferralOnBooking,
  generateReferralCode,
  cleanupExpiredReferrals,
  getReferralStats,
  getLeaderboard,
} from "./referral";
