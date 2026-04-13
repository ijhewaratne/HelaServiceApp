/**
 * Phase 6: DevOps & Monitoring - Automated Backups
 * 
 * Firestore backup to Cloud Storage with 30-day retention
 * Daily scheduled backup at 2 AM Asia/Colombo time
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Storage } from '@google-cloud/storage';

const db = admin.firestore();
const storage = new Storage();

// Collections to backup (in order of importance)
const CRITICAL_COLLECTIONS = [
  'users',
  'bookings', 
  'worker_profiles',
  'payments',
  'job_requests',
  'job_offers'
];

const SECONDARY_COLLECTIONS = [
  'notifications',
  'chat_messages',
  'reviews',
  'incidents',
  'feedback'
];

/**
 * Scheduled Firestore Backup - Runs daily at 2 AM Asia/Colombo
 */
export const scheduledFirestoreBackup = functions.pubsub
  .schedule('0 2 * * *')
  .timeZone('Asia/Colombo')
  .onRun(async (context) => {
    const projectId = process.env.GCLOUD_PROJECT || 'helaservice-prod';
    const timestamp = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
    const bucketName = `${projectId}-backups`;
    
    console.log(`🔵 Starting Firestore backup for ${timestamp}`);
    
    try {
      // Ensure backup bucket exists
      await ensureBackupBucket(bucketName);
      
      // Backup critical collections
      const backupStats = {
        timestamp,
        projectId,
        collections: {} as Record<string, number>,
        totalDocuments: 0,
        errors: [] as string[]
      };
      
      // Backup critical collections first
      for (const collection of CRITICAL_COLLECTIONS) {
        try {
          const count = await backupCollection(collection, bucketName, timestamp);
          backupStats.collections[collection] = count;
          backupStats.totalDocuments += count;
          console.log(`✅ Backed up ${collection}: ${count} documents`);
        } catch (error) {
          const errorMsg = `Failed to backup ${collection}: ${error}`;
          console.error(`❌ ${errorMsg}`);
          backupStats.errors.push(errorMsg);
        }
      }
      
      // Backup secondary collections
      for (const collection of SECONDARY_COLLECTIONS) {
        try {
          const count = await backupCollection(collection, bucketName, timestamp);
          backupStats.collections[collection] = count;
          backupStats.totalDocuments += count;
          console.log(`✅ Backed up ${collection}: ${count} documents`);
        } catch (error) {
          const errorMsg = `Failed to backup ${collection}: ${error}`;
          console.warn(`⚠️ ${errorMsg}`);
          backupStats.errors.push(errorMsg);
        }
      }
      
      // Save backup metadata
      await saveBackupMetadata(bucketName, timestamp, backupStats);
      
      // Cleanup old backups (keep 30 days)
      await cleanupOldBackups(bucketName, 30);
      
      // Send success notification
      await notifyBackupComplete(backupStats);
      
      console.log(`🟢 Backup completed: ${backupStats.totalDocuments} documents backed up`);
      
    } catch (error) {
      console.error('🔴 Backup job failed:', error);
      await notifyBackupFailure(error);
      throw error;
    }
  });

/**
 * Manual backup trigger - for on-demand backups
 */
export const manualBackup = functions.https.onCall(async (data, context) => {
  // Verify admin role
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }
  
  const userDoc = await db.collection('users').doc(context.auth.uid).get();
  const userData = userDoc.data();
  
  if (!userData || userData.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }
  
  const projectId = process.env.GCLOUD_PROJECT || 'helaservice-prod';
  const timestamp = new Date().toISOString();
  const bucketName = `${projectId}-backups`;
  const collections = data.collections || CRITICAL_COLLECTIONS;
  
  console.log(`🔵 Manual backup started by ${context.auth.uid}`);
  
  const results: Record<string, number> = {};
  
  for (const collection of collections) {
    try {
      const count = await backupCollection(collection, bucketName, `manual-${timestamp}`);
      results[collection] = count;
    } catch (error) {
      console.error(`Failed to backup ${collection}:`, error);
      results[collection] = -1;
    }
  }
  
  return {
    success: true,
    timestamp,
    results
  };
});

/**
 * List available backups
 */
export const listBackups = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }
  
  const projectId = process.env.GCLOUD_PROJECT || 'helaservice-prod';
  const bucketName = `${projectId}-backups`;
  
  try {
    const [files] = await storage.bucket(bucketName).getFiles({
      prefix: 'backups/',
      delimiter: '/'
    });
    
    const backups = files
      .filter(f => f.name.endsWith('metadata.json'))
      .map(f => {
        const parts = f.name.split('/');
        return {
          date: parts[1],
          path: f.name
        };
      })
      .sort((a, b) => b.date.localeCompare(a.date));
    
    return { backups };
  } catch (error) {
    console.error('Failed to list backups:', error);
    return { backups: [] };
  }
});

/**
 * Restore collection from backup (admin only)
 */
export const restoreFromBackup = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }
  
  const userDoc = await db.collection('users').doc(context.auth.uid).get();
  const userData = userDoc.data();
  
  if (!userData || userData.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }
  
  const { backupDate, collections, dryRun = true } = data;
  
  if (!backupDate || !collections || !Array.isArray(collections)) {
    throw new functions.https.HttpsError('invalid-argument', 'backupDate and collections required');
  }
  
  const projectId = process.env.GCLOUD_PROJECT || 'helaservice-prod';
  const bucketName = `${projectId}-backups`;
  
  console.log(`🟡 Restore initiated by ${context.auth.uid}`, { backupDate, collections, dryRun });
  
  const results: Record<string, { restored: number; errors: number }> = {};
  
  for (const collection of collections) {
    const fileName = `backups/${backupDate}/${collection}.json`;
    
    try {
      const file = storage.bucket(bucketName).file(fileName);
      const [exists] = await file.exists();
      
      if (!exists) {
        results[collection] = { restored: 0, errors: 1 };
        continue;
      }
      
      const [content] = await file.download();
      const documents = JSON.parse(content.toString());
      
      if (dryRun) {
        results[collection] = { restored: documents.length, errors: 0 };
        console.log(`[DRY RUN] Would restore ${documents.length} documents to ${collection}`);
      } else {
        // Actually restore
        const batch = db.batch();
        let count = 0;
        
        for (const doc of documents) {
          const { id, ...data } = doc;
          const ref = db.collection(collection).doc(id);
          batch.set(ref, data);
          count++;
          
          // Commit every 500 operations
          if (count % 500 === 0) {
            await batch.commit();
          }
        }
        
        await batch.commit();
        results[collection] = { restored: count, errors: 0 };
      }
    } catch (error) {
      console.error(`Failed to restore ${collection}:`, error);
      results[collection] = { restored: 0, errors: 1 };
    }
  }
  
  return {
    success: true,
    dryRun,
    results
  };
});

// Helper functions

async function ensureBackupBucket(bucketName: string): Promise<void> {
  try {
    const [exists] = await storage.bucket(bucketName).exists();
    if (!exists) {
      await storage.createBucket(bucketName, {
        location: 'ASIA-SOUTH1',
        storageClass: 'STANDARD',
        versioning: {
          enabled: true
        }
      });
      console.log(`Created backup bucket: ${bucketName}`);
    }
  } catch (error) {
    console.error('Failed to ensure backup bucket:', error);
    throw error;
  }
}

async function backupCollection(
  collection: string, 
  bucketName: string, 
  timestamp: string
): Promise<number> {
  const snapshot = await db.collection(collection).get();
  const documents = snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  }));
  
  if (documents.length === 0) {
    return 0;
  }
  
  const fileName = `backups/${timestamp}/${collection}.json`;
  const file = storage.bucket(bucketName).file(fileName);
  
  await file.save(JSON.stringify(documents, null, 2), {
    contentType: 'application/json',
    metadata: {
      collection,
      documentCount: documents.length,
      backedUpAt: new Date().toISOString()
    }
  });
  
  return documents.length;
}

async function saveBackupMetadata(
  bucketName: string, 
  timestamp: string, 
  stats: any
): Promise<void> {
  const fileName = `backups/${timestamp}/metadata.json`;
  const file = storage.bucket(bucketName).file(fileName);
  
  await file.save(JSON.stringify(stats, null, 2), {
    contentType: 'application/json'
  });
}

async function cleanupOldBackups(bucketName: string, retentionDays: number): Promise<void> {
  const [files] = await storage.bucket(bucketName).getFiles({
    prefix: 'backups/'
  });
  
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - retentionDays);
  
  let deletedCount = 0;
  
  for (const file of files) {
    try {
      const [metadata] = await file.getMetadata();
      const created = new Date(metadata.timeCreated);
      
      if (created < cutoffDate) {
        await file.delete();
        deletedCount++;
      }
    } catch (error) {
      console.warn(`Failed to check/delete file ${file.name}:`, error);
    }
  }
  
  console.log(`Cleaned up ${deletedCount} old backup files`);
}

async function notifyBackupComplete(stats: any): Promise<void> {
  // Add to admin notifications collection
  await db.collection('admin_notifications').add({
    type: 'backup_complete',
    title: 'Daily Backup Completed',
    message: `Backed up ${stats.totalDocuments} documents across ${Object.keys(stats.collections).length} collections`,
    stats,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    read: false
  });
}

async function notifyBackupFailure(error: any): Promise<void> {
  await db.collection('admin_notifications').add({
    type: 'backup_failed',
    title: '🔴 Daily Backup Failed',
    message: error.message || 'Unknown error occurred during backup',
    error: error.toString(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    read: false,
    priority: 'high'
  });
}
