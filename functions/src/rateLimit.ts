import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Rate Limiting for Cloud Functions
 * Sprint 5: Security Hardening
 * 
 * Provides rate limiting for sensitive operations to prevent abuse
 */

// Rate limit configuration
interface RateLimitConfig {
  /** Maximum requests per window */
  maxRequests: number;
  /** Time window in milliseconds */
  windowMs: number;
  /** Key prefix for Firestore documents */
  keyPrefix: string;
}

// Default rate limits for different operations
const DEFAULT_LIMITS: Record<string, RateLimitConfig> = {
  // OTP requests: 3 per minute
  otp: { maxRequests: 3, windowMs: 60000, keyPrefix: 'otp' },
  
  // Job creation: 10 per minute
  jobCreate: { maxRequests: 10, windowMs: 60000, keyPrefix: 'job_create' },
  
  // Feedback submission: 5 per hour
  feedback: { maxRequests: 5, windowMs: 3600000, keyPrefix: 'feedback' },
  
  // Search requests: 30 per minute
  search: { maxRequests: 30, windowMs: 60000, keyPrefix: 'search' },
  
  // API calls (general): 100 per minute
  general: { maxRequests: 100, windowMs: 60000, keyPrefix: 'general' },
};

/**
 * Rate limit result
 */
interface RateLimitResult {
  /** Whether the request is allowed */
  allowed: boolean;
  /** Remaining requests in current window */
  remaining: number;
  /** Time when the rate limit resets (ms since epoch) */
  resetTime: number;
  /** Current request count in window */
  currentCount: number;
}

/**
 * Check rate limit for a user/operation combination
 * 
 * @param userId - The authenticated user ID
 * @param operation - The operation type (otp, jobCreate, etc.)
 * @param config - Optional custom rate limit config
 * @returns Rate limit result
 */
export async function checkRateLimit(
  userId: string,
  operation: string,
  config?: RateLimitConfig
): Promise<RateLimitResult> {
  const db = admin.firestore();
  const rateLimitConfig = config || DEFAULT_LIMITS[operation] || DEFAULT_LIMITS.general;
  
  // Create document ID: rate_limits/{userId}_{operation}
  const docId = `${userId}_${rateLimitConfig.keyPrefix}`;
  const rateLimitRef = db.collection('rate_limits').doc(docId);
  
  const now = Date.now();
  const windowStart = now - rateLimitConfig.windowMs;
  
  try {
    // Use transaction for atomic read/write
    const result = await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(rateLimitRef);
      
      if (!doc.exists) {
        // First request - create new entry
        const newData = {
          userId,
          operation: rateLimitConfig.keyPrefix,
          requests: 1,
          windowStart: admin.firestore.Timestamp.fromMillis(now),
          lastRequest: admin.firestore.FieldValue.serverTimestamp(),
        };
        
        transaction.set(rateLimitRef, newData);
        
        return {
          allowed: true,
          remaining: rateLimitConfig.maxRequests - 1,
          resetTime: now + rateLimitConfig.windowMs,
          currentCount: 1,
        };
      }
      
      const data = doc.data()!;
      const docWindowStart = data.windowStart.toMillis();
      let requests = data.requests || 0;
      
      // Check if window has expired
      if (docWindowStart < windowStart) {
        // Reset window
        const newData = {
          userId,
          operation: rateLimitConfig.keyPrefix,
          requests: 1,
          windowStart: admin.firestore.Timestamp.fromMillis(now),
          lastRequest: admin.firestore.FieldValue.serverTimestamp(),
        };
        
        transaction.set(rateLimitRef, newData);
        
        return {
          allowed: true,
          remaining: rateLimitConfig.maxRequests - 1,
          resetTime: now + rateLimitConfig.windowMs,
          currentCount: 1,
        };
      }
      
      // Check if limit exceeded
      if (requests >= rateLimitConfig.maxRequests) {
        return {
          allowed: false,
          remaining: 0,
          resetTime: docWindowStart + rateLimitConfig.windowMs,
          currentCount: requests,
        };
      }
      
      // Increment request count
      transaction.update(rateLimitRef, {
        requests: admin.firestore.FieldValue.increment(1),
        lastRequest: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return {
        allowed: true,
        remaining: rateLimitConfig.maxRequests - requests - 1,
        resetTime: docWindowStart + rateLimitConfig.windowMs,
        currentCount: requests + 1,
      };
    });
    
    return result;
  } catch (error) {
    console.error('Rate limit check failed:', error);
    // Fail open - allow request if rate limit check fails
    return {
      allowed: true,
      remaining: 0,
      resetTime: now + rateLimitConfig.windowMs,
      currentCount: 0,
    };
  }
}

/**
 * Callable function wrapper with rate limiting
 * 
 * Usage:
 * ```typescript
 * export const myFunction = withRateLimit('operationType', async (data, context) => {
 *   // Your function logic here
 * });
 * ```
 */
export function withRateLimit(
  operation: string,
  handler: (data: any, context: functions.https.CallableContext) => Promise<any>,
  config?: RateLimitConfig
): functions.HttpsFunction {
  return functions.https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }
    
    const userId = context.auth.uid;
    
    // Check rate limit
    const rateLimit = await checkRateLimit(userId, operation, config);
    
    if (!rateLimit.allowed) {
      const retryAfter = Math.ceil((rateLimit.resetTime - Date.now()) / 1000);
      
      throw new functions.https.HttpsError(
        'resource-exhausted',
        `Rate limit exceeded. Try again in ${retryAfter} seconds.`,
        {
          retryAfter,
          resetTime: rateLimit.resetTime,
        }
      );
    }
    
    // Add rate limit info to context for potential use
    (context as any).rateLimit = rateLimit;
    
    // Execute handler
    return handler(data, context);
  });
}

/**
 * HTTP function wrapper with rate limiting (for non-callable functions)
 */
export function withHttpRateLimit(
  operation: string,
  handler: (req: functions.Request, res: functions.Response) => Promise<void>,
  config?: RateLimitConfig
): functions.HttpsFunction {
  return functions.https.onRequest(async (req, res) => {
    // Extract user ID from auth token or IP address
    const userId = req.headers.authorization 
      ? await getUserIdFromToken(req.headers.authorization)
      : req.ip || req.connection.remoteAddress || 'anonymous';
    
    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }
    
    // Check rate limit
    const rateLimit = await checkRateLimit(userId, operation, config);
    
    // Add rate limit headers
    res.set('X-RateLimit-Limit', String(config?.maxRequests || DEFAULT_LIMITS[operation]?.maxRequests || 100));
    res.set('X-RateLimit-Remaining', String(rateLimit.remaining));
    res.set('X-RateLimit-Reset', String(Math.ceil(rateLimit.resetTime / 1000)));
    
    if (!rateLimit.allowed) {
      const retryAfter = Math.ceil((rateLimit.resetTime - Date.now()) / 1000);
      res.set('Retry-After', String(retryAfter));
      res.status(429).json({
        error: 'Too Many Requests',
        message: `Rate limit exceeded. Try again in ${retryAfter} seconds.`,
        retryAfter,
      });
      return;
    }
    
    // Execute handler
    await handler(req, res);
  });
}

/**
 * Extract user ID from Bearer token
 */
async function getUserIdFromToken(authHeader: string): Promise<string | null> {
  try {
    const token = authHeader.replace('Bearer ', '');
    const decodedToken = await admin.auth().verifyIdToken(token);
    return decodedToken.uid;
  } catch (error) {
    console.error('Token verification failed:', error);
    return null;
  }
}

/**
 * Example: Rate-limited OTP request function
 */
export const requestOTP = withRateLimit(
  'otp',
  async (data: { phoneNumber: string }, context) => {
    const { phoneNumber } = data;
    
    // Validate phone number
    const phoneRegex = /^\+94[0-9]{9}$/;
    if (!phoneRegex.test(phoneNumber)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid phone number format'
      );
    }
    
    // Generate and send OTP (implementation depends on your SMS provider)
    // This is just a placeholder
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Store OTP in Firestore with expiry
    const db = admin.firestore();
    await db.collection('otp_codes').doc(phoneNumber).set({
      code: otp,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 300000), // 5 minutes
      attempts: 0,
    });
    
    // TODO: Send actual SMS via provider (e.g., Twilio, MessageBird)
    console.log(`OTP for ${phoneNumber}: ${otp}`);
    
    return {
      success: true,
      message: 'OTP sent successfully',
      // Don't return actual OTP in production!
      ...(process.env.NODE_ENV === 'development' && { otp }),
    };
  }
);

/**
 * Example: Rate-limited job creation
 */
export const createJob = withRateLimit(
  'jobCreate',
  async (data: any, context) => {
    const db = admin.firestore();
    
    // Validate required fields
    if (!data.customerId || !data.serviceType || !data.location) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required fields'
      );
    }
    
    // Verify customerId matches authenticated user
    if (data.customerId !== context.auth!.uid) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Can only create jobs for yourself'
      );
    }
    
    // Create job
    const jobRef = db.collection('jobs').doc();
    const jobData = {
      ...data,
      id: jobRef.id,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    
    await jobRef.set(jobData);
    
    return {
      success: true,
      jobId: jobRef.id,
    };
  }
);

/**
 * Cleanup old rate limit documents (run periodically via scheduled function)
 */
export async function cleanupRateLimits(): Promise<number> {
  const db = admin.firestore();
  const cutoff = Date.now() - (24 * 60 * 60 * 1000); // 24 hours ago
  
  const snapshot = await db
    .collection('rate_limits')
    .where('windowStart', '<', admin.firestore.Timestamp.fromMillis(cutoff))
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
  
  return count;
}
