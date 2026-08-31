import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as geofire from 'geofire-common';

admin.initializeApp();
const db = admin.firestore();

// Sri Lankan service zones (matching your app constants)
const SERVICE_ZONES: Record<string, { center: { lat: number; lng: number }; radiusKm: number }> = {
    'col_03_04': { center: { lat: 6.8940, lng: 79.8580 }, radiusKm: 2.5 },
    'col_07': { center: { lat: 6.9119, lng: 79.8716 }, radiusKm: 3.0 },
    'rajagiriya': { center: { lat: 6.9108, lng: 79.8927 }, radiusKm: 2.0 },
};

interface WorkerLocation {
    workerId: string;
    lat: number;
    lng: number;
    skills: string[];
    lastJobCompletedAt: admin.firestore.Timestamp | null;
    homeLocation: { latitude: number; longitude: number };
    rating: number;
    distanceToCustomer?: number;
}

interface JobRequest {
    jobId?: string;
    bookingId?: string;
    customerId: string;
    serviceType: string;
    zoneId: string;
    location: admin.firestore.GeoPoint;
    houseNumber: string;
    landmark?: string;
    estimatedEarnings: number;
    createdAt: admin.firestore.Timestamp;
    status?: string;
    offerCount?: number;
    retryCount?: number;
}

/**
 * Gate 0: `bookings` is the single source of truth for booking state and
 * worker assignment — job_requests/job_offers below are an internal
 * matching/offer mechanism only. Every place that mutates a job_requests
 * document in a way that should be visible to the customer/worker apps
 * (offers went out, a worker was assigned, matching failed) must also write
 * the corresponding, minimal update to the linked `bookings/{bookingId}`
 * document in the same operation, so the two can never drift apart. This
 * helper centralizes that so it isn't duplicated (and isn't forgotten) at
 * each call site.
 */
function syncBookingRef(bookingId: string | undefined) {
    return bookingId ? db.collection('bookings').doc(bookingId) : null;
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

                const bookingRef = syncBookingRef(job.bookingId);
                if (bookingRef) {
                    await bookingRef.update({ noWorkersAvailable: true });
                }

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

            // Gate 0: mirror the offer onto the canonical booking so the
            // customer app can show "offers sent" and acceptJob has an
            // authoritative offeredWorkerIds list to check the accepting
            // worker against.
            const bookingRef = syncBookingRef(job.bookingId);
            if (bookingRef) {
                batch.update(bookingRef, {
                    offeredWorkerIds: top3.map(w => w.workerId),
                });
            }

            await batch.commit();

            // 6. Schedule cleanup job (if no one accepts in 35s)
            setTimeout(async () => {
                await handleOfferTimeout(jobId, top3.map(w => w.workerId));
            }, 35000);

        } catch (error) {
            console.error('Dispatch error:', error);
            await snap.ref.update({ status: 'error', error: String(error) });
        }
    });

/**
 * Find workers who are online, verified, in correct zone, with matching skills
 */
async function findEligibleWorkers(job: JobRequest): Promise<WorkerLocation[]> {
    const zone = SERVICE_ZONES[job.zoneId];

    // Query: Online workers in geohash range (approximate, then filter precisely)
    const center: [number, number] = [zone.center.lat, zone.center.lng];
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
            const distanceInKm = geofire.distanceBetween(
                [data.lat as number, data.lng as number] as [number, number],
                [job.location.latitude, job.location.longitude] as [number, number],
            );

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
        const distanceScore = 1 / ((worker.distanceToCustomer ?? 1) + 0.1);

        // Factor 2: Idle time (workers who just finished get priority - PickMe style)
        let idleScore = 0;
        if (worker.lastJobCompletedAt) {
            const idleMinutes = (Date.now() - worker.lastJobCompletedAt.toMillis()) / 60000;
            idleScore = Math.min(idleMinutes / 60, 2); // Cap at 2 hours
        } else {
            idleScore = 2; // Never worked = high priority
        }

        // Factor 3: Distance from home (don't send too far from home base)
        const homeDistKm = geofire.distanceBetween(
            [worker.lat, worker.lng],
            [worker.homeLocation.latitude, worker.homeLocation.longitude],
        );
        const homeScore = 1 / (homeDistKm + 0.1);

        // Weighted score
        const finalScore = (distanceScore * 0.5) + (idleScore * 0.3) + (homeScore * 0.2);

        return { ...worker, score: finalScore, distanceToCustomer: worker.distanceToCustomer };
    }).sort((a, b) => b.score - a.score);
}

/**
 * Handle worker accepting job (race condition resolver).
 *
 * Gate 0 fix (authenticated worker acceptance, CRITICAL): this function used
 * to take `workerId` from the client-supplied `data` payload and trust it
 * outright — it never checked that `context.auth.uid` was the worker
 * actually accepting. Any authenticated user could call this with an
 * arbitrary workerId and assign that job to any worker of their choosing
 * (or a nonexistent one), regardless of who the offer was actually made to.
 * The only trustworthy identity here is `context.auth.uid`; the client no
 * longer needs to (and no longer can) supply which worker is accepting.
 *
 * This also now syncs the result onto the canonical `bookings` document
 * (via the `bookingId` stored on the job_requests doc), which the original
 * version never did at all — meaning a successful acceptance previously
 * left the customer-facing booking permanently stuck at its pre-assignment
 * status. `bookings` is the single source of truth for booking state; this
 * update happens inside the same transaction so the two can never diverge.
 */
export const acceptJob = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Login required');
    }
    const workerId = context.auth.uid;
    const { jobId } = data;
    if (typeof jobId !== 'string' || !jobId) {
        throw new functions.https.HttpsError('invalid-argument', 'jobId is required');
    }

    const jobRef = db.collection('job_requests').doc(jobId);
    const offerRef = db.collection('job_offers').doc(`${jobId}_${workerId}`);

    return db.runTransaction(async (transaction) => {
        const jobDoc = await transaction.get(jobRef);
        const offerDoc = await transaction.get(offerRef);

        if (!jobDoc.exists) throw new Error('Job not found');
        // Because offerRef is keyed by `${jobId}_${workerId}` and workerId is
        // now context.auth.uid, this existence check IS the "only the
        // offered provider can accept" guarantee — a worker who was never
        // offered this job has no document here to read.
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

        // Gate 0: bookings is the single source of truth — sync the
        // assignment atomically in the same transaction that decides the
        // winner, so no client ever observes a booking whose status says
        // "confirmed" without a workerId, or vice versa.
        const bookingRef = syncBookingRef(jobData.bookingId);
        if (bookingRef) {
            transaction.update(bookingRef, {
                workerId,
                status: 'confirmed',
                offeredWorkerIds: admin.firestore.FieldValue.delete(),
                confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }

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
    if ((jobData.offerCount ?? 0) < 6) { // Max 2 rounds of dispatch
        batch.update(jobRef, {
            status: 'searching_extended',
            retryCount: (jobData.retryCount || 0) + 1
        });
        await batch.commit();

        // Trigger new search with wider radius (implementation omitted for brevity)
    } else {
        batch.update(jobRef, { status: 'no_workers_available' });
        const bookingRef = syncBookingRef(jobData.bookingId);
        if (bookingRef) {
            batch.update(bookingRef, { noWorkersAvailable: true });
        }
        await batch.commit();
        await notifyCustomerNoWorkers(jobData.customerId, jobId);
    }
}

/**
 * SMS Fallback for workers without data (Sri Lanka specific).
 * TODO: wire to Notify.lk API when merchant account is approved.
 */
export async function notifyViaSMS(phoneNumber: string, message: string): Promise<void> {
    console.log(`📱 SMS to ${phoneNumber}: ${message}`);
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
export { payhereNotify, checkPaymentStatus, generatePayHereUrl } from "./payhereWebhook";

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

// Phase 8: Scheduling, Safety & Payouts
export {
  generateRecurringBookings,
  processWeeklyPayouts,
  checkMissedCheckIns,
  checkMissedCheckOuts,
  notifyUpcomingBookings,
  autoCompleteBookings,
  escalateSafetyAlert,
} from "./schedulingFunctions";

// Phase 9: Service Catalog + Wallet Escrow + Recurring Booking Management
export { seedServiceCatalog } from "./seedServiceCatalog";
export {
  holdWalletFunds,
  releaseWalletFunds,
} from "./walletFunctions";
export {
  cancelRecurringInstance,
  modifyRecurringSeries,
  verifyWorkerCheckInLocation,
  suspendWorker,
  suspendWorkerManually,
} from "./bookingManagementFunctions";

// Phase 10: Operational Functions
export {
  processRefund,
  processVerificationUpgrade,
  scheduleReverification,
  updateWorkerReliabilityScores,
  generateDailyReport,
  cleanupOldPendingBookings,
} from "./operationalFunctions";

// Phase 11: Admin governance — two-person approval
export { applyApprovedChange } from "./approvals";

// Phase 12: Session management
export { revokeOtherSessions } from "./sessions";

// Gate 0: security & core-flow stabilization
export { syncWorkerPublicProfile } from "./workerPublicProfile";
