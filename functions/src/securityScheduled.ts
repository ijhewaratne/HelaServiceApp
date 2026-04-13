import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { cleanupRateLimits } from './rateLimit';

/**
 * Scheduled Security Functions
 * Sprint 5: Security Hardening
 * 
 * These functions run on a schedule to maintain security hygiene
 */

const db = admin.firestore();

/**
 * Clean up expired rate limit documents daily
 * Runs at 2:00 AM daily
 */
export const cleanupRateLimitsDaily = functions.pubsub
  .schedule('0 2 * * *')
  .timeZone('Asia/Colombo')
  .onRun(async (context) => {
    console.log('🧹 Starting daily rate limit cleanup...');
    
    try {
      const deleted = await cleanupRateLimits();
      console.log(`✅ Cleaned up ${deleted} rate limit documents`);
      return { success: true, deleted };
    } catch (error) {
      console.error('❌ Rate limit cleanup failed:', error);
      return { success: false, error: error.message };
    }
  });

/**
 * Clean up expired OTP codes
 * Runs every hour
 */
export const cleanupExpiredOTPs = functions.pubsub
  .schedule('0 * * * *')
  .timeZone('Asia/Colombo')
  .onRun(async (context) => {
    console.log('🧹 Cleaning up expired OTP codes...');
    
    try {
      const now = admin.firestore.Timestamp.now();
      const snapshot = await db
        .collection('otp_codes')
        .where('expiresAt', '<', now)
        .limit(500)
        .get();
      
      const batch = db.batch();
      let count = 0;
      
      for (const doc of snapshot.docs) {
        batch.delete(doc.ref);
        count++;
      }
      
      if (count > 0) {
        await batch.commit();
      }
      
      console.log(`✅ Cleaned up ${count} expired OTP codes`);
      return { success: true, deleted: count };
    } catch (error) {
      console.error('❌ OTP cleanup failed:', error);
      return { success: false, error: error.message };
    }
  });

/**
 * Clean up old job offers (expired/accepted/rejected after 7 days)
 * Runs daily at 3:00 AM
 */
export const cleanupOldJobOffers = functions.pubsub
  .schedule('0 3 * * *')
  .timeZone('Asia/Colombo')
  .onRun(async (context) => {
    console.log('🧹 Cleaning up old job offers...');
    
    try {
      const cutoff = admin.firestore.Timestamp.fromMillis(
        Date.now() - (7 * 24 * 60 * 60 * 1000) // 7 days ago
      );
      
      const snapshot = await db
        .collection('job_offers')
        .where('offeredAt', '<', cutoff)
        .limit(500)
        .get();
      
      const batch = db.batch();
      let count = 0;
      
      for (const doc of snapshot.docs) {
        batch.delete(doc.ref);
        count++;
      }
      
      if (count > 0) {
        await batch.commit();
      }
      
      console.log(`✅ Cleaned up ${count} old job offers`);
      return { success: true, deleted: count };
    } catch (error) {
      console.error('❌ Job offer cleanup failed:', error);
      return { success: false, error: error.message };
    }
  });

/**
 * Clean up old chat messages (older than 30 days)
 * PDPA compliance - data retention policy
 * Runs daily at 4:00 AM
 */
export const cleanupOldMessages = functions.pubsub
  .schedule('0 4 * * *')
  .timeZone('Asia/Colombo')
  .onRun(async (context) => {
    console.log('🧹 Cleaning up old chat messages (PDPA compliance)...');
    
    try {
      const cutoff = admin.firestore.Timestamp.fromMillis(
        Date.now() - (30 * 24 * 60 * 60 * 1000) // 30 days ago
      );
      
      const snapshot = await db
        .collectionGroup('messages')
        .where('createdAt', '<', cutoff)
        .limit(500)
        .get();
      
      const batch = db.batch();
      let count = 0;
      
      for (const doc of snapshot.docs) {
        batch.delete(doc.ref);
        count++;
      }
      
      if (count > 0) {
        await batch.commit();
      }
      
      console.log(`✅ Cleaned up ${count} old messages`);
      return { success: true, deleted: count };
    } catch (error) {
      console.error('❌ Message cleanup failed:', error);
      return { success: false, error: error.message };
    }
  });

/**
 * Archive old job requests (completed/cancelled after 90 days)
 * Moves to archive collection and deletes from active
 * Runs weekly on Sunday at 5:00 AM
 */
export const archiveOldJobs = functions.pubsub
  .schedule('0 5 * * 0')
  .timeZone('Asia/Colombo')
  .onRun(async (context) => {
    console.log('📦 Archiving old job requests...');
    
    try {
      const cutoff = admin.firestore.Timestamp.fromMillis(
        Date.now() - (90 * 24 * 60 * 60 * 1000) // 90 days ago
      );
      
      // Find completed/cancelled jobs older than 90 days
      const snapshot = await db
        .collection('job_requests')
        .where('status', 'in', ['completed', 'cancelled', 'no_workers_available'])
        .where('completedAt', '<', cutoff)
        .limit(100)
        .get();
      
      let archived = 0;
      let deleted = 0;
      
      for (const doc of snapshot.docs) {
        const data = doc.data();
        
        // Archive to cold storage
        await db.collection('job_requests_archive').doc(doc.id).set({
          ...data,
          archivedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        archived++;
        
        // Delete from active collection
        await doc.ref.delete();
        deleted++;
      }
      
      console.log(`✅ Archived ${archived} jobs, deleted ${deleted} from active`);
      return { success: true, archived, deleted };
    } catch (error) {
      console.error('❌ Job archiving failed:', error);
      return { success: false, error: error.message };
    }
  });

/**
 * Detect and alert on suspicious activity
 * Runs every 15 minutes
 */
export const detectSuspiciousActivity = functions.pubsub
  .schedule('*/15 * * * *')
  .timeZone('Asia/Colombo')
  .onRun(async (context) => {
    console.log('🔍 Scanning for suspicious activity...');
    
    const alerts: string[] = [];
    
    try {
      // Check for multiple failed OTP attempts from same IP
      const fifteenMinutesAgo = admin.firestore.Timestamp.fromMillis(
        Date.now() - (15 * 60 * 1000)
      );
      
      const failedOtps = await db
        .collection('otp_codes')
        .where('attempts', '>=', 5)
        .where('createdAt', '>', fifteenMinutesAgo)
        .limit(50)
        .get();
      
      for (const doc of failedOtps.docs) {
        const data = doc.data();
        alerts.push(`Multiple failed OTP attempts for ${data.phoneNumber}`);
        
        // Log to audit collection
        await db.collection('security_alerts').add({
          type: 'multiple_failed_otp',
          phoneNumber: data.phoneNumber,
          attempts: data.attempts,
          detectedAt: admin.firestore.FieldValue.serverTimestamp(),
          severity: 'high',
        });
      }
      
      // Check for rapid job creation (potential abuse)
      const oneMinuteAgo = admin.firestore.Timestamp.fromMillis(
        Date.now() - (60 * 1000)
      );
      
      const recentJobs = await db
        .collectionGroup('rate_limits')
        .where('operation', '==', 'job_create')
        .where('requests', '>=', 20)
        .where('windowStart', '>', oneMinuteAgo)
        .limit(10)
        .get();
      
      for (const doc of recentJobs.docs) {
        const data = doc.data();
        alerts.push(`High job creation rate for user ${data.userId}`);
        
        await db.collection('security_alerts').add({
          type: 'high_job_creation_rate',
          userId: data.userId,
          requests: data.requests,
          detectedAt: admin.firestore.FieldValue.serverTimestamp(),
          severity: 'medium',
        });
      }
      
      if (alerts.length > 0) {
        console.log(`⚠️ Detected ${alerts.length} suspicious activities`);
        // In production, send alerts to admin via email/Slack
      } else {
        console.log('✅ No suspicious activity detected');
      }
      
      return { success: true, alerts: alerts.length };
    } catch (error) {
      console.error('❌ Suspicious activity detection failed:', error);
      return { success: false, error: error.message };
    }
  });
