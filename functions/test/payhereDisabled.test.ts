import { expect } from 'chai';

/**
 * Gate 0: PayHere is disabled server-side for this MVP release
 * (functions/src/payhereWebhook.ts PAYMENTS_ENABLED flag). This is the
 * authoritative enforcement point — the client-side "not available" screens
 * (test/features/payment/presentation/**\/*_test.dart, on the Flutter side)
 * are a UX nicety, not the real boundary, since a client could in principle
 * call the Cloud Function directly regardless of what the app UI shows.
 */

process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'demo-gate0-tests';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const functionsTest = require('firebase-functions-test')();
// eslint-disable-next-line @typescript-eslint/no-var-requires
const myFunctions = require('../lib/index');

const generatePayHereUrl = functionsTest.wrap(myFunctions.generatePayHereUrl);
const checkPaymentStatus = functionsTest.wrap(myFunctions.checkPaymentStatus);

describe('PayHere disabled for MVP (Gate 0)', function () {
  this.timeout(20000);

  after(() => {
    functionsTest.cleanup();
  });

  it('generatePayHereUrl rejects even a fully-authenticated, well-formed request', async () => {
    let threw = false;
    let code: string | undefined;
    try {
      await generatePayHereUrl(
        {
          type: 'booking',
          bookingId: 'booking1',
          amount: 1500,
          customerName: 'Test Customer',
          customerPhone: '+94771234567',
        },
        { auth: { uid: 'customer1' } },
      );
    } catch (e: any) {
      threw = true;
      code = e.code;
    }
    expect(threw).to.equal(true);
    expect(code).to.equal('failed-precondition');
  });

  it('checkPaymentStatus rejects even a fully-authenticated request', async () => {
    let threw = false;
    let code: string | undefined;
    try {
      await checkPaymentStatus({ paymentId: 'payment1' }, { auth: { uid: 'customer1' } });
    } catch (e: any) {
      threw = true;
      code = e.code;
    }
    expect(threw).to.equal(true);
    expect(code).to.equal('failed-precondition');
  });
});
