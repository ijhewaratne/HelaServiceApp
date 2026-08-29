/**
 * One-time data migration: convert the wallet ledger from LKR doubles to
 * integer cents, and drop the separately-tracked `availableBalance` field
 * (it is now always derived client- and server-side as balance - heldBalance).
 *
 * This is NOT wired into `npm run deploy` and is NOT a Cloud Function — it is
 * a standalone admin script you run once, by hand, against a specific
 * Firestore project, after reading this whole file.
 *
 * ── BEFORE YOU RUN THIS ──────────────────────────────────────────────────
 *
 * 1. Deploy the updated Cloud Functions FIRST (this repo's walletFunctions.ts,
 *    payhereWebhook.ts, operationalFunctions.ts, referral.ts) — or, better,
 *    put the app into maintenance mode / disable wallet-writing paths —
 *    before running this script. If old (LKR-writing) and new (cents-writing)
 *    code are both live against the same documents at the same time, this
 *    migration will race with them and corrupt data.
 * 2. Export a backup of the `wallets`, `wallet_transactions`, and
 *    `transactions` collections first (e.g. `gcloud firestore export`).
 *    This migration is destructive: it overwrites balance/heldBalance/
 *    totalCredited/totalDebited/amount/balanceAfter in place. There is no
 *    built-in undo.
 * 3. Run with no arguments first (dry run). It only reads and logs — it does
 *    not write anything unless you pass --execute.
 * 4. Re-run with --execute only after reviewing the dry-run output and
 *    confirming the numbers look right for a sample of real documents.
 *
 * ── USAGE ────────────────────────────────────────────────────────────────
 *
 *   cd functions
 *   npm install
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
 *     node scripts/migrateWalletsToCents.js                # dry run
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
 *     node scripts/migrateWalletsToCents.js --execute       # actually writes
 *
 * A document already storing an integer value that looks like it's already
 * in cents (heuristically: an existing `balance` that's an integer AND the
 * document has no fractional-cent evidence) cannot be reliably distinguished
 * from a small LKR balance — this script assumes ALL documents are still in
 * the pre-migration LKR-double format. Do not run it twice.
 */

const admin = require('firebase-admin');

const DRY_RUN = !process.argv.includes('--execute');

admin.initializeApp();
const db = admin.firestore();

function toCents(value) {
  if (value === undefined || value === null) return undefined;
  return Math.round(Number(value) * 100);
}

async function migrateWallets() {
  const snap = await db.collection('wallets').get();
  console.log(`\nwallets: ${snap.size} documents found`);

  let batch = db.batch();
  let opsInBatch = 0;
  let updated = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const update = {};

    if (typeof data.balance === 'number') update.balance = toCents(data.balance);
    if (typeof data.heldBalance === 'number') update.heldBalance = toCents(data.heldBalance);
    if (typeof data.totalCredited === 'number') update.totalCredited = toCents(data.totalCredited);
    if (typeof data.totalDebited === 'number') update.totalDebited = toCents(data.totalDebited);
    if ('availableBalance' in data) update.availableBalance = admin.firestore.FieldValue.delete();

    if (Object.keys(update).length === 0) continue;

    console.log(
      `  ${doc.id}: balance ${data.balance} -> ${update.balance}, ` +
      `heldBalance ${data.heldBalance} -> ${update.heldBalance}, ` +
      `totalCredited ${data.totalCredited} -> ${update.totalCredited}, ` +
      `totalDebited ${data.totalDebited} -> ${update.totalDebited}` +
      ('availableBalance' in data ? ' [dropping availableBalance]' : '')
    );

    if (!DRY_RUN) {
      batch.update(doc.ref, update);
      opsInBatch++;
      if (opsInBatch >= 400) {
        await batch.commit();
        batch = db.batch();
        opsInBatch = 0;
      }
    }
    updated++;
  }

  if (!DRY_RUN && opsInBatch > 0) {
    await batch.commit();
  }

  console.log(`wallets: ${updated} documents ${DRY_RUN ? 'would be' : 'were'} updated`);
}

async function migrateTransactionCollection(collectionName) {
  const snap = await db.collection(collectionName).get();
  console.log(`\n${collectionName}: ${snap.size} documents found`);

  let batch = db.batch();
  let opsInBatch = 0;
  let updated = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const update = {};

    if (typeof data.amount === 'number') update.amount = toCents(data.amount);
    if (typeof data.balanceAfter === 'number') update.balanceAfter = toCents(data.balanceAfter);

    if (Object.keys(update).length === 0) continue;

    if (!DRY_RUN) {
      batch.update(doc.ref, update);
      opsInBatch++;
      if (opsInBatch >= 400) {
        await batch.commit();
        batch = db.batch();
        opsInBatch = 0;
      }
    }
    updated++;
  }

  if (!DRY_RUN && opsInBatch > 0) {
    await batch.commit();
  }

  console.log(`${collectionName}: ${updated} documents ${DRY_RUN ? 'would be' : 'were'} updated`);
}

async function main() {
  console.log(DRY_RUN
    ? '=== DRY RUN — no writes will be made. Pass --execute to actually migrate. ==='
    : '=== EXECUTE MODE — this will write to Firestore. ===');

  await migrateWallets();
  await migrateTransactionCollection('wallet_transactions');
  await migrateTransactionCollection('transactions');

  console.log('\nDone.' + (DRY_RUN ? ' Re-run with --execute to apply these changes.' : ''));
}

main().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
