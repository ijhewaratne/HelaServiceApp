import { expect } from 'chai';
// Imports the COMPILED output (functions/lib/, built by `npm run build`,
// which `pretest` always runs first) rather than ../src, since this test
// file itself is compiled to functions/test-dist/ and cannot require a
// sibling .ts source file directly.
import { assertIsAdmin } from '../lib/authUtils';
import * as functions from 'firebase-functions';

/**
 * Gate 0 fix (role escalation): manualBackup/restoreFromBackup/getSystemHealth
 * used to check a client-writable Firestore field (`users/{uid}.role`)
 * instead of a Firebase Auth custom claim — see the comment in
 * src/authUtils.ts for the full vulnerability writeup. These are plain unit
 * tests (no emulator needed) proving the replacement helper only trusts
 * `context.auth.token`, which a client cannot forge.
 */
describe('assertIsAdmin (Gate 0: role escalation fix)', () => {
  it('throws unauthenticated when there is no auth context at all', () => {
    expect(() => assertIsAdmin({ auth: null } as unknown as functions.https.CallableContext))
      .to.throw().with.property('code', 'unauthenticated');
  });

  it('VULNERABILITY: throws permission-denied for a signed-in user with no admin claim, '
    + 'even if they have other (forgeable) properties set', () => {
    const context = {
      auth: { uid: 'attacker', token: { admin: false, role: 'admin' } },
    } as unknown as functions.https.CallableContext;
    expect(() => assertIsAdmin(context)).to.throw().with.property('code', 'permission-denied');
  });

  it('succeeds for a user whose ID token carries the admin custom claim, and returns their uid', () => {
    const context = {
      auth: { uid: 'real-admin', token: { admin: true } },
    } as unknown as functions.https.CallableContext;
    expect(assertIsAdmin(context)).to.equal('real-admin');
  });

  it('succeeds for a user whose ID token carries the superAdmin custom claim, and returns their uid', () => {
    const context = {
      auth: { uid: 'real-super-admin', token: { superAdmin: true } },
    } as unknown as functions.https.CallableContext;
    expect(assertIsAdmin(context)).to.equal('real-super-admin');
  });
});
