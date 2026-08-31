import * as functions from 'firebase-functions';

/**
 * Gate 0 fix (role escalation, CRITICAL): manualBackup, restoreFromBackup,
 * and getSystemHealth used to check `(await db.collection('users').doc(uid).get()).data().role === 'admin'`
 * — a plain Firestore document field that `firestore.rules` allowed any
 * signed-in user to write on their own `users/{uid}` document. Any
 * authenticated user could therefore set `role: 'admin'` on themselves and
 * then successfully call those admin-only functions, including
 * restoreFromBackup, which can overwrite production Firestore data.
 *
 * The only trustworthy source of admin status is the Firebase Auth ID
 * token's custom claims (`admin` / `superAdmin`), set out-of-band by an
 * Admin SDK script or Cloud Function a client cannot invoke on itself —
 * exactly the mechanism firestore.rules' own `isAdmin()` helper already
 * relies on. Every callable in this codebase that needs an admin check
 * should call this helper instead of reading a Firestore field.
 */
/**
 * Returns the verified admin's uid (rather than just void) so call sites get
 * a definitely-defined uid without needing TypeScript to narrow
 * `context.auth` themselves — `context.auth` stays optional on the callable
 * context type regardless of what this function does internally.
 */
export function assertIsAdmin(context: functions.https.CallableContext): string {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }
  const token = context.auth.token as Record<string, unknown>;
  if (token.admin !== true && token.superAdmin !== true) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }
  return context.auth.uid;
}
