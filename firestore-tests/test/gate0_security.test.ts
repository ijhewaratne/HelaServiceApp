/**
 * Gate 0 security & core-flow stabilization — Firestore/Storage rules tests.
 *
 * Each `describe` block below encodes one of the vulnerabilities named in
 * the Gate 0 sprint. Run against the ORIGINAL (pre-Gate-0) firestore.rules /
 * storage.rules, every test in this file that starts with "VULNERABILITY:"
 * fails (assertFails throws because the bad action actually succeeds, or
 * assertSucceeds throws because the good action is wrongly denied). Against
 * the fixed rules in this branch, they all pass.
 *
 * Run with the emulator up:
 *   firebase emulators:exec --project demo-gate0 \
 *     --only firestore,storage,auth "npm test" (from repo root)
 * or, with emulators already running separately:
 *   npm test (from this directory)
 */
import * as fs from 'fs';
import * as path from 'path';
import { expect } from 'chai';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import type { RulesTestEnvironment } from '@firebase/rules-unit-testing';

const PROJECT_ID = 'demo-gate0-tests';

let testEnv: RulesTestEnvironment;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(path.resolve(process.cwd(), '../firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
    storage: {
      rules: fs.readFileSync(path.resolve(process.cwd(), '../storage.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 9199,
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.clearStorage();
});

describe('Gate 0: role escalation (users/{uid})', () => {
  it('VULNERABILITY: a normal user cannot set role: "admin" on their own user doc', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      alice.firestore().collection('users').doc('alice').set({ role: 'admin' }),
    );
  });

  it('VULNERABILITY: a normal user cannot self-promote userType to "admin"', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      alice.firestore().collection('users').doc('alice').set({ userType: 'admin' }),
    );
  });

  it('a user can still legitimately set userType to "customer" during onboarding', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      alice.firestore().collection('users').doc('alice').set({ userType: 'customer' }),
    );
  });

  it('a user cannot write role on another user\'s doc', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      alice.firestore().collection('users').doc('bob').set({ role: 'admin' }),
    );
  });
});

describe('Gate 0: provider self-approval (worker_applications, workers)', () => {
  it('VULNERABILITY: a worker cannot set their own application status to "approved"', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('worker_applications').doc('worker1').set({
        nic: '123', status: 'pending',
      });
    });
    const worker1 = testEnv.authenticatedContext('worker1');
    await assertFails(
      worker1.firestore().collection('worker_applications').doc('worker1')
        .update({ status: 'approved' }),
    );
  });

  it('a worker can still edit their own application content', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('worker_applications').doc('worker1').set({
        nic: '123', status: 'pending',
      });
    });
    const worker1 = testEnv.authenticatedContext('worker1');
    await assertSucceeds(
      worker1.firestore().collection('worker_applications').doc('worker1')
        .update({ nic: '999999999V' }),
    );
  });

  it('VULNERABILITY: a worker cannot self-elevate their own verificationTier', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('workers').doc('worker1').set({
        isVerified: false, verificationTier: 'green',
      });
    });
    const worker1 = testEnv.authenticatedContext('worker1');
    await assertFails(
      worker1.firestore().collection('workers').doc('worker1')
        .update({ verificationTier: 'gold' }),
    );
  });

  it('a worker still cannot self-set isVerified (pre-existing, unchanged protection)', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('workers').doc('worker1').set({ isVerified: false });
    });
    const worker1 = testEnv.authenticatedContext('worker1');
    await assertFails(
      worker1.firestore().collection('workers').doc('worker1').update({ isVerified: true }),
    );
  });
});

// UploadTask is thenable but not a strict Promise per its TS typings —
// `.then(() => undefined)` gives assertSucceeds/assertFails a real Promise.
function put(ref: any, data: Buffer, contentType: string): Promise<void> {
  return ref.put(data, { contentType }).then(() => undefined);
}

describe('Gate 0: Storage rules (worker document upload)', () => {
  it('VULNERABILITY: a worker cannot upload a file larger than 5MB', async () => {
    const worker1 = testEnv.authenticatedContext('worker1');
    const bigFile = Buffer.alloc(6 * 1024 * 1024, 'a'); // 6MB
    await assertFails(
      put(worker1.storage().ref('workers/worker1/nic_front.jpg'), bigFile, 'image/jpeg'),
    );
  });

  it('VULNERABILITY: a worker cannot upload a non-image file', async () => {
    const worker1 = testEnv.authenticatedContext('worker1');
    const exe = Buffer.from('not an image');
    await assertFails(
      put(worker1.storage().ref('workers/worker1/payload.exe'), exe, 'application/octet-stream'),
    );
  });

  it('a worker CAN upload a small image', async () => {
    const worker1 = testEnv.authenticatedContext('worker1');
    const small = Buffer.alloc(1024, 'a');
    await assertSucceeds(
      put(worker1.storage().ref('workers/worker1/nic_front.jpg'), small, 'image/jpeg'),
    );
  });

  it('a different worker cannot upload to worker1\'s path', async () => {
    const worker2 = testEnv.authenticatedContext('worker2');
    const small = Buffer.alloc(1024, 'a');
    await assertFails(
      put(worker2.storage().ref('workers/worker1/nic_front.jpg'), small, 'image/jpeg'),
    );
  });
});

describe('Gate 0: audit log permissions', () => {
  it('VULNERABILITY: a normal authenticated user cannot create an audit_logs entry', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      alice.firestore().collection('audit_logs').add({
        adminUserId: 'alice', actionType: 'fake_entry',
      }),
    );
  });

  it('an admin can create an audit_logs entry attributed to themselves', async () => {
    const admin1 = testEnv.authenticatedContext('admin1', { admin: true });
    await assertSucceeds(
      admin1.firestore().collection('audit_logs').add({
        adminUserId: 'admin1', actionType: 'approve_review',
      }),
    );
  });

  it('VULNERABILITY: an admin cannot forge another admin as the actor', async () => {
    const admin1 = testEnv.authenticatedContext('admin1', { admin: true });
    await assertFails(
      admin1.firestore().collection('audit_logs').add({
        adminUserId: 'someone-else', actionType: 'approve_review',
      }),
    );
  });

  it('audit_logs remain immutable — no update or delete, even for admins', async () => {
    let logId = '';
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const ref = await ctx.firestore().collection('audit_logs').add({ adminUserId: 'x' });
      logId = ref.id;
    });
    const admin1 = testEnv.authenticatedContext('admin1', { admin: true });
    await assertFails(
      admin1.firestore().collection('audit_logs').doc(logId).update({ actionType: 'tampered' }),
    );
    await assertFails(
      admin1.firestore().collection('audit_logs').doc(logId).delete(),
    );
  });
});

describe('Gate 0: location privacy (worker_locations)', () => {
  it('VULNERABILITY: an unrelated signed-in user cannot read an online worker\'s location', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('worker_locations').doc('worker1').set({
        status: 'online', geohash: 'abc123',
      });
    });
    const stranger = testEnv.authenticatedContext('stranger');
    await assertFails(
      stranger.firestore().collection('worker_locations').doc('worker1').get(),
    );
  });

  it('a worker can read their own location', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('worker_locations').doc('worker1').set({ status: 'online' });
    });
    const worker1 = testEnv.authenticatedContext('worker1');
    await assertSucceeds(
      worker1.firestore().collection('worker_locations').doc('worker1').get(),
    );
  });

  it('the customer of the worker\'s ACTIVE booking can read that worker\'s location', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('bookings').doc('booking1').set({
        customerId: 'alice', workerId: 'worker1', status: 'confirmed',
      });
      await ctx.firestore().collection('worker_locations').doc('worker1').set({
        status: 'online', currentBookingId: 'booking1',
      });
    });
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      alice.firestore().collection('worker_locations').doc('worker1').get(),
    );
  });

  it('a DIFFERENT customer (not on that booking) still cannot read the location', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('bookings').doc('booking1').set({
        customerId: 'alice', workerId: 'worker1', status: 'confirmed',
      });
      await ctx.firestore().collection('worker_locations').doc('worker1').set({
        status: 'online', currentBookingId: 'booking1',
      });
    });
    const mallory = testEnv.authenticatedContext('mallory');
    await assertFails(
      mallory.firestore().collection('worker_locations').doc('worker1').get(),
    );
  });
});

describe('Gate 0: worker_public_profiles (location/PII privacy split)', () => {
  it('any authenticated user can read a worker\'s public profile', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('worker_public_profiles').doc('worker1').set({
        fullName: 'Worker One', rating: 4.5,
      });
    });
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      alice.firestore().collection('worker_public_profiles').doc('worker1').get(),
    );
  });

  it('VULNERABILITY: a client (even the worker themselves) cannot write worker_public_profiles directly', async () => {
    const worker1 = testEnv.authenticatedContext('worker1');
    await assertFails(
      worker1.firestore().collection('worker_public_profiles').doc('worker1')
        .set({ fullName: 'Fake Name', rating: 5.0 }),
    );
  });

  it('the full workers/{id} document (with NIC etc.) remains denied to a customer', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('workers').doc('worker1').set({
        nic: '123456789V', fullName: 'Worker One',
      });
    });
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      alice.firestore().collection('workers').doc('worker1').get(),
    );
  });
});

describe('Gate 0: bookings — single source of truth & legal transitions', () => {
  it('VULNERABILITY: a customer cannot create a booking that is already "confirmed"', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      alice.firestore().collection('bookings').doc('b1').set({
        customerId: 'alice', status: 'confirmed', workerId: 'worker1',
      }),
    );
  });

  it('VULNERABILITY: a customer cannot create a booking that pre-assigns a worker', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertFails(
      alice.firestore().collection('bookings').doc('b1').set({
        customerId: 'alice', status: 'pending', workerId: 'worker1',
      }),
    );
  });

  it('a customer CAN create a plain pending booking with no worker', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      alice.firestore().collection('bookings').doc('b1').set({
        customerId: 'alice', status: 'pending', workerId: null,
      }),
    );
  });

  it('VULNERABILITY: a worker cannot jump straight from "confirmed" to "completed"', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('bookings').doc('b1').set({
        customerId: 'alice', workerId: 'worker1', status: 'confirmed',
      });
    });
    const worker1 = testEnv.authenticatedContext('worker1');
    await assertFails(
      worker1.firestore().collection('bookings').doc('b1')
        .update({ status: 'completed', updatedAt: new Date() }),
    );
  });

  it('a worker CAN move through the legal chain one step at a time', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('bookings').doc('b1').set({
        customerId: 'alice', workerId: 'worker1', status: 'confirmed',
      });
    });
    const worker1 = testEnv.authenticatedContext('worker1');
    const ref = worker1.firestore().collection('bookings').doc('b1');
    await assertSucceeds(ref.update({ status: 'workerAssigned', updatedAt: new Date() }));
    await assertSucceeds(ref.update({ status: 'workerEnRoute', updatedAt: new Date() }));
    await assertSucceeds(ref.update({ status: 'workerArrived', updatedAt: new Date(),
      arrivedAt: new Date() }));
    await assertSucceeds(ref.update({ status: 'inProgress', updatedAt: new Date(),
      checkIn: { latitude: 6.9, longitude: 79.85, timestamp: new Date() } }));
    await assertSucceeds(ref.update({ status: 'completed', updatedAt: new Date(),
      completedAt: new Date(),
      checkOut: { latitude: 6.9, longitude: 79.85, timestamp: new Date() } }));
  });

  it('a worker not assigned to the booking cannot update it at all', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('bookings').doc('b1').set({
        customerId: 'alice', workerId: 'worker1', status: 'confirmed',
      });
    });
    const worker2 = testEnv.authenticatedContext('worker2');
    await assertFails(
      worker2.firestore().collection('bookings').doc('b1')
        .update({ status: 'workerAssigned', updatedAt: new Date() }),
    );
  });
});

describe('Gate 0: authenticated worker acceptance (job_offers)', () => {
  it('VULNERABILITY: a worker cannot directly set their own offer to "accepted" (must go through acceptJob)', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('job_offers').doc('job1_worker1').set({
        jobId: 'job1', workerId: 'worker1', status: 'pending',
      });
    });
    const worker1 = testEnv.authenticatedContext('worker1');
    await assertFails(
      worker1.firestore().collection('job_offers').doc('job1_worker1')
        .update({ status: 'accepted' }),
    );
  });

  it('a worker can still directly decline their own offer', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('job_offers').doc('job1_worker1').set({
        jobId: 'job1', workerId: 'worker1', status: 'pending',
      });
    });
    const worker1 = testEnv.authenticatedContext('worker1');
    await assertSucceeds(
      worker1.firestore().collection('job_offers').doc('job1_worker1')
        .update({ status: 'rejected' }),
    );
  });

  it('a worker cannot read or modify an offer made to someone else', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('job_offers').doc('job1_worker1').set({
        jobId: 'job1', workerId: 'worker1', status: 'pending',
      });
    });
    const worker2 = testEnv.authenticatedContext('worker2');
    await assertFails(
      worker2.firestore().collection('job_offers').doc('job1_worker1').get(),
    );
  });
});

describe('sanity: normal customer/worker read/write of their own bookings still works', () => {
  it('customer can read their own booking; unrelated user cannot', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('bookings').doc('b1').set({
        customerId: 'alice', status: 'pending', workerId: null,
      });
    });
    const alice = testEnv.authenticatedContext('alice');
    const mallory = testEnv.authenticatedContext('mallory');
    await assertSucceeds(alice.firestore().collection('bookings').doc('b1').get());
    await assertFails(mallory.firestore().collection('bookings').doc('b1').get());
  });

  it('customer can cancel their own pending booking', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('bookings').doc('b1').set({
        customerId: 'alice', status: 'pending', workerId: null,
      });
    });
    const alice = testEnv.authenticatedContext('alice');
    await assertSucceeds(
      alice.firestore().collection('bookings').doc('b1').update({
        status: 'cancelled', cancellationReason: 'changed my mind', cancelledAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });
});

// Sanity check that these tests actually exercise something (chai imported and used).
describe('meta', () => {
  it('rules files were readable and non-empty', () => {
    const rules = fs.readFileSync(path.resolve(process.cwd(), '../firestore.rules'), 'utf8');
    expect(rules.length).to.be.greaterThan(100);
  });
});
