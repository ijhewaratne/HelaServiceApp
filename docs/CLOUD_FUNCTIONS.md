# Appendix B: Cloud Functions (Complete)

This document describes the Firebase Cloud Functions for HelaService.

## Overview

Cloud Functions handle:
- Job dispatch and matching algorithm
- Payment webhooks (PayHere)
- Background tasks
- Integration with third-party services

## Functions Location

All functions are in `/functions/src/index.ts`

## Main Functions

### 1. `dispatchJob` (Firestore Trigger)

**Trigger**: On create of `job_requests/{jobId}`

**Purpose**: PickMe-style algorithm to find and dispatch jobs to eligible workers.

**Algorithm**:
1. Find online workers within zone radius
2. Filter by: skills match, verified status, within 5km
3. Score workers:
   - 50% - Proximity to customer
   - 30% - Idle time (prefer workers who haven't worked recently)
   - 20% - Distance from home
4. Select top 3 workers
5. Create job offers with 30-second timeout
6. Send FCM notifications

**Code**:
```typescript
export const dispatchJob = functions.firestore
  .document('job_requests/{jobId}')
  .onCreate(async (snap, context) => {
    const job = snap.data();
    const jobId = context.params.jobId;
    
    // Find, score, and dispatch to top 3 workers
    const candidates = await findEligibleWorkers(job);
    const scored = scoreWorkers(candidates, job);
    const top3 = scored.slice(0, 3);
    
    // Create offers and notify
    await createOffers(jobId, top3, job);
    await sendJobOfferNotifications(top3, job);
    
    // Schedule timeout
    setTimeout(() => handleOfferTimeout(jobId, top3.map(w => w.workerId)), 35000);
  });
```

### 2. `acceptJob` (Callable Function)

**Purpose**: Worker accepts a job offer. Race-condition safe via transactions.

**Input**:
```typescript
{
  jobId: string;
  workerId: string;
}
```

**Transaction Logic**:
1. Verify job exists and is available
2. Verify offer exists and belongs to worker
3. Check job not already assigned (race condition prevention)
4. Assign job to worker
5. Cancel all other pending offers
6. Update worker status (isAvailable: false)

**Error Handling**:
- `unauthenticated` - User not logged in
- `failed-precondition` - Job already taken
- `not-found` - Job or offer doesn't exist

### 3. `payhereNotify` (HTTP Webhook)

**Trigger**: PayHere payment completion webhook

**Purpose**: Verify payment status and update booking

**Security**:
- MD5 signature verification
- IP whitelist (PayHere servers)
- Idempotency check (prevent duplicate processing)

**Flow**:
1. Validate MD5 signature
2. Check payment status
3. Update booking status to 'paid'
4. Trigger job dispatch if newly paid
5. Send confirmation to customer

### 4. `updateWorkerLocation` (Firestore Trigger)

**Trigger**: On write to `worker_locations/{workerId}`

**Purpose**: Geohash maintenance and availability tracking

### 5. `sendScheduledNotifications` (Pub/Sub Scheduled)

**Trigger**: Every 5 minutes

**Purpose**: Send reminders for upcoming bookings

**Logic**:
- Find jobs starting in 15-30 minutes
- Send "Heading to customer?" to worker
- Send "Your service starts soon" to customer

### 6. `cleanUpOldData` (Pub/Sub Scheduled)

**Trigger**: Daily at 3 AM

**Purpose**: Data retention compliance (PDPA)

**Tasks**:
- Delete chat messages older than 30 days
- Archive completed jobs older than 1 year
- Clear expired job offers
- Anonymize cancelled bookings older than 90 days

## Helper Functions

### `findEligibleWorkers(job)`

Finds workers available for a job.

**Criteria**:
- Status: online
- In zone (geohash query)
- Within 5km of customer
- Has required skill
- Verified status

**Returns**: Array of worker objects with distance

### `scoreWorkers(workers, job)`

Ranks workers by composite score.

**Scoring Formula**:
```
finalScore = (distanceScore * 0.5) + (idleScore * 0.3) + (homeScore * 0.2)

where:
  distanceScore = 1 / (distanceKm + 0.1)
  idleScore = min(idleMinutes / 60, 2)
  homeScore = 1 / (distanceFromHomeKm + 0.1)
```

### `sendJobOfferNotifications(workers, job)`

Sends FCM push notifications to workers.

**Notification Content**:
- Title: "New Job Available!"
- Body: `{serviceType} job nearby - LKR {estimatedEarnings}`
- Data: `{ jobId, type: 'job_offer' }`

### `handleOfferTimeout(jobId, workerIds)`

Handles expired job offers.

**Logic**:
1. Check if job already assigned
2. If not, mark all offers as expired
3. Update job status to 'no_workers_available'
4. Notify customer

## Service Zones

```typescript
const SERVICE_ZONES = {
  'col_03_04': { center: { lat: 6.8940, lng: 79.8580 }, radiusKm: 2.5 },
  'col_07': { center: { lat: 6.9119, lng: 79.8716 }, radiusKm: 3.0 },
  'rajagiriya': { center: { lat: 6.9108, lng: 79.8927 }, radiusKm: 2.0 }
};
```

## Deployment

### Deploy all functions
```bash
cd functions
npm run build
firebase deploy --only functions
```

### Deploy specific function
```bash
firebase deploy --only functions:dispatchJob
```

### Set environment variables
```bash
firebase functions:config:set payhere.merchantsecret="..."
firebase functions:config:set payhere.sandbox="true"
```

## Local Development

### Emulator setup
```bash
firebase emulators:start --only functions,firestore
```

### Test callable function
```bash
curl -X POST http://localhost:5001/helaservice-prod/acceptJob \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  -d '{"jobId": "...", "workerId": "..."}'
```

## Monitoring

### View logs
```bash
firebase functions:log
```

### Monitor in Firebase Console
- Go to Functions → Dashboard
- Check execution count, errors, latency

### Set up alerts
- Error rate > 5%
- Execution time > 10s
- Memory usage > 80%

## Testing

### Unit Tests
Located in `/functions/src/__tests__/`

```bash
npm test
```

### Key Test Cases
1. Job dispatch with no available workers
2. Race condition - two workers accept simultaneously
3. Payment webhook with invalid signature
4. Worker location outside zone boundary

## Performance Optimization

### Caching
- Worker availability cached for 30 seconds
- Service zone calculations cached

### Batching
- Offer creation uses Firestore batch writes
- Notifications sent via multicast (up to 500 tokens)

### Concurrency
- Default: 80 concurrent instances
- Memory: 256MB (can increase for heavy operations)

## Error Handling

### Retry Policy
```typescript
const runtimeOpts = {
  failurePolicy: {
    retry: {
      maxAttempts: 3,
      minBackoffSeconds: 10,
    },
  },
};

export const dispatchJob = functions
  .runWith(runtimeOpts)
  .firestore.document('job_requests/{jobId}')
  .onCreate(...);
```

### Dead Letter Queue
Failed events are written to `failed_events/{eventId}` for manual review.

## Security

### Authentication
- All callable functions verify `context.auth`
- Admin operations check `context.auth.token.admin`

### Input Validation
```typescript
const dataSchema = Joi.object({
  jobId: Joi.string().required(),
  workerId: Joi.string().required(),
});

const { error } = dataSchema.validate(data);
if (error) throw new functions.https.HttpsError('invalid-argument', error.message);
```

### Rate Limiting
- Accept job: 10 requests/minute per worker
- Webhook: 100 requests/minute globally

## Complete Source Code

See `/functions/src/index.ts` for the complete implementation.

### Key Imports
```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as geofire from 'geofire-common';
```

### Initialization
```typescript
admin.initializeApp();
const db = admin.firestore();
```

### Exports
```typescript
export { dispatchJob, acceptJob, payhereNotify };
```
