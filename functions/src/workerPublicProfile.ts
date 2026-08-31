import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Gate 0 fix (location privacy): `workers/{workerId}` is owner+admin-only in
 * firestore.rules, correctly protecting NIC, home address, and home/live
 * coordinates — but that also means no rule anywhere grants a customer read
 * access to a provider's PUBLIC profile (name, rating, bio, services). This
 * mirrors an explicit allowlist of non-sensitive fields into
 * `worker_public_profiles/{workerId}`, which any authenticated user may
 * read (see firestore.rules) and which a client can never write directly.
 *
 * Deliberately excluded from the mirror: nic, mobileNumber, address,
 * emergencyContactName/Phone, nicFrontUrl/nicBackUrl, currentLat/currentLng,
 * homeLat/homeLng.
 */
const PUBLIC_FIELDS = [
    'fullName',
    'profilePhotoUrl',
    'services',
    'status',
    'isOnline',
    'rating',
    'totalJobs',
    'verificationTier',
    'businessName',
    'bio',
    'experienceYears',
    'serviceRadiusKm',
    'district',
    // Required by Worker.fromJson (lib/features/worker/domain/entities/worker.dart)
    // even though it's not itself sensitive — omitting it makes DateTime.parse
    // throw on the client when it builds a Worker from this mirror.
    'createdAt',
] as const;

export const syncWorkerPublicProfile = functions.firestore
    .document('workers/{workerId}')
    .onWrite(async (change, context) => {
        const workerId = context.params.workerId;
        const publicRef = db.collection('worker_public_profiles').doc(workerId);

        if (!change.after.exists) {
            await publicRef.delete().catch(() => undefined);
            return;
        }

        const data = change.after.data() ?? {};
        const publicData: Record<string, unknown> = {};
        for (const field of PUBLIC_FIELDS) {
            if (field in data) {
                publicData[field] = data[field];
            }
        }
        publicData.updatedAt = admin.firestore.FieldValue.serverTimestamp();

        await publicRef.set(publicData, { merge: false });
    });
