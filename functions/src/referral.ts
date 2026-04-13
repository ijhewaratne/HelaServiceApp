/**
 * Phase 7: Business Features - Referral System Cloud Functions
 * 
 * Automatic referral processing:
 * - Create referral on new user signup with referral code
 * - Credit rewards when referred user completes first booking
 * - Handle edge cases and duplicate prevention
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

const DEFAULT_REFERRAL_REWARD = 500; // LKR 500
const REFERRAL_EXPIRY_DAYS = 30;

/**
 * Process referral when new user signs up with referral code
 * Trigger: On user document creation
 */
export const processReferralOnSignup = functions.firestore
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const userData = snap.data();
    const referralCode = userData.referralCode;

    // No referral code provided
    if (!referralCode) {
      console.log(`No referral code for user ${userId}`);
      return null;
    }

    try {
      // Find referrer by their referral code
      const referrerQuery = await db
        .collection('users')
        .where('myReferralCode', '==', referralCode)
        .limit(1)
        .get();

      if (referrerQuery.empty) {
        console.warn(`Invalid referral code: ${referralCode}`);
        await snap.ref.update({
          referralStatus: 'invalid_code',
          referralCode: admin.firestore.FieldValue.delete(),
        });
        return null;
      }

      const referrerId = referrerQuery.docs[0].id;

      // Prevent self-referral
      if (referrerId === userId) {
        console.warn(`Self-referral blocked for user ${userId}`);
        await snap.ref.update({
          referralStatus: 'self_referral_blocked',
          referralCode: admin.firestore.FieldValue.delete(),
        });
        return null;
      }

      // Check if this user was already referred (prevent duplicate referrals)
      const existingReferral = await db
        .collection('referrals')
        .where('referredUserId', '==', userId)
        .limit(1)
        .get();

      if (!existingReferral.empty) {
        console.log(`User ${userId} already has a referral record`);
        return null;
      }

      // Create referral record
      const referralRef = db.collection('referrals').doc();
      const now = admin.firestore.FieldValue.serverTimestamp();

      await referralRef.set({
        id: referralRef.id,
        referrerId: referrerId,
        referredUserId: userId,
        referralCode: referralCode,
        status: 'pending',
        rewardAmount: DEFAULT_REFERRAL_REWARD,
        rewardType: 'walletCredit',
        referrerRewarded: false,
        referredRewarded: false,
        createdAt: now,
        expiresAt: admin.firestore.Timestamp.fromMillis(
          Date.now() + REFERRAL_EXPIRY_DAYS * 24 * 60 * 60 * 1000
        ),
      });

      // Update new user with referrer info
      await snap.ref.update({
        referredBy: referrerId,
        referralStatus: 'pending',
      });

      // Update referrer's referral count
      const referrerRef = db.collection('users').doc(referrerId);
      await referrerRef.update({
        totalReferrals: admin.firestore.FieldValue.increment(1),
      });

      // Create notification for referrer
      await createNotification(
        referrerId,
        'New Referral! 🎉',
        `Someone signed up using your referral code. You'll earn LKR ${DEFAULT_REFERRAL_REWARD} when they complete their first booking!`,
        {
          type: 'referral_signup',
          referralId: referralRef.id,
          referredUserId: userId,
        }
      );

      console.log(`Referral created: ${referralRef.id} for user ${userId}`);
      return { success: true, referralId: referralRef.id };

    } catch (error) {
      console.error('Error processing referral:', error);
      throw error;
    }
  });

/**
 * Complete referral when referred user finishes first booking
 * Trigger: On booking status change to 'completed'
 */
export const completeReferralOnBooking = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only process when booking is completed
    if (before.status !== 'completed' && after.status === 'completed') {
      const customerId = after.customerId;

      try {
        // Find pending referral for this user
        const referralQuery = await db
          .collection('referrals')
          .where('referredUserId', '==', customerId)
          .where('status', '==', 'pending')
          .limit(1)
          .get();

        if (referralQuery.empty) {
          console.log(`No pending referral for user ${customerId}`);
          return null;
        }

        const referralDoc = referralQuery.docs[0];
        const referralData = referralDoc.data();
        const referralId = referralDoc.id;
        const referrerId = referralData.referrerId;
        const rewardAmount = referralData.rewardAmount || DEFAULT_REFERRAL_REWARD;

        // Start a batch to ensure atomic updates
        const batch = db.batch();

        // Update referral status
        const now = admin.firestore.FieldValue.serverTimestamp();
        batch.update(referralDoc.ref, {
          status: 'completed',
          completedAt: now,
          completedBookingId: context.params.bookingId,
        });

        // Credit referrer's wallet
        const referrerWalletRef = db.collection('wallets').doc(referrerId);
        const referrerWalletDoc = await referrerWalletRef.get();

        if (referrerWalletDoc.exists) {
          batch.update(referrerWalletRef, {
            balance: admin.firestore.FieldValue.increment(rewardAmount),
            totalCredited: admin.firestore.FieldValue.increment(rewardAmount),
            updatedAt: now,
          });
        } else {
          // Create wallet if doesn't exist
          batch.set(referrerWalletRef, {
            balance: rewardAmount,
            totalCredited: rewardAmount,
            totalDebited: 0,
            isActive: true,
            isFrozen: false,
            createdAt: now,
            updatedAt: now,
          });
        }

        // Add transaction record for referrer
        const transactionRef = db.collection('wallet_transactions').doc();
        batch.set(transactionRef, {
          userId: referrerId,
          type: 'referralReward',
          amount: rewardAmount,
          balanceAfter: admin.firestore.FieldValue.increment(rewardAmount),
          description: `Referral reward for inviting user ${customerId.substring(0, 8)}...`,
          relatedBookingId: context.params.bookingId,
          relatedReferralId: referralId,
          status: 'completed',
          createdAt: now,
        });

        // Credit referred user's wallet (welcome bonus)
        const referredWalletRef = db.collection('wallets').doc(customerId);
        const referredWalletDoc = await referredWalletRef.get();
        const welcomeBonus = 100; // LKR 100 welcome bonus

        if (referredWalletDoc.exists) {
          batch.update(referredWalletRef, {
            balance: admin.firestore.FieldValue.increment(welcomeBonus),
            totalCredited: admin.firestore.FieldValue.increment(welcomeBonus),
            updatedAt: now,
          });
        } else {
          batch.set(referredWalletRef, {
            balance: welcomeBonus,
            totalCredited: welcomeBonus,
            totalDebited: 0,
            isActive: true,
            isFrozen: false,
            createdAt: now,
            updatedAt: now,
          });
        }

        // Add transaction record for referred user
        const referredTransactionRef = db.collection('wallet_transactions').doc();
        batch.set(referredTransactionRef, {
          userId: customerId,
          type: 'referralReward',
          amount: welcomeBonus,
          balanceAfter: admin.firestore.FieldValue.increment(welcomeBonus),
          description: 'Welcome bonus for signing up with a referral code',
          relatedBookingId: context.params.bookingId,
          relatedReferralId: referralId,
          status: 'completed',
          createdAt: now,
        });

        // Update referrer's successful referral count
        batch.update(db.collection('users').doc(referrerId), {
          successfulReferrals: admin.firestore.FieldValue.increment(1),
        });

        // Update referred user's status
        batch.update(db.collection('users').doc(customerId), {
          referralStatus: 'completed',
        });

        // Update referral with reward status
        batch.update(referralDoc.ref, {
          status: 'rewarded',
          rewardedAt: now,
          referrerRewarded: true,
          referredRewarded: true,
          referrerRewardAmount: rewardAmount,
          referredRewardAmount: welcomeBonus,
        });

        // Commit all updates
        await batch.commit();

        // Send notification to referrer
        await createNotification(
          referrerId,
          'Referral Reward Earned! 🎉',
          `You've earned LKR ${rewardAmount} because ${customerId.substring(0, 8)}... completed their first booking!`,
          {
            type: 'referral_reward',
            referralId: referralId,
            rewardAmount: rewardAmount,
          }
        );

        // Send notification to referred user
        await createNotification(
          customerId,
          'Welcome Bonus! 🎁',
          `You've earned LKR ${welcomeBonus} for completing your first booking!`,
          {
            type: 'welcome_bonus',
            referralId: referralId,
            rewardAmount: welcomeBonus,
          }
        );

        console.log(`Referral ${referralId} completed and rewards credited`);
        return { success: true, referralId };

      } catch (error) {
        console.error('Error completing referral:', error);
        throw error;
      }
    }

    return null;
  });

/**
 * Generate referral code for new users
 * Trigger: On user creation (if no referral code exists)
 */
export const generateReferralCode = functions.firestore
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const userData = snap.data();

    // Skip if already has referral code
    if (userData.myReferralCode) {
      return null;
    }

    try {
      // Generate unique referral code
      const referralCode = generateUniqueReferralCode(userId);

      await snap.ref.update({
        myReferralCode: referralCode,
        totalReferrals: 0,
        successfulReferrals: 0,
        referralRewardsEarned: 0,
      });

      console.log(`Generated referral code ${referralCode} for user ${userId}`);
      return { success: true, referralCode };

    } catch (error) {
      console.error('Error generating referral code:', error);
      throw error;
    }
  });

/**
 * Clean up expired pending referrals
 * Scheduled: Daily
 */
export const cleanupExpiredReferrals = functions.pubsub
  .schedule('0 1 * * *') // Daily at 1 AM
  .timeZone('Asia/Colombo')
  .onRun(async (context) => {
    try {
      const now = admin.firestore.Timestamp.now();
      
      const expiredReferrals = await db
        .collection('referrals')
        .where('status', '==', 'pending')
        .where('expiresAt', '<', now)
        .limit(100)
        .get();

      const batch = db.batch();
      let count = 0;

      expiredReferrals.docs.forEach(doc => {
        batch.update(doc.ref, {
          status: 'expired',
          expiredAt: now,
        });
        count++;
      });

      await batch.commit();
      console.log(`Marked ${count} referrals as expired`);

      return { expiredCount: count };

    } catch (error) {
      console.error('Error cleaning up expired referrals:', error);
      throw error;
    }
  });

/**
 * Get referral statistics (HTTP callable)
 */
export const getReferralStats = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login required');
  }

  const userId = context.auth.uid;

  try {
    // Get user's referrals
    const referralsSnapshot = await db
      .collection('referrals')
      .where('referrerId', '==', userId)
      .get();

    const totalReferrals = referralsSnapshot.size;
    const successful = referralsSnapshot.docs.filter(
      d => d.data().status === 'completed' || d.data().status === 'rewarded'
    ).length;
    const pending = referralsSnapshot.docs.filter(
      d => d.data().status === 'pending'
    ).length;

    // Calculate total rewards
    const totalRewards = referralsSnapshot.docs.reduce((sum, d) => {
      const data = d.data();
      return sum + (data.referrerRewarded ? (data.referrerRewardAmount || 0) : 0);
    }, 0);

    return {
      totalReferrals,
      successfulReferrals: successful,
      pendingReferrals: pending,
      conversionRate: totalReferrals > 0 ? (successful / totalReferrals) * 100 : 0,
      totalRewardsEarned: totalRewards,
    };

  } catch (error) {
    console.error('Error getting referral stats:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get stats');
  }
});

/**
 * Get leaderboard (HTTP callable)
 */
export const getLeaderboard = functions.https.onCall(async (data, context) => {
  const limit = Math.min(data.limit || 10, 50);

  try {
    const topReferrers = await db
      .collection('users')
      .orderBy('successfulReferrals', 'desc')
      .limit(limit)
      .get();

    const leaderboard = topReferrers.docs.map(doc => {
      const data = doc.data();
      return {
        userId: doc.id,
        displayName: data.displayName || 'Anonymous',
        referralCount: data.successfulReferrals || 0,
        totalRewards: data.referralRewardsEarned || 0,
      };
    });

    return { leaderboard };

  } catch (error) {
    console.error('Error getting leaderboard:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get leaderboard');
  }
});

// Helper functions

function generateUniqueReferralCode(userId: string): string {
  // Take first 6 chars of userId
  const prefix = userId.substring(0, 6).toUpperCase();
  // Add random 4-digit number
  const random = Math.floor(1000 + Math.random() * 9000);
  return `HEL${prefix}${random}`;
}

async function createNotification(
  userId: string,
  title: string,
  body: string,
  data: Record<string, any>
): Promise<void> {
  try {
    await db.collection('notifications').add({
      userId,
      title,
      body,
      data,
      type: data.type || 'general',
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error('Failed to create notification:', error);
  }
}
