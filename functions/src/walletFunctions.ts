import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

const PLATFORM_FEE_RATE = 0.20; // 20% platform commission
const MIN_PAYOUT_THRESHOLD_LKR = 1000;

// ── Hold Wallet Funds (Escrow on Booking Confirmation) ────────────────────────

/**
 * Callable: atomically move `amount` from customer's availableBalance → heldBalance.
 * Must be called before a booking is confirmed.
 * Params: { customerId: string, bookingId: string, amount: number }
 */
export const holdWalletFunds = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login required');
  }

  const { customerId, bookingId, amount } = data as {
    customerId: string;
    bookingId: string;
    amount: number;
  };

  if (!customerId || !bookingId || !amount || amount <= 0) {
    throw new functions.https.HttpsError('invalid-argument', 'customerId, bookingId and a positive amount required');
  }

  // Only the customer or admin may hold funds
  if (context.auth.uid !== customerId && !context.auth.token.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Not authorised to hold funds for this customer');
  }

  const walletRef = db.collection('wallets').doc(customerId);
  const bookingRef = db.collection('bookings').doc(bookingId);

  return db.runTransaction(async (tx) => {
    const [walletSnap, bookingSnap] = await Promise.all([tx.get(walletRef), tx.get(bookingRef)]);

    if (!walletSnap.exists) throw new functions.https.HttpsError('not-found', 'Wallet not found');
    if (!bookingSnap.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');

    const wallet = walletSnap.data()!;
    const available = (wallet.availableBalance ?? wallet.balance ?? 0) as number;
    const held = (wallet.heldBalance ?? 0) as number;

    if (available < amount) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Insufficient balance: available LKR ${available.toFixed(2)}, needed LKR ${amount.toFixed(2)}`,
      );
    }

    const bookingData = bookingSnap.data()!;
    if (bookingData.heldAmount && bookingData.heldAmount > 0) {
      throw new functions.https.HttpsError('already-exists', 'Funds already held for this booking');
    }

    tx.update(walletRef, {
      availableBalance: available - amount,
      heldBalance: held + amount,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.update(bookingRef, {
      heldAmount: amount,
      status: 'confirmed',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Wallet transaction log
    const txRef = db.collection('wallet_transactions').doc();
    tx.set(txRef, {
      id: txRef.id,
      walletId: customerId,
      type: 'hold',
      amount,
      bookingId,
      description: 'Funds held for booking',
      balanceAfter: available - amount,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, heldAmount: amount, availableBalance: available - amount };
  });
});

// ── Release Wallet Funds (80/20 Split on Booking Completion) ─────────────────

/**
 * Callable: on booking completion, release the held amount — 80% to worker,
 * 20% retained as platform fee. Creates a pending payout record.
 * Params: { bookingId: string }
 */
export const releaseWalletFunds = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login required');
  }

  const { bookingId } = data as { bookingId: string };
  if (!bookingId) throw new functions.https.HttpsError('invalid-argument', 'bookingId required');

  const bookingRef = db.collection('bookings').doc(bookingId);

  return db.runTransaction(async (tx) => {
    const bookingSnap = await tx.get(bookingRef);
    if (!bookingSnap.exists) throw new functions.https.HttpsError('not-found', 'Booking not found');

    const booking = bookingSnap.data()!;

    // Only the booking's worker, customer, or admin may release
    const uid = context.auth!.uid;
    if (booking.workerId !== uid && booking.customerId !== uid && !context.auth!.token.admin) {
      throw new functions.https.HttpsError('permission-denied', 'Not authorised to release funds for this booking');
    }

    if (booking.status !== 'completed') {
      throw new functions.https.HttpsError('failed-precondition', `Booking must be completed before releasing funds (status: ${booking.status})`);
    }

    if (booking.payoutId) {
      throw new functions.https.HttpsError('already-exists', 'Funds already released for this booking');
    }

    const heldAmount = (booking.heldAmount ?? 0) as number;
    if (heldAmount <= 0) {
      throw new functions.https.HttpsError('failed-precondition', 'No held funds to release');
    }

    const platformFee = heldAmount * PLATFORM_FEE_RATE;
    const workerAmount = heldAmount - platformFee;

    // 1. Release hold on customer wallet
    const customerWalletRef = db.collection('wallets').doc(booking.customerId);
    const customerWalletSnap = await tx.get(customerWalletRef);
    if (customerWalletSnap.exists) {
      const cw = customerWalletSnap.data()!;
      const currentHeld = (cw.heldBalance ?? 0) as number;
      tx.update(customerWalletRef, {
        heldBalance: Math.max(0, currentHeld - heldAmount),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // 2. Credit worker wallet
    const workerWalletRef = db.collection('wallets').doc(booking.workerId);
    const workerWalletSnap = await tx.get(workerWalletRef);
    if (workerWalletSnap.exists) {
      const ww = workerWalletSnap.data()!;
      const workerBalance = (ww.balance ?? 0) as number;
      const workerAvailable = (ww.availableBalance ?? workerBalance) as number;
      tx.update(workerWalletRef, {
        balance: workerBalance + workerAmount,
        availableBalance: workerAvailable + workerAmount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else {
      tx.set(workerWalletRef, {
        balance: workerAmount,
        availableBalance: workerAmount,
        heldBalance: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // 3. Create pending payout record (paid out on next Monday batch)
    const payoutRef = db.collection('payouts').doc();
    tx.set(payoutRef, {
      id: payoutRef.id,
      workerId: booking.workerId,
      bookingIds: [bookingId],
      grossAmount: heldAmount,
      platformFee,
      workerAmount,
      status: workerAmount >= MIN_PAYOUT_THRESHOLD_LKR ? 'pending' : 'below_threshold',
      thresholdLkr: MIN_PAYOUT_THRESHOLD_LKR,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 4. Mark booking as paid
    tx.update(bookingRef, {
      payoutId: payoutRef.id,
      paymentStatus: 'paid',
      heldAmount: 0,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 5. Wallet transaction logs
    const customerTxRef = db.collection('wallet_transactions').doc();
    tx.set(customerTxRef, {
      id: customerTxRef.id,
      walletId: booking.customerId,
      type: 'debit',
      amount: heldAmount,
      bookingId,
      description: 'Payment for completed booking',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const workerTxRef = db.collection('wallet_transactions').doc();
    tx.set(workerTxRef, {
      id: workerTxRef.id,
      walletId: booking.workerId,
      type: 'credit',
      amount: workerAmount,
      bookingId,
      description: `Earnings (80% of LKR ${heldAmount.toFixed(2)})`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      heldAmount,
      workerAmount,
      platformFee,
      payoutId: payoutRef.id,
    };
  });
});
