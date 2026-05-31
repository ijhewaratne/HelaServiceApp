import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as geofire from 'geofire-common';

const db = admin.firestore();

const CHECK_IN_RADIUS_M = 200; // Worker must be within 200 m of booking address

// ── GPS Proximity Check on Worker Check-In (4.2.4) ───────────────────────────

/**
 * Triggered when a booking document gets a `checkIn` field set.
 * Validates the worker GPS location is within CHECK_IN_RADIUS_M of the
 * booking address and raises a safety alert if not.
 */
export const verifyWorkerCheckInLocation = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only run when checkIn is newly set
    if (before.checkIn || !after.checkIn) return;

    const checkIn = after.checkIn as { lat?: number; lng?: number } | null;
    if (!checkIn?.lat || !checkIn?.lng) return;

    const address = after.address as { lat?: number; lng?: number } | null;
    if (!address?.lat || !address?.lng) return;

    const distanceM = geofire.distanceBetween(
      [checkIn.lat, checkIn.lng],
      [address.lat, address.lng],
    ) * 1000;

    if (distanceM > CHECK_IN_RADIUS_M) {
      const bookingId = context.params.bookingId;
      console.warn(`Check-in GPS mismatch for booking ${bookingId}: ${Math.round(distanceM)}m from address`);

      await db.collection('safety_alerts').add({
        bookingId,
        workerId: after.workerId ?? '',
        customerId: after.customerId ?? '',
        type: 'locationMismatch',
        severity: 'medium',
        status: 'open',
        message: `Worker checked in ${Math.round(distanceM)}m from booking address (max ${CHECK_IN_RADIUS_M}m).`,
        checkInLat: checkIn.lat,
        checkInLng: checkIn.lng,
        bookingLat: address.lat,
        bookingLng: address.lng,
        distanceMeters: Math.round(distanceM),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

// ── Cancel a Single Recurring Instance (4.1.2) ───────────────────────────────

/**
 * Callable: cancel a single instance of a recurring booking without
 * affecting sibling instances. The parent booking is left untouched.
 * Params: { bookingId: string, reason?: string }
 */
export const cancelRecurringInstance = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login required');
  }

  const { bookingId, reason } = data as { bookingId: string; reason?: string };
  if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'bookingId required');

  const ref = db.collection('bookings').doc(bookingId);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');

    const d = snap.data()!;
    const uid = context.auth!.uid;

    // Only the booking's customer or an admin may cancel
    if (d.customerId !== uid && !context.auth!.token.admin) {
      throw new functions.https.HttpsError('permission-denied', 'Not authorised to cancel this booking');
    }

    // Must be a recurring instance (has parentBookingId)
    if (!d.schedule?.recurrence?.parentBookingId) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'This booking is not a recurring instance. Use regular cancellation.',
      );
    }

    if (['cancelled', 'completed'].includes(d.status)) {
      throw new functions.https.HttpsError('failed-precondition', `Booking is already ${d.status}`);
    }

    tx.update(ref, {
      status: 'cancelled',
      cancellationReason: reason ?? 'Customer cancelled',
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      cancelledBy: uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { success: true, bookingId };
});

// ── Modify All Future Instances in a Recurring Series (4.1.3) ────────────────

/**
 * Callable: update all future (not yet started) instances of a recurring
 * series to a new time or duration.
 * Params: {
 *   parentBookingId: string,
 *   updates: { startTime?: string, durationHours?: number, specialNotes?: string }
 * }
 */
export const modifyRecurringSeries = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login required');
  }

  const { parentBookingId, updates } = data as {
    parentBookingId: string;
    updates: { startTime?: string; durationHours?: number; specialNotes?: string };
  };

  if (!parentBookingId) throw new functions.https.HttpsError('invalid-argument', 'parentBookingId required');
  if (!updates || Object.keys(updates).length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'updates must contain at least one field');
  }

  // Validate ownership on the parent booking
  const parentSnap = await db.collection('bookings').doc(parentBookingId).get();
  if (!parentSnap.exists) throw new functions.https.HttpsError('not-found', 'Parent booking not found');
  const parentData = parentSnap.data()!;
  if (parentData.customerId !== context.auth.uid && !context.auth.token.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Not authorised to modify this series');
  }

  // Find all future instances that haven't started or completed
  const now = new Date();
  const instancesSnap = await db
    .collection('bookings')
    .where('schedule.recurrence.parentBookingId', '==', parentBookingId)
    .where('status', 'in', ['pending', 'confirmed', 'workerAssigned'])
    .get();

  const futureDocs = instancesSnap.docs.filter(doc => {
    const scheduledDate = doc.data().scheduledDate as admin.firestore.Timestamp | undefined;
    return scheduledDate ? scheduledDate.toDate() > now : false;
  });

  if (futureDocs.length === 0) {
    return { success: true, modifiedCount: 0, message: 'No future instances to update' };
  }

  const allowedFields = ['startTime', 'durationHours', 'specialNotes'];
  const safeUpdates: Record<string, unknown> = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };
  for (const key of allowedFields) {
    if (key in updates) safeUpdates[key] = (updates as Record<string, unknown>)[key];
  }

  const batch = db.batch();
  futureDocs.forEach(doc => batch.update(doc.ref, safeUpdates));
  await batch.commit();

  return { success: true, modifiedCount: futureDocs.length };
});

// ── Worker Suspension (4.4.4) ─────────────────────────────────────────────────

/**
 * Triggered when a safety_alert document is created.
 * If the alert is critical (sosPanic or serious incident) and the worker
 * has >= 2 unresolved critical alerts in the past 30 days, auto-suspend them.
 * Admins can also call the suspendWorkerManually callable.
 */
export const suspendWorker = functions.firestore
  .document('safety_alerts/{alertId}')
  .onCreate(async (snap) => {
    const alert = snap.data();

    // Only act on high/critical severity types that implicate a worker
    const autoSuspendTypes = ['sosPanic', 'customerReport'];
    if (!autoSuspendTypes.includes(alert.type)) return;
    if (!alert.workerId) return;

    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    const recentCritical = await db
      .collection('safety_alerts')
      .where('workerId', '==', alert.workerId)
      .where('severity', 'in', ['high', 'critical'])
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
      .get();

    // Auto-suspend threshold: 2 or more high/critical unresolved alerts
    const unresolvedCount = recentCritical.docs.filter(
      d => d.data().status === 'open' || d.data().status === 'escalated',
    ).length;

    if (unresolvedCount < 2) return;

    await db.collection('workers').doc(alert.workerId).update({
      status: 'suspended',
      suspendedAt: admin.firestore.FieldValue.serverTimestamp(),
      suspendReason: `Auto-suspended: ${unresolvedCount} unresolved safety alerts in 30 days`,
      isOnline: false,
      isAvailable: false,
    });

    // Notify admins
    const admins = await db.collection('users').where('userType', '==', 'admin').get();
    const batch = db.batch();
    admins.docs.forEach(adminDoc => {
      const ref = db.collection('notifications').doc();
      batch.set(ref, {
        userId: adminDoc.id,
        type: 'worker_auto_suspended',
        title: '⚠️ Worker Auto-Suspended',
        body: `Worker ${alert.workerId} was auto-suspended after ${unresolvedCount} unresolved safety alerts.`,
        workerId: alert.workerId,
        alertId: snap.id,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    await batch.commit();

    console.log(`Worker ${alert.workerId} auto-suspended (${unresolvedCount} unresolved alerts)`);
  });

/**
 * Callable: manually suspend a worker (admin only).
 * Params: { workerId: string, reason: string }
 */
export const suspendWorkerManually = functions.https.onCall(async (data, context) => {
  if (!context.auth?.token?.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }

  const { workerId, reason } = data as { workerId: string; reason: string };
  if (!workerId || !reason) {
    throw new functions.https.HttpsError('invalid-argument', 'workerId and reason required');
  }

  await db.collection('workers').doc(workerId).update({
    status: 'suspended',
    suspendedAt: admin.firestore.FieldValue.serverTimestamp(),
    suspendReason: reason,
    suspendedBy: context.auth.uid,
    isOnline: false,
    isAvailable: false,
  });

  return { success: true, workerId };
});
