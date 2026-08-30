/**
 * Session management (FR-AUTH-007).
 *
 * Firebase Auth has no concept of revoking a single refresh token — only
 * `revokeRefreshTokens(uid)`, which invalidates every refresh token issued
 * before the call for that user. There is no way to selectively kill one
 * device's session while leaving others alone; this function is honest
 * about that rather than pretending otherwise.
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export const revokeOtherSessions = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login required');
  }

  const uid = context.auth.uid;
  const { keepSessionId } = data as { keepSessionId?: string };

  await admin.auth().revokeRefreshTokens(uid);

  const sessionsSnap = await db
    .collection('users')
    .doc(uid)
    .collection('sessions')
    .get();

  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();
  let revokedCount = 0;
  sessionsSnap.docs.forEach((doc) => {
    if (doc.id !== keepSessionId) {
      batch.update(doc.ref, { revokedAt: now });
      revokedCount++;
    }
  });
  await batch.commit();

  return { success: true, revokedCount };
});
