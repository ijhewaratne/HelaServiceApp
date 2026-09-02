import { expect } from 'chai';

/**
 * One-off comparative evidence for the handover (not part of the permanent
 * suite): demonstrates the ORIGINAL backup.ts/health.ts admin-check logic
 * accepts a client-forgeable Firestore field, then demonstrates the FIXED
 * assertIsAdmin() helper rejects the same forged actor. Run against a live
 * Firestore emulator (needs FIRESTORE_EMULATOR_HOST set).
 */
process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'demo-gate0-tests';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const admin = require('firebase-admin');
if (admin.apps.length === 0) admin.initializeApp();
const db = admin.firestore();

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { assertIsAdmin } = require('../lib/authUtils');

describe('BEFORE/AFTER comparative evidence: role escalation via users/{uid}.role', () => {
  const attackerUid = 'attacker-forged-role';

  before(async () => {
    // Simulates exactly what the ORIGINAL firestore.rules allowed: any
    // authenticated user could write ANY field, including `role`, to their
    // own users/{uid} document.
    await db.collection('users').doc(attackerUid).set({ role: 'admin' });
  });

  it('ORIGINAL logic (verbatim from backup.ts/health.ts pre-Gate-0): a forged role field IS accepted', async () => {
    const userDoc = await db.collection('users').doc(attackerUid).get();
    const userData = userDoc.data();

    // This is the exact original condition, copied verbatim from
    // functions/src/backup.ts (git show 24e87a9:functions/src/backup.ts).
    const wouldBeRejected = !userData || userData.role !== 'admin';

    expect(wouldBeRejected).to.equal(
      false,
      'VULNERABILITY CONFIRMED: the original check does not reject an attacker '
      + 'who simply wrote role:"admin" on their own user document — '
      + 'manualBackup/restoreFromBackup/getSystemHealth would have proceeded.',
    );
  });

  it('FIXED logic (assertIsAdmin): the same forged actor IS rejected', () => {
    // The attacker has no real custom claim — only the forged Firestore field.
    const context = {
      auth: { uid: attackerUid, token: { admin: false } },
    } as any;

    let threw = false;
    let code: string | undefined;
    try {
      assertIsAdmin(context);
    } catch (e: any) {
      threw = true;
      code = e.code;
    }

    expect(threw).to.equal(true, 'FIX CONFIRMED: assertIsAdmin correctly rejects the forged actor');
    expect(code).to.equal('permission-denied');
  });
});
