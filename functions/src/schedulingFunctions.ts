import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();
const MIN_PAYOUT_THRESHOLD_LKR = 1000;

// ── Recurring Bookings ────────────────────────────────────────────────────────

/**
 * When a root booking is confirmed and has a recurrence rule, expand it
 * into all instance booking documents.
 */
export const generateRecurringBookings = functions.firestore
  .document('bookings/{bookingId}')
  .onWrite(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!after) return;

    // Only trigger when status transitions to confirmed
    const justConfirmed =
      before?.status !== 'confirmed' && after.status === 'confirmed';
    if (!justConfirmed) return;

    const schedule = after.schedule;
    if (!schedule || !schedule.recurrence) return;
    if (schedule.recurrence.pattern === 'once') return;
    // Only expand root bookings (not already-generated instances)
    if (schedule.recurrence.parentBookingId) return;

    const bookingId = context.params.bookingId;
    console.log(`Expanding recurring booking ${bookingId}`);

    const firstDate: admin.firestore.Timestamp = schedule.date;
    const intervalDays: Record<string, number> = {
      weekly: 7,
      biweekly: 14,
      monthly: 30,
    };
    const interval = intervalDays[schedule.recurrence.pattern] ?? 7;

    const endDate: admin.firestore.Timestamp | null =
      schedule.recurrence.endDate ?? null;
    const maxOccurrences: number = schedule.recurrence.maxOccurrences ?? 999;
    const cutoffMs = endDate
      ? endDate.toMillis()
      : firstDate.toMillis() + 180 * 24 * 60 * 60 * 1000; // 6 months

    const dates: Date[] = [];
    let current = firstDate.toDate();
    // Skip first date — that's the parent booking
    if (schedule.recurrence.pattern === 'monthly') {
      current = new Date(current.getFullYear(), current.getMonth() + 1, current.getDate());
    } else {
      current = new Date(current.getTime() + interval * 24 * 60 * 60 * 1000);
    }

    while (current.getTime() < cutoffMs && dates.length < maxOccurrences - 1) {
      dates.push(new Date(current));
      if (schedule.recurrence.pattern === 'monthly') {
        current = new Date(current.getFullYear(), current.getMonth() + 1, current.getDate());
      } else {
        current = new Date(current.getTime() + interval * 24 * 60 * 60 * 1000);
      }
    }

    const batch = db.batch();
    for (const date of dates) {
      const ref = db.collection('bookings').doc();
      const instanceSchedule = {
        ...schedule,
        date: admin.firestore.Timestamp.fromDate(date),
        recurrence: {
          ...schedule.recurrence,
          parentBookingId: bookingId,
        },
      };
      batch.set(ref, {
        ...after,
        id: ref.id,
        schedule: instanceSchedule,
        scheduledDate: admin.firestore.Timestamp.fromDate(date),
        status: 'pending',
        heldAmount: 0,
        checkIn: null,
        checkOut: null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    console.log(`Created ${dates.length} instances for booking ${bookingId}`);
  });

// ── Weekly Payouts ─────────────────────────────────────────────────────────────

/**
 * Every Monday at 09:00 Colombo time, aggregate completed bookings without
 * a payoutId and create pending payout records for each worker.
 */
export const processWeeklyPayouts = functions.pubsub
  .schedule('0 9 * * 1') // Monday 09:00
  .timeZone('Asia/Colombo')
  .onRun(async () => {
    console.log('Processing weekly payouts');

    const now = new Date();
    const weekStart = new Date(now);
    weekStart.setDate(now.getDate() - now.getDay()); // Sunday midnight
    weekStart.setHours(0, 0, 0, 0);
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekStart.getDate() + 7);

    const snap = await db
      .collection('bookings')
      .where('status', '==', 'completed')
      .where('payoutId', '==', null)
      .get();

    const byWorker = new Map<string, { gross: number; ids: string[] }>();
    snap.docs.forEach(doc => {
      const data = doc.data();
      const workerId = data.workerId as string | undefined;
      if (!workerId) return;
      const amount = (data.finalPrice ?? data.estimatedPrice ?? 0) as number;
      const entry = byWorker.get(workerId) ?? { gross: 0, ids: [] };
      entry.gross += amount;
      entry.ids.push(doc.id);
      byWorker.set(workerId, entry);
    });

    const batch = db.batch();
    byWorker.forEach((entry, workerId) => {
      if (entry.gross <= 0) return;
      const ref = db.collection('payouts').doc();
      const platformFee = entry.gross * 0.20;
      const workerAmount = entry.gross - platformFee;
      batch.set(ref, {
        id: ref.id,
        workerId,
        grossAmount: entry.gross,
        platformFee,
        workerAmount,
        status: workerAmount >= MIN_PAYOUT_THRESHOLD_LKR ? 'pending' : 'below_threshold',
        thresholdLkr: MIN_PAYOUT_THRESHOLD_LKR,
        periodStart: admin.firestore.Timestamp.fromDate(weekStart),
        periodEnd: admin.firestore.Timestamp.fromDate(weekEnd),
        bookingIds: entry.ids,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      entry.ids.forEach(bookingId => {
        batch.update(db.collection('bookings').doc(bookingId), {
          payoutId: ref.id,
        });
      });
    });

    await batch.commit();
    console.log(`Created ${byWorker.size} payout records`);
  });

// ── Missed Check-In Detection ─────────────────────────────────────────────────

/**
 * Every 30 minutes: find workerArrived bookings past their grace period
 * with no checkIn, and raise a safety alert.
 */
export const checkMissedCheckIns = functions.pubsub
  .schedule('every 30 minutes')
  .timeZone('Asia/Colombo')
  .onRun(async () => {
    const now = new Date();
    const graceMs = 15 * 60 * 1000; // 15 minutes
    const cutoff = new Date(now.getTime() - graceMs);

    const snap = await db
      .collection('bookings')
      .where('status', '==', 'workerArrived')
      .get();

    for (const doc of snap.docs) {
      const data = doc.data();
      if (data.checkIn) continue;

      const scheduledDate = data.scheduledDate as admin.firestore.Timestamp | undefined;
      if (!scheduledDate || scheduledDate.toDate() > cutoff) continue;

      // Skip if alert already exists
      const existing = await db
        .collection('safety_alerts')
        .where('bookingId', '==', doc.id)
        .where('type', '==', 'missedCheckIn')
        .limit(1)
        .get();
      if (!existing.empty) continue;

      await db.collection('safety_alerts').add({
        bookingId: doc.id,
        workerId: data.workerId ?? '',
        customerId: data.customerId ?? '',
        type: 'missedCheckIn',
        severity: 'high',
        status: 'open',
        message: `Worker has not checked in for booking ${doc.id}`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

// ── Missed Check-Out Detection ────────────────────────────────────────────────

/**
 * Every 30 minutes: find inProgress bookings past their expected end time
 * with no checkOut, and raise a safety alert.
 */
export const checkMissedCheckOuts = functions.pubsub
  .schedule('every 30 minutes')
  .timeZone('Asia/Colombo')
  .onRun(async () => {
    const now = new Date();
    const graceMs = 30 * 60 * 1000;

    const snap = await db
      .collection('bookings')
      .where('status', '==', 'inProgress')
      .get();

    for (const doc of snap.docs) {
      const data = doc.data();
      if (data.checkOut) continue;

      // Compute expected end from schedule or scheduledDate + durationHours
      let expectedEnd: Date | null = null;
      const schedule = data.schedule as Record<string, any> | undefined;
      if (schedule?.date && schedule?.endTime) {
        const date = (schedule.date as admin.firestore.Timestamp).toDate();
        const [h, m] = (schedule.endTime as string).split(':').map(Number);
        expectedEnd = new Date(date.getFullYear(), date.getMonth(), date.getDate(), h, m);
      }
      if (!expectedEnd) {
        const base = (data.scheduledDate as admin.firestore.Timestamp | undefined)?.toDate();
        if (base) expectedEnd = new Date(base.getTime() + ((data.durationHours ?? 4) as number) * 3600000);
      }
      if (!expectedEnd || expectedEnd.getTime() + graceMs > now.getTime()) continue;

      const existing = await db
        .collection('safety_alerts')
        .where('bookingId', '==', doc.id)
        .where('type', '==', 'missedCheckOut')
        .limit(1)
        .get();
      if (!existing.empty) continue;

      await db.collection('safety_alerts').add({
        bookingId: doc.id,
        workerId: data.workerId ?? '',
        customerId: data.customerId ?? '',
        type: 'missedCheckOut',
        severity: 'high',
        status: 'open',
        message: `Worker has not checked out for booking ${doc.id} (expected: ${expectedEnd.toISOString()})`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

// ── Upcoming Booking Reminders ────────────────────────────────────────────────

/**
 * Every hour: send reminders for bookings starting in ~24 hours and ~2 hours.
 * Notifies both the customer AND the assigned worker.
 */
export const notifyUpcomingBookings = functions.pubsub
  .schedule('every 60 minutes')
  .timeZone('Asia/Colombo')
  .onRun(async () => {
    const now = Date.now();

    for (const windowHours of [24, 2]) {
      const windowStart = new Date(now + (windowHours - 0.5) * 3600000);
      const windowEnd = new Date(now + (windowHours + 0.5) * 3600000);

      const snap = await db
        .collection('bookings')
        .where('status', 'in', ['confirmed', 'workerAssigned'])
        .where('scheduledDate', '>=', admin.firestore.Timestamp.fromDate(windowStart))
        .where('scheduledDate', '<=', admin.firestore.Timestamp.fromDate(windowEnd))
        .get();

      const batch = db.batch();
      snap.docs.forEach(doc => {
        const data = doc.data();
        const scheduledStr = (data.scheduledDate as admin.firestore.Timestamp).toDate().toLocaleString('en-LK');

        // ── Customer notification ──
        const customerRef = db.collection('notifications').doc();
        batch.set(customerRef, {
          userId: data.customerId,
          type: 'booking_reminder',
          title: windowHours === 24 ? 'Reminder: your booking is tomorrow' : 'Reminder: booking in 2 hours',
          body: `Your booking is scheduled for ${scheduledStr}`,
          bookingId: doc.id,
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // ── Worker notification (only if a worker has been assigned) ──
        if (data.workerId) {
          const workerRef = db.collection('notifications').doc();
          batch.set(workerRef, {
            userId: data.workerId,
            type: 'upcoming_job_reminder',
            title: windowHours === 24 ? 'Job reminder: tomorrow' : 'Job reminder: starting in 2 hours',
            body: `You have a booking at ${scheduledStr}. Please prepare and be on time.`,
            bookingId: doc.id,
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      });
      await batch.commit();
    }
  });

// ── Auto-Complete Stalled Bookings ────────────────────────────────────────────

/**
 * Every hour: bookings stuck in inProgress > 4 hours past expected end are
 * auto-completed so payment can settle.
 */
export const autoCompleteBookings = functions.pubsub
  .schedule('every 60 minutes')
  .timeZone('Asia/Colombo')
  .onRun(async () => {
    const now = new Date();

    const snap = await db
      .collection('bookings')
      .where('status', '==', 'inProgress')
      .get();

    const batch = db.batch();
    let count = 0;

    snap.docs.forEach(doc => {
      const data = doc.data();
      const base = (data.scheduledDate as admin.firestore.Timestamp | undefined)?.toDate();
      if (!base) return;
      const duration = (data.durationHours ?? 4) as number;
      const expectedEnd = new Date(base.getTime() + (duration + 4) * 3600000);
      if (now < expectedEnd) return;

      batch.update(doc.ref, {
        status: 'completed',
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        metadata: { ...((data.metadata ?? {}) as object), autoCompleted: true },
      });
      count++;
    });

    if (count > 0) {
      await batch.commit();
      console.log(`Auto-completed ${count} stalled bookings`);
    }
  });

// ── Safety Alert Auto-Escalation ─────────────────────────────────────────────

/**
 * When a critical safety alert is created, push notifications to all admins.
 */
export const escalateSafetyAlert = functions.firestore
  .document('safety_alerts/{alertId}')
  .onCreate(async (snap) => {
    const data = snap.data();
    const isSOS       = data.type === 'sos';
    const isCritical  = data.severity === 'critical' || isSOS;
    if (!isCritical) return;

    const alertId  = snap.id;
    const workerId = data.workerId as string | undefined;
    const alertMsg = isSOS ? 'Worker triggered SOS' : (data.description as string ?? 'Safety alert');

    // ── Step 1: Push notification to all admins ───────────────────────────
    const admins = await db.collection('users')
      .where('userType', '==', 'admin')
      .get();

    const batch = db.batch();
    const fcmTokens: string[] = [];

    admins.docs.forEach(adminDoc => {
      const notifRef = db.collection('notifications').doc();
      batch.set(notifRef, {
        userId: adminDoc.id,
        type: 'safety_alert_critical',
        title: isSOS ? '🚨 SOS — Worker Emergency' : '⚠️ Critical Safety Alert',
        body: alertMsg,
        alertId,
        workerId: workerId ?? null,
        bookingId: data.bookingId ?? null,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      const token = adminDoc.data().fcmToken as string | undefined;
      if (token) fcmTokens.push(token);
    });
    await batch.commit();

    // Send FCM push to all admin devices
    if (fcmTokens.length > 0) {
      await admin.messaging().sendEachForMulticast({
        tokens: fcmTokens,
        notification: {
          title: isSOS ? '🚨 SOS Emergency' : '⚠️ Safety Alert',
          body: alertMsg,
        },
        data: { alertId, type: data.type ?? 'alert' },
      });
    }

    // ── Step 2: SMS via Notify.lk to all admin phone numbers ─────────────
    const notifyApiKey  = functions.config().notify?.api_key  ?? '';
    const notifyUserId  = functions.config().notify?.user_id  ?? '';
    const notifyService = functions.config().notify?.service_id ?? '';

    if (notifyApiKey && notifyUserId && notifyService) {
      const adminPhones: string[] = [];
      admins.docs.forEach(d => {
        const phone = d.data().phone as string | undefined;
        if (phone) adminPhones.push(phone);
      });

      if (workerId) {
        const workerSnap = await db.collection('workers').doc(workerId).get();
        const workerPhone = workerSnap.data()?.phone as string | undefined;
        if (workerPhone) {
          const smsText = isSOS
            ? `HelaService SOS: Worker ${workerSnap.data()?.fullName ?? workerId} triggered emergency. Alert ID: ${alertId}`
            : `HelaService Safety Alert: ${alertMsg}. Worker: ${workerId}. Alert ID: ${alertId}`;

          // SMS to all admin numbers
          for (const phone of adminPhones) {
            try {
              const resp = await fetch('https://app.notify.lk/api/v1/send', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                  user_id:    notifyUserId,
                  api_key:    notifyApiKey,
                  service_id: notifyService,
                  to:         phone,
                  message:    smsText,
                }),
              });
              if (!resp.ok) console.error('Notify.lk SMS failed:', await resp.text());
            } catch (err) {
              console.error('SMS send error:', err);
            }
          }
        }
      }
    } else {
      console.log('Notify.lk not configured — skipping SMS escalation');
    }

    // ── Step 3: Mark alert as escalated ──────────────────────────────────
    await snap.ref.update({
      escalatedAt: admin.firestore.FieldValue.serverTimestamp(),
      escalationChannels: ['push', notifyApiKey ? 'sms' : 'push_only'],
    });

    console.log(`escalateSafetyAlert: alert ${alertId} escalated to ${admins.size} admins`);
  });
