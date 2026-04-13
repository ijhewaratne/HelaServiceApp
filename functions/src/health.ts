/**
 * Phase 6: DevOps & Monitoring - Health Check Endpoints
 * 
 * Provides health status for:
 * - Firebase Functions
 * - Firestore connectivity
 * - Cloud Storage
 * - External service integrations
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

interface HealthStatus {
  status: 'healthy' | 'degraded' | 'unhealthy';
  timestamp: string;
  version: string;
  environment: string;
  checks: {
    firestore: ServiceCheck;
    storage: ServiceCheck;
    auth: ServiceCheck;
    functions: ServiceCheck;
    externalServices?: Record<string, ServiceCheck>;
  };
  metrics?: {
    responseTimeMs: number;
    activeConnections?: number;
    requestRate?: number;
  };
}

interface ServiceCheck {
  status: 'up' | 'down' | 'degraded';
  responseTimeMs: number;
  message?: string;
  lastError?: string;
}

const START_TIME = Date.now();
const VERSION = process.env.FUNCTIONS_VERSION || '1.0.0';

/**
 * Main health check endpoint - HTTP
 * Returns comprehensive system health status
 */
export const healthCheck = functions.https.onRequest(async (req, res) => {
  const requestStart = Date.now();
  
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET');
  res.set('Access-Control-Allow-Headers', 'Content-Type');
  
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }
  
  try {
    const health = await performHealthChecks();
    const responseTime = Date.now() - requestStart;
    
    health.metrics = {
      responseTimeMs: responseTime
    };
    
    // Determine HTTP status code based on health
    const httpStatus = health.status === 'healthy' ? 200 : 
                       health.status === 'degraded' ? 200 : 503;
    
    res.status(httpStatus).json(health);
    
  } catch (error) {
    console.error('Health check failed:', error);
    
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      version: VERSION,
      environment: process.env.NODE_ENV || 'unknown',
      error: error instanceof Error ? error.message : 'Unknown error',
      checks: {}
    });
  }
});

/**
 * Callable health check - for admin dashboard
 */
export const getSystemHealth = functions.https.onCall(async (data, context) => {
  // Verify admin
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }
  
  const userDoc = await db.collection('users').doc(context.auth.uid).get();
  const userData = userDoc.data();
  
  if (!userData || userData.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }
  
  const health = await performHealthChecks();
  
  // Add additional metrics for admin view
  const metrics = await getDetailedMetrics();
  
  return {
    ...health,
    detailedMetrics: metrics
  };
});

/**
 * Simple ping endpoint - for uptime monitoring
 */
export const ping = functions.https.onRequest((req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: Date.now() - START_TIME
  });
});

/**
 * Readiness probe - for Kubernetes/GCP health checks
 */
export const ready = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  
  try {
    // Quick check - just verify Firestore is accessible
    await db.collection('health_check').doc('ping').set({
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
    
    res.status(200).json({ ready: true });
  } catch (error) {
    res.status(503).json({ ready: false, error: 'Database unavailable' });
  }
});

/**
 * Liveness probe - for Kubernetes/GCP health checks
 */
export const live = functions.https.onRequest((req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.status(200).json({ alive: true });
});

// Helper functions

async function performHealthChecks(): Promise<HealthStatus> {
  const checks: HealthStatus['checks'] = {
    firestore: await checkFirestore(),
    storage: await checkStorage(),
    auth: await checkAuth(),
    functions: await checkFunctions()
  };
  
  // Check external services if configured
  const externalServices = await checkExternalServices();
  if (Object.keys(externalServices).length > 0) {
    checks.externalServices = externalServices;
  }
  
  // Determine overall status
  const serviceStatuses = [
    checks.firestore.status,
    checks.storage.status,
    checks.auth.status,
    checks.functions.status
  ];
  
  let overallStatus: HealthStatus['status'] = 'healthy';
  
  if (serviceStatuses.some(s => s === 'down')) {
    overallStatus = 'unhealthy';
  } else if (serviceStatuses.some(s => s === 'degraded')) {
    overallStatus = 'degraded';
  }
  
  return {
    status: overallStatus,
    timestamp: new Date().toISOString(),
    version: VERSION,
    environment: process.env.NODE_ENV || 'production',
    checks
  };
}

async function checkFirestore(): Promise<ServiceCheck> {
  const start = Date.now();
  
  try {
    // Test write
    await db.collection('health_check').doc('test').set({
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      check: 'write'
    });
    
    // Test read
    const doc = await db.collection('health_check').doc('test').get();
    
    if (!doc.exists) {
      return {
        status: 'down',
        responseTimeMs: Date.now() - start,
        message: 'Read verification failed'
      };
    }
    
    const responseTime = Date.now() - start;
    
    return {
      status: responseTime > 2000 ? 'degraded' : 'up',
      responseTimeMs: responseTime,
      message: 'Read/write operations successful'
    };
    
  } catch (error) {
    return {
      status: 'down',
      responseTimeMs: Date.now() - start,
      message: 'Connection failed',
      lastError: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

async function checkStorage(): Promise<ServiceCheck> {
  const start = Date.now();
  
  try {
    const bucket = admin.storage().bucket();
    const [exists] = await bucket.exists();
    
    if (!exists) {
      return {
        status: 'down',
        responseTimeMs: Date.now() - start,
        message: 'Default storage bucket not found'
      };
    }
    
    return {
      status: 'up',
      responseTimeMs: Date.now() - start,
      message: 'Storage accessible'
    };
    
  } catch (error) {
    return {
      status: 'down',
      responseTimeMs: Date.now() - start,
      message: 'Storage check failed',
      lastError: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

async function checkAuth(): Promise<ServiceCheck> {
  const start = Date.now();
  
  try {
    // Try to get project config (lightweight operation)
    await admin.auth().getProjectConfig();
    
    return {
      status: 'up',
      responseTimeMs: Date.now() - start,
      message: 'Auth service responsive'
    };
    
  } catch (error) {
    // getProjectConfig might fail due to permissions, which is OK
    // as long as the service is reachable
    if (error instanceof Error && error.message.includes('permission')) {
      return {
        status: 'up',
        responseTimeMs: Date.now() - start,
        message: 'Auth service reachable'
      };
    }
    
    return {
      status: 'degraded',
      responseTimeMs: Date.now() - start,
      message: 'Auth service check inconclusive',
      lastError: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

async function checkFunctions(): Promise<ServiceCheck> {
  const start = Date.now();
  
  // Functions are running if this code executes
  return {
    status: 'up',
    responseTimeMs: Date.now() - start,
    message: 'Functions runtime active'
  };
}

async function checkExternalServices(): Promise<Record<string, ServiceCheck>> {
  const results: Record<string, ServiceCheck> = {};
  
  // Check PayHere API (if configured)
  try {
    const payhereCheck = await checkPayHereHealth();
    results.payhere = payhereCheck;
  } catch (error) {
    // External service not configured or failed
  }
  
  // Check Google Maps API (if configured)
  try {
    const mapsCheck = await checkGoogleMapsHealth();
    results.googleMaps = mapsCheck;
  } catch (error) {
    // External service not configured
  }
  
  return results;
}

async function checkPayHereHealth(): Promise<ServiceCheck> {
  const start = Date.now();
  
  try {
    // Check PayHere API status
    const response = await fetch('https://sandbox.payhere.lk/health', {
      method: 'HEAD',
      signal: AbortSignal.timeout(5000)
    });
    
    return {
      status: response.ok ? 'up' : 'degraded',
      responseTimeMs: Date.now() - start,
      message: response.ok ? 'PayHere API reachable' : 'PayHere API issues'
    };
    
  } catch (error) {
    return {
      status: 'down',
      responseTimeMs: Date.now() - start,
      message: 'PayHere API unreachable',
      lastError: error instanceof Error ? error.message : 'Connection failed'
    };
  }
}

async function checkGoogleMapsHealth(): Promise<ServiceCheck> {
  const start = Date.now();
  
  try {
    const apiKey = functions.config().googlemaps?.apikey;
    
    if (!apiKey) {
      return {
        status: 'down',
        responseTimeMs: Date.now() - start,
        message: 'API key not configured'
      };
    }
    
    // Test geocoding API
    const response = await fetch(
      `https://maps.googleapis.com/maps/api/geocode/json?address=Colombo&key=${apiKey}`,
      { signal: AbortSignal.timeout(5000) }
    );
    
    const data = await response.json();
    
    return {
      status: data.status === 'OK' ? 'up' : 'degraded',
      responseTimeMs: Date.now() - start,
      message: data.status === 'OK' ? 'Maps API operational' : `Maps API: ${data.status}`
    };
    
  } catch (error) {
    return {
      status: 'down',
      responseTimeMs: Date.now() - start,
      message: 'Maps API unreachable',
      lastError: error instanceof Error ? error.message : 'Connection failed'
    };
  }
}

async function getDetailedMetrics(): Promise<Record<string, any>> {
  const metrics: Record<string, any> = {};
  
  try {
    // Get user counts
    const [userCount] = await Promise.all([
      db.collection('users').count().get()
    ]);
    metrics.totalUsers = userCount.data().count;
    
    // Get active bookings count
    const activeBookings = await db.collection('bookings')
      .where('status', 'in', ['pending', 'confirmed', 'inProgress'])
      .count()
      .get();
    metrics.activeBookings = activeBookings.data().count;
    
    // Get online workers count
    const onlineWorkers = await db.collection('worker_locations')
      .where('status', '==', 'online')
      .count()
      .get();
    metrics.onlineWorkers = onlineWorkers.data().count;
    
    // Get today's bookings
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const todaysBookings = await db.collection('bookings')
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(today))
      .count()
      .get();
    metrics.todaysBookings = todaysBookings.data().count;
    
  } catch (error) {
    console.error('Failed to get detailed metrics:', error);
    metrics.error = 'Failed to fetch metrics';
  }
  
  return metrics;
}
