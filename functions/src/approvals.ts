/**
 * Two-person approval for high-risk admin changes.
 *
 * The Dart client (and Firestore rules) only ever move a pending_approvals
 * document to status 'approved' or 'rejected' — they never apply the
 * underlying change directly. This trigger is the only thing that actually
 * deactivates a category or grants a permission scope, and it runs with the
 * Admin SDK, so it isn't constrained by the deciding admin's own Firestore
 * permissions (e.g. a categoryManagement-scoped admin can approve a
 * category change without also needing superAdmin's admin_permissions
 * write access).
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export const applyApprovedChange = functions.firestore
  .document('pending_approvals/{approvalId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === after.status || after.status !== 'approved') {
      return null;
    }

    const payload = (after.payload ?? {}) as Record<string, unknown>;
    const approvalId = context.params.approvalId;

    try {
      switch (after.type) {
        case 'categoryDeactivation': {
          const categoryId = payload.categoryId as string;
          if (!categoryId) {
            throw new Error('categoryDeactivation payload missing categoryId');
          }
          await db.collection('service_catalog').doc(categoryId).update({
            isActive: false,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          break;
        }
        case 'permissionGrant': {
          const adminUid = payload.adminUid as string;
          const scopes = payload.scopes as string[];
          if (!adminUid || !Array.isArray(scopes)) {
            throw new Error('permissionGrant payload missing adminUid/scopes');
          }
          await db.collection('admin_permissions').doc(adminUid).set({
            scopes,
            grantedBy: after.decidedBy,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          break;
        }
        default:
          throw new Error(`Unknown approval type: ${after.type}`);
      }

      await change.after.ref.update({
        appliedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (err) {
      console.error(`Failed to apply approval ${approvalId}:`, err);
      await change.after.ref.update({
        applyError: err instanceof Error ? err.message : String(err),
      });
    }

    return null;
  });
