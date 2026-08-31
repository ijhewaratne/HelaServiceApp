import { expect } from 'chai';

/**
 * Gate 0 fix (authenticated worker acceptance, CRITICAL + bookings single
 * source of truth): acceptJob (src/index.ts) used to trust a client-supplied
 * `workerId` in the request payload instead of `context.auth.uid`, and never
 * wrote back to the `bookings` document at all. See the comment on acceptJob
 * itself for the full vulnerability writeup.
 *
 * Run against a live Firestore emulator:
 *   firebase emulators:exec --project demo-gate0-tests --only firestore \
 *     "cd functions && npm test"
 */

process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'demo-gate0-tests';

// firebase-functions-test must be required before the functions module so
// its environment shimming (project id, etc.) is in place first.
// eslint-disable-next-line @typescript-eslint/no-var-requires
const functionsTest = require('firebase-functions-test')();
// eslint-disable-next-line @typescript-eslint/no-var-requires
const myFunctions = require('../lib/index');
// eslint-disable-next-line @typescript-eslint/no-var-requires
const admin = require('firebase-admin');

const db = admin.firestore();
const acceptJob = functionsTest.wrap(myFunctions.acceptJob);

async function clearCollections() {
  const collections = ['job_requests', 'job_offers', 'bookings', 'workers', 'notifications'];
  for (const name of collections) {
    const snap = await db.collection(name).get();
    await Promise.all(snap.docs.map((d: any) => d.ref.delete()));
  }
}

async function seedOffer(jobId: string, workerId: string, bookingId: string) {
  await db.collection('job_requests').doc(jobId).set({
    jobId, bookingId, customerId: 'customer1', serviceType: 'cleaning', status: 'dispatching',
  });
  await db.collection('bookings').doc(bookingId).set({
    customerId: 'customer1', status: 'pending', offeredWorkerIds: [workerId],
  });
  await db.collection('job_offers').doc(`${jobId}_${workerId}`).set({
    jobId, workerId, status: 'pending',
  });
  await db.collection('workers').doc(workerId).set({ fullName: `Worker ${workerId}` });
}

describe('acceptJob (Gate 0: authenticated worker acceptance)', function () {
  this.timeout(20000);

  afterEach(async () => {
    await clearCollections();
  });

  after(() => {
    functionsTest.cleanup();
  });

  it('VULNERABILITY: ignores a client-supplied workerId and assigns to context.auth.uid instead', async () => {
    await seedOffer('job1', 'workerA', 'booking1');
    // workerA is the one actually offered the job and actually authenticated;
    // the payload lies and claims to be accepting on behalf of workerB.
    await seedOffer('job1', 'workerB', 'bookingNever'); // workerB has its own unrelated offer/booking

    const result = await acceptJob(
      { jobId: 'job1', workerId: 'workerB' }, // spoofed
      { auth: { uid: 'workerA' } },
    );

    expect(result.success).to.equal(true);
    const jobDoc = await db.collection('job_requests').doc('job1').get();
    expect(jobDoc.data()?.assignedWorkerId).to.equal('workerA'); // not workerB
  });

  it('VULNERABILITY (only the offered provider can accept): a worker never offered the job cannot accept it', async () => {
    await seedOffer('job1', 'workerA', 'booking1');

    let threw = false;
    try {
      await acceptJob({ jobId: 'job1' }, { auth: { uid: 'workerC' } });
    } catch (e) {
      threw = true;
    }
    expect(threw).to.equal(true, 'workerC (never offered) should not be able to accept');

    const jobDoc = await db.collection('job_requests').doc('job1').get();
    expect(jobDoc.data()?.assignedWorkerId).to.be.undefined;
  });

  it('rejects a call with no auth context at all', async () => {
    await seedOffer('job1', 'workerA', 'booking1');
    let threw = false;
    try {
      await acceptJob({ jobId: 'job1' }, { auth: null });
    } catch (e: any) {
      threw = true;
      expect(e.code).to.equal('unauthenticated');
    }
    expect(threw).to.equal(true);
  });

  it('atomicity: of two workers racing for the same job, exactly one wins', async () => {
    await seedOffer('job1', 'workerA', 'booking1');
    // Give workerB their own offer on the SAME job (mirrors the real
    // dispatchJob flow, which offers one job to up to 3 workers at once).
    await db.collection('job_offers').doc('job1_workerB').set({
      jobId: 'job1', workerId: 'workerB', status: 'pending',
    });
    await db.collection('workers').doc('workerB').set({ fullName: 'Worker B' });

    const results = await Promise.allSettled([
      acceptJob({ jobId: 'job1' }, { auth: { uid: 'workerA' } }),
      acceptJob({ jobId: 'job1' }, { auth: { uid: 'workerB' } }),
    ]);

    const fulfilled = results.filter((r) => r.status === 'fulfilled');
    const rejected = results.filter((r) => r.status === 'rejected');
    expect(fulfilled.length).to.equal(1, 'exactly one acceptance should succeed');
    expect(rejected.length).to.equal(1, 'exactly one acceptance should be rejected');

    const jobDoc = await db.collection('job_requests').doc('job1').get();
    expect(['workerA', 'workerB']).to.include(jobDoc.data()?.assignedWorkerId);

    // Gate 0: bookings is the single source of truth — the winner must be
    // reflected there too, atomically, in the same operation.
    const bookingDoc = await db.collection('bookings').doc('booking1').get();
    expect(bookingDoc.data()?.status).to.equal('confirmed');
    expect(bookingDoc.data()?.workerId).to.equal(jobDoc.data()?.assignedWorkerId);
  });

  it('bookings single source of truth: a successful acceptance syncs workerId/status onto the booking', async () => {
    await seedOffer('job1', 'workerA', 'booking1');
    await acceptJob({ jobId: 'job1' }, { auth: { uid: 'workerA' } });

    const bookingDoc = await db.collection('bookings').doc('booking1').get();
    expect(bookingDoc.data()?.workerId).to.equal('workerA');
    expect(bookingDoc.data()?.status).to.equal('confirmed');
    expect(bookingDoc.data()?.offeredWorkerIds).to.be.undefined;
  });

  it('a worker cannot accept a job that is already assigned', async () => {
    await seedOffer('job1', 'workerA', 'booking1');
    await acceptJob({ jobId: 'job1' }, { auth: { uid: 'workerA' } });

    await db.collection('job_offers').doc('job1_workerB').set({
      jobId: 'job1', workerId: 'workerB', status: 'pending',
    });
    let threw = false;
    try {
      await acceptJob({ jobId: 'job1' }, { auth: { uid: 'workerB' } });
    } catch (e) {
      threw = true;
    }
    expect(threw).to.equal(true);
  });
});
