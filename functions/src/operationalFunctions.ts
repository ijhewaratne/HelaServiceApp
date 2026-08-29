/**
 * Operational Cloud Functions
 * Covers: refunds, verification tier upgrades, reliability scoring,
 * daily reports, stale booking cleanup, annual re-verification.
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

// ─── 4.3.4  processRefund ────────────────────────────────────────────────────
// Callable: { bookingId, reason? }
// Returns held funds to customer wallet. Safe to call multiple times (idempotent).

export const processRefund = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login required');
  }

  const { bookingId, reason } = data as { bookingId: string; reason?: string };
  if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'bookingId required');

  return db.runTransaction(async (tx) => {
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingSnap = await tx.get(bookingRef);
    if (!bookingSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'Booking not found');
    }

    const booking = bookingSnap.data()!;

    // Auth check — customer or admin
    if (booking.customerId !== context.auth!.uid && !context.auth!.token.admin) {
      throw new functions.https.HttpsError('permission-denied', 'Not your booking');
    }

    const heldAmount: number = booking.heldAmount ?? 0;
    if (heldAmount <= 0) {
      return { success: true, refundedAmount: 0, message: 'No held funds to refund' };
    }

    // Idempotency: skip if already refunded
    if (booking.paymentStatus === 'refunded') {
      return { success: true, refundedAmount: 0, message: 'Already refunded' };
    }

    const walletRef = db.collection('wallets').doc(booking.customerId);
    const walletSnap = await tx.get(walletRef);
    if (!walletSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'Customer wallet not found');
    }

    const wallet = walletSnap.data()!;
    const currentBalance: number = wallet.balance ?? 0;
    const currentHeld: number = wallet.heldBalance ?? 0;

    // heldAmount is LKR (Booking.heldAmount); wallets.balance/heldBalance and
    // transactions.amount are integer cents.
    const heldAmountCents = Math.round(heldAmount * 100);

    // Return held funds to available balance (balance - heldBalance is always
    // the source of truth — there is no separately-stored availableBalance)
    tx.update(walletRef, {
      balance: currentBalance + heldAmountCents,
      heldBalance: Math.max(0, currentHeld - heldAmountCents),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Write transaction record
    const txRef = db.collection('transactions').doc();
    tx.set(txRef, {
      id: txRef.id,
      userId: booking.customerId,
      type: 'refund',
      amount: heldAmountCents,
      relatedBookingId: bookingId,
      description: reason ?? 'Booking cancellation refund',
      status: 'completed',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Mark booking
    tx.update(bookingRef, {
      heldAmount: 0,
      paymentStatus: 'refunded',
      refundedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, refundedAmount: heldAmount };
  });
});

// ─── 4.4.1 / 4.4.2  processVerificationUpgrade ──────────────────────────────
// Callable (admin only): { workerId, newTier: 'blue'|'gold'|'partner' }
// Promotes worker tier, updates rate multiplier, sends notification.

export const processVerificationUpgrade = functions.https.onCall(async (data, context) => {
  if (!context.auth?.token.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin only');
  }

  const { workerId, newTier } = data as { workerId: string; newTier: string };
  if (!workerId || !newTier) {
    throw new functions.https.HttpsError('invalid-argument', 'workerId and newTier required');
  }

  const validTiers = ['blue', 'gold', 'partner'];
  if (!validTiers.includes(newTier)) {
    throw new functions.https.HttpsError('invalid-argument', `newTier must be one of: ${validTiers.join(', ')}`);
  }

  const tierMultipliers: Record<string, number> = {
    blue: 1.10,
    gold: 1.25,
    partner: 1.40,
  };

  const workerRef = db.collection('workers').doc(workerId);
  const verifRef  = db.collection('worker_verifications').doc(workerId);

  const batch = db.batch();

  // Update worker document
  batch.update(workerRef, {
    verificationTier: newTier,
    rateMultiplier: tierMultipliers[newTier],
    isVerified: true,
    verificationStatus: 'approved',
    [`${newTier}TierGrantedAt`]: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Update verification record
  batch.set(verifRef, {
    workerId,
    currentTier: newTier,
    status: 'approved',
    approvedBy: context.auth.uid,
    approvedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  // Create notification for worker
  const notifRef = db.collection('notifications').doc();
  batch.set(notifRef, {
    id: notifRef.id,
    userId: workerId,
    type: 'tier_upgrade',
    title: `Congratulations! You've been promoted to ${newTier.charAt(0).toUpperCase() + newTier.slice(1)} tier`,
    body: `Your verification tier has been upgraded to ${newTier}. You now earn a ${Math.round((tierMultipliers[newTier] - 1) * 100)}% rate bonus!`,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await batch.commit();

  // Send FCM push notification
  try {
    const workerSnap = await workerRef.get();
    const fcmToken = workerSnap.data()?.fcmToken as string | undefined;
    if (fcmToken) {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: `You're now ${newTier.charAt(0).toUpperCase() + newTier.slice(1)} tier!`,
          body: `+${Math.round((tierMultipliers[newTier] - 1) * 100)}% hourly rate bonus unlocked`,
        },
        data: { type: 'tier_upgrade', newTier },
      });
    }
  } catch (err) {
    // Non-fatal: push failure shouldn't block the upgrade
    console.warn('FCM push failed (non-fatal):', err);
  }

  return { success: true, workerId, newTier, multiplier: tierMultipliers[newTier] };
});

// ─── 4.4.3  scheduleReverification ──────────────────────────────────────────
// Cron: daily at 08:00. Finds Blue/Gold workers whose verification expires in
// 30 days and sends reminders; downgrades expired workers back to green.

const REVERIFICATION_PERIOD_DAYS = 365;

export const scheduleReverification = functions.pubsub
  .schedule('0 8 * * *')
  .timeZone('Asia/Colombo')
  .onRun(async () => {
    const now = new Date();
    const in30Days = new Date(now);
    in30Days.setDate(now.getDate() + 30);

    // Workers with a tier-granted timestamp approaching 1 year
    const workersSnap = await db
      .collection('workers')
      .where('verificationTier', 'in', ['blue', 'gold', 'partner'])
      .where('isVerified', '==', true)
      .get();

    const batch = db.batch();
    let reminders = 0;
    let downgrades = 0;

    for (const doc of workersSnap.docs) {
      const data = doc.data();
      const tier: string = data.verificationTier;
      const grantedAt: admin.firestore.Timestamp | undefined = data[`${tier}TierGrantedAt`];
      if (!grantedAt) continue;

      const grantDate = grantedAt.toDate();
      const expiryDate = new Date(grantDate);
      expiryDate.setDate(grantDate.getDate() + REVERIFICATION_PERIOD_DAYS);

      const daysUntilExpiry = Math.ceil((expiryDate.getTime() - now.getTime()) / 86400000);

      if (daysUntilExpiry <= 0) {
        // Expired — downgrade to green
        batch.update(doc.ref, {
          verificationTier: 'green',
          rateMultiplier: 1.0,
          verificationStatus: 'reverification_required',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        const notifRef = db.collection('notifications').doc();
        batch.set(notifRef, {
          id: notifRef.id,
          userId: doc.id,
          type: 'tier_expired',
          title: 'Verification Expired',
          body: `Your ${tier} tier verification has expired. Please resubmit documents to regain your tier.`,
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        downgrades++;
      } else if (daysUntilExpiry <= 30) {
        // Approaching expiry — send reminder
        const notifRef = db.collection('notifications').doc();
        batch.set(notifRef, {
          id: notifRef.id,
          userId: doc.id,
          type: 'reverification_reminder',
          title: 'Verification Renewal Due',
          body: `Your ${tier} tier verification expires in ${daysUntilExpiry} days. Please submit renewal documents.`,
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        reminders++;
      }
    }

    await batch.commit();
    console.log(`scheduleReverification: ${reminders} reminders sent, ${downgrades} tiers downgraded`);
  });

// ─── 4.5.2  updateWorkerReliabilityScores ───────────────────────────────────
// Cron: every Monday at 06:00.
// Score = (completionRate × 0.6) + (normalizedRating × 0.4)
// Where normalizedRating = avgRating / 5.0

export const updateWorkerReliabilityScores = functions.pubsub
  .schedule('0 6 * * 1')
  .timeZone('Asia/Colombo')
  .onRun(async () => {
    const workersSnap = await db
      .collection('workers')
      .where('isVerified', '==', true)
      .get();

    const batch = db.batch();

    for (const workerDoc of workersSnap.docs) {
      const wid = workerDoc.id;

      // Count completed and total assigned bookings
      const [completedSnap, assignedSnap, ratingSnap] = await Promise.all([
        db.collection('bookings')
          .where('workerId', '==', wid)
          .where('status', '==', 'completed')
          .get(),
        db.collection('bookings')
          .where('workerId', '==', wid)
          .where('status', 'in', ['completed', 'cancelled', 'disputed'])
          .get(),
        db.collection('reviews')
          .where('workerId', '==', wid)
          .get(),
      ]);

      const completedCount = completedSnap.size;
      const assignedCount  = assignedSnap.size;
      const completionRate = assignedCount > 0 ? completedCount / assignedCount : 0;

      let avgRating = 0;
      if (ratingSnap.size > 0) {
        const sum = ratingSnap.docs.reduce((acc, d) => acc + ((d.data().rating as number) ?? 0), 0);
        avgRating = sum / ratingSnap.size;
      }
      const normalizedRating = avgRating / 5.0;

      const reliabilityScore = (completionRate * 0.6) + (normalizedRating * 0.4);

      batch.update(workerDoc.ref, {
        reliabilityScore: Math.round(reliabilityScore * 100) / 100,
        completedJobsCount: completedCount,
        avgRating: Math.round(avgRating * 10) / 10,
        scoreUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    console.log(`updateWorkerReliabilityScores: updated ${workersSnap.size} workers`);
  });

// ─── 4.6.2  generateDailyReport ─────────────────────────────────────────────
// Cron: daily at 23:00. Writes summary to daily_reports/{YYYY-MM-DD}.

export const generateDailyReport = functions.pubsub
  .schedule('0 23 * * *')
  .timeZone('Asia/Colombo')
  .onRun(async () => {
    const now  = new Date();
    const date = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;

    const startOfDay = new Date(now);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(now);
    endOfDay.setHours(23, 59, 59, 999);

    const startTs = admin.firestore.Timestamp.fromDate(startOfDay);
    const endTs   = admin.firestore.Timestamp.fromDate(endOfDay);

    const [
      newBookingsSnap,
      completedSnap,
      cancelledSnap,
      alertsSnap,
      newWorkersSnap,
      newCustomersSnap,
    ] = await Promise.all([
      db.collection('bookings').where('createdAt', '>=', startTs).where('createdAt', '<=', endTs).get(),
      db.collection('bookings').where('completedAt', '>=', startTs).where('completedAt', '<=', endTs).get(),
      db.collection('bookings').where('cancelledAt', '>=', startTs).where('cancelledAt', '<=', endTs).get(),
      db.collection('safety_alerts').where('createdAt', '>=', startTs).where('createdAt', '<=', endTs).get(),
      db.collection('workers').where('createdAt', '>=', startTs).where('createdAt', '<=', endTs).get(),
      db.collection('customer_profiles').where('createdAt', '>=', startTs).where('createdAt', '<=', endTs).get(),
    ]);

    // Revenue from completed bookings
    let grossRevenue = 0;
    let platformFee  = 0;
    completedSnap.docs.forEach(d => {
      const price = (d.data().finalPrice as number) ?? (d.data().estimatedPrice as number) ?? 0;
      grossRevenue += price;
      platformFee  += price * 0.20;
    });

    await db.collection('daily_reports').doc(date).set({
      date,
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
      bookings: {
        new:       newBookingsSnap.size,
        completed: completedSnap.size,
        cancelled: cancelledSnap.size,
      },
      revenue: {
        gross:       Math.round(grossRevenue * 100) / 100,
        platformFee: Math.round(platformFee * 100) / 100,
        workerPayout: Math.round((grossRevenue - platformFee) * 100) / 100,
      },
      safety: {
        alertsCreated: alertsSnap.size,
        sosAlerts: alertsSnap.docs.filter(d => d.data().type === 'sos').length,
      },
      growth: {
        newWorkers:   newWorkersSnap.size,
        newCustomers: newCustomersSnap.size,
      },
    });

    console.log(`generateDailyReport: ${date} — ${completedSnap.size} completed, LKR ${grossRevenue.toFixed(0)} gross`);
  });

// ─── 4.6.3  cleanupOldPendingBookings ───────────────────────────────────────
// Cron: daily at 02:00.
// Auto-cancels bookings stuck in 'pending' or 'draft' for > 48h with no worker.

export const cleanupOldPendingBookings = functions.pubsub
  .schedule('0 2 * * *')
  .timeZone('Asia/Colombo')
  .onRun(async () => {
    const cutoff = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 48 * 60 * 60 * 1000)
    );

    const snap = await db
      .collection('bookings')
      .where('status', 'in', ['pending', 'draft'])
      .where('createdAt', '<', cutoff)
      .get();

    if (snap.empty) {
      console.log('cleanupOldPendingBookings: nothing to clean');
      return;
    }

    const batch = db.batch();
    snap.docs.forEach(doc => {
      const data = doc.data();
      batch.update(doc.ref, {
        status: 'cancelled',
        cancellationReason: 'Auto-cancelled: no worker assigned within 48 hours',
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Refund any held funds (fire-and-forget via a separate transaction)
      if ((data.heldAmount as number ?? 0) > 0) {
        // data.heldAmount is LKR (Booking.heldAmount); wallets.balance/heldBalance
        // are integer cents.
        const heldAmountCents = Math.round((data.heldAmount as number) * 100);
        db.runTransaction(async (tx) => {
          const walletRef = db.collection('wallets').doc(data.customerId as string);
          const wallet = (await tx.get(walletRef)).data() ?? {};
          tx.update(walletRef, {
            balance: (wallet.balance as number ?? 0) + heldAmountCents,
            heldBalance: Math.max(0, (wallet.heldBalance as number ?? 0) - heldAmountCents),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }).catch(err => console.error('Auto-refund failed for booking', doc.id, err));
      }
    });

    await batch.commit();
    console.log(`cleanupOldPendingBookings: auto-cancelled ${snap.size} stale bookings`);
  });
