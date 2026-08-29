import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';

const db = admin.firestore();

/**
 * PayHere Webhook Handler
 * Receives payment notifications from PayHere server
 * URL: https://us-central1-helaservice-prod.cloudfunctions.net/payhereNotify
 */
export const payhereNotify = functions.https.onRequest(async (req, res) => {
    // Only accept POST requests
    if (req.method !== 'POST') {
        res.status(405).send('Method Not Allowed');
        return;
    }

    try {
        const {
            merchant_id,
            order_id,
            payment_id,
            payhere_amount,
            payhere_currency,
            status_code,
            md5sig,
            method,
            card_holder_name,
            card_no,
            card_expiry,
            recurring,
            message,
            custom_1, // bookingId
            custom_2, // customerId
        } = req.body;

        console.log('🔔 PayHere notification received:', {
            order_id,
            payment_id,
            status_code,
            amount: payhere_amount,
        });

        // Get merchant secret from config
        const merchantSecret = functions.config().payhere?.secret || '';
        
        if (!merchantSecret) {
            console.error('❌ Merchant secret not configured');
            res.status(500).send('Configuration error');
            return;
        }

        // Verify MD5 signature (security check)
        const localSig = generateMD5Signature(
            merchant_id,
            order_id,
            payhere_amount,
            payhere_currency,
            status_code,
            merchantSecret
        );

        if (localSig.toUpperCase() !== md5sig.toUpperCase()) {
            console.error('❌ Invalid MD5 signature');
            res.status(403).send('Invalid signature');
            return;
        }

        // Map PayHere status codes
        // 2 = success, 0 = pending, -1 = canceled, -2 = failed
        let paymentStatus: string;
        let bookingStatus: string;
        
        switch (status_code) {
            case '2':
                paymentStatus = 'completed';
                bookingStatus = 'paid';
                break;
            case '0':
                paymentStatus = 'pending';
                bookingStatus = 'payment_pending';
                break;
            case '-1':
                paymentStatus = 'cancelled';
                bookingStatus = 'payment_failed';
                break;
            case '-2':
                paymentStatus = 'failed';
                bookingStatus = 'payment_failed';
                break;
            default:
                paymentStatus = 'unknown';
                bookingStatus = 'payment_failed';
        }

        const bookingId = custom_1 || order_id;
        const customerId = custom_2;

        // ── Wallet top-up shortcut ────────────────────────────────────────
        // order_id convention: 'topup_{userId}_{timestamp}'
        if (order_id.startsWith('topup_') && status_code === '2') {
            const topupUserId = customerId || order_id.split('_')[1];
            const topupAmount = parseFloat(payhere_amount); // LKR, as PayHere reports it
            if (topupUserId && topupAmount > 0) {
                // wallets.balance/totalCredited and transactions.amount/balanceAfter
                // are stored in integer cents.
                const topupAmountCents = Math.round(topupAmount * 100);
                await db.runTransaction(async (tx) => {
                    const walletRef = db.collection('wallets').doc(topupUserId);
                    const walletSnap = await tx.get(walletRef);
                    const wallet = walletSnap.data() ?? {};
                    const newBalance = (wallet.balance as number ?? 0) + topupAmountCents;
                    tx.set(walletRef, {
                        userId: topupUserId,
                        balance: newBalance,
                        totalCredited: (wallet.totalCredited as number ?? 0) + topupAmountCents,
                        isActive: true,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    }, { merge: true });
                    const txRef = db.collection('transactions').doc();
                    tx.set(txRef, {
                        id: txRef.id,
                        userId: topupUserId,
                        type: 'topUp',
                        amount: topupAmountCents,
                        balanceAfter: newBalance,
                        paymentMethod: 'payhere',
                        description: `PayHere wallet top-up`,
                        relatedBookingId: null,
                        status: 'completed',
                        payherePaymentId: payment_id,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                });
                console.log(`✅ Wallet top-up: LKR ${topupAmount} for user ${topupUserId}`);
                res.status(200).send('OK');
                return;
            }
        }

        // Create payment record
        const paymentData = {
            paymentId: payment_id,
            orderId: order_id,
            bookingId: bookingId,
            customerId: customerId,
            amount: parseFloat(payhere_amount),
            currency: payhere_currency,
            status: paymentStatus,
            method: method || 'unknown',
            cardHolderName: card_holder_name || null,
            cardLast4: card_no ? maskCardNumber(card_no) : null,
            cardExpiry: card_expiry || null,
            isRecurring: recurring === '1',
            payhereMessage: message || null,
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            rawResponse: req.body, // Keep full response for debugging
        };

        // Use transaction to ensure atomicity
        await db.runTransaction(async (transaction) => {
            // Save payment record
            const paymentRef = db.collection('payments').doc(payment_id);
            transaction.set(paymentRef, paymentData, { merge: true });

            // Update booking
            const bookingRef = db.collection('bookings').doc(bookingId);
            const bookingUpdate: any = {
                paymentId: payment_id,
                paymentStatus: bookingStatus,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            };

            if (status_code === '2') {
                bookingUpdate.paidAt = admin.firestore.FieldValue.serverTimestamp();
                bookingUpdate.paidAmount = parseFloat(payhere_amount);
            }

            transaction.update(bookingRef, bookingUpdate);

            // If payment successful, update job request status too
            if (status_code === '2') {
                const jobQuery = await db.collection('job_requests')
                    .where('bookingId', '==', bookingId)
                    .limit(1)
                    .get();
                
                if (!jobQuery.empty) {
                    transaction.update(jobQuery.docs[0].ref, {
                        paymentStatus: 'completed',
                        paymentId: payment_id,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                }
            }
        });

        // Send notification to customer
        if (customerId) {
            await sendPaymentNotification(
                customerId,
                bookingId,
                status_code === '2',
                parseFloat(payhere_amount)
            );
        }

        console.log('✅ Payment processed:', { payment_id, status: paymentStatus });
        res.status(200).send('OK');

    } catch (error) {
        console.error('❌ PayHere webhook error:', error);
        res.status(500).send('Internal Server Error');
    }
});

/**
 * Generate MD5 signature for PayHere verification
 * Format: merchant_id + order_id + amount + currency + status_code + md5(merchant_secret)
 */
function generateMD5Signature(
    merchantId: string,
    orderId: string,
    amount: string,
    currency: string,
    statusCode: string,
    merchantSecret: string
): string {
    const secretHash = crypto
        .createHash('md5')
        .update(merchantSecret)
        .digest('hex')
        .toUpperCase();
    
    const signatureString = `${merchantId}${orderId}${amount}${currency}${statusCode}${secretHash}`;
    
    return crypto
        .createHash('md5')
        .update(signatureString)
        .digest('hex')
        .toUpperCase();
}

/**
 * Mask card number, showing only last 4 digits
 */
function maskCardNumber(cardNo: string): string {
    const cleaned = cardNo.replace(/\s/g, '');
    if (cleaned.length < 4) return cleaned;
    return '****' + cleaned.slice(-4);
}

/**
 * Send payment notification to customer
 */
async function sendPaymentNotification(
    customerId: string,
    bookingId: string,
    success: boolean,
    amount: number
) {
    try {
        const notificationData = {
            userId: customerId,
            type: success ? 'payment_success' : 'payment_failed',
            title: success ? 'Payment Successful' : 'Payment Failed',
            body: success
                ? `Your payment of LKR ${amount.toFixed(2)} was successful`
                : 'Your payment could not be processed. Please try again.',
            bookingId: bookingId,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            read: false,
        };

        await db.collection('notifications').add(notificationData);
    } catch (error) {
        console.error('Failed to send notification:', error);
    }
}

/**
 * Manual payment status check (for polling fallback)
 */
export const checkPaymentStatus = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Login required');
    }

    const { orderId } = data;
    
    try {
        const paymentQuery = await db.collection('payments')
            .where('orderId', '==', orderId)
            .orderBy('createdAt', 'desc')
            .limit(1)
            .get();

        if (paymentQuery.empty) {
            return { status: 'not_found', message: 'Payment not found' };
        }

        const payment = paymentQuery.docs[0].data();
        return {
            status: payment.status,
            paymentId: payment.paymentId,
            amount: payment.amount,
            processedAt: payment.processedAt?.toMillis(),
        };
    } catch (error) {
        console.error('Check payment status error:', error);
        throw new functions.https.HttpsError('internal', 'Failed to check status');
    }
});

// ─── generatePayHereUrl ──────────────────────────────────────────────────────
// Callable: signs the payment hash server-side so the merchant secret never
// reaches the client. Works for both booking payments and wallet top-ups.
//
// Input:  { type: 'booking'|'topup', bookingId?, userId?, amount, customerName,
//           customerPhone, customerEmail? }
// Output: { url: string, orderId: string }

export const generatePayHereUrl = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Login required');
    }

    const {
        type = 'booking',
        bookingId,
        amount,       // in LKR (not cents)
        customerName,
        customerPhone,
        customerEmail,
    } = data as {
        type?: 'booking' | 'topup';
        bookingId?: string;
        amount: number;
        customerName: string;
        customerPhone: string;
        customerEmail?: string;
    };

    if (!amount || amount <= 0) {
        throw new functions.https.HttpsError('invalid-argument', 'amount must be > 0');
    }

    const merchantId: string = functions.config().payhere?.merchant_id || '';
    const merchantSecret: string = functions.config().payhere?.secret || '';
    const sandbox: boolean = functions.config().payhere?.sandbox === 'true';

    if (!merchantId || !merchantSecret) {
        throw new functions.https.HttpsError('failed-precondition', 'PayHere not configured');
    }

    // Build order ID
    const ts = Date.now();
    const orderId = type === 'topup'
        ? `topup_${context.auth.uid}_${ts}`
        : (bookingId ?? `booking_${ts}`);

    // Format amount to 2 decimal places (PayHere requires this exact format)
    const amountStr = amount.toFixed(2);
    const currency  = 'LKR';

    // PayHere hash for PAYMENT initiation:
    // MD5( merchantId + orderId + amount + currency + MD5(merchantSecret).toUpperCase() )
    const secretHash = crypto
        .createHash('md5')
        .update(merchantSecret)
        .digest('hex')
        .toUpperCase();

    const hash = crypto
        .createHash('md5')
        .update(`${merchantId}${orderId}${amountStr}${currency}${secretHash}`)
        .digest('hex')
        .toUpperCase();

    const baseUrl = sandbox
        ? 'https://sandbox.payhere.lk/pay/checkout'
        : 'https://www.payhere.lk/pay/checkout';

    const notifyUrl =
        `https://us-central1-helaservice-prod.cloudfunctions.net/payhereNotify`;
    const returnUrl  = 'helaservice://payment/success';
    const cancelUrl  = 'helaservice://payment/cancel';

    const nameParts = customerName.trim().split(' ');
    const firstName = nameParts[0] ?? 'Customer';
    const lastName  = nameParts.slice(1).join(' ') || 'User';

    const params = new URLSearchParams({
        merchant_id: merchantId,
        return_url:  returnUrl,
        cancel_url:  cancelUrl,
        notify_url:  notifyUrl,
        order_id:    orderId,
        items:       type === 'topup' ? 'Wallet Top-up' : `Booking ${bookingId ?? orderId}`,
        currency,
        amount:      amountStr,
        first_name:  firstName,
        last_name:   lastName,
        email:       customerEmail ?? `${context.auth.uid}@helaservice.lk`,
        phone:       customerPhone,
        address:     'Colombo',
        city:        'Colombo',
        country:     'Sri Lanka',
        hash,
        custom_1:    type === 'topup' ? `topup_${context.auth.uid}` : (bookingId ?? orderId),
        custom_2:    context.auth.uid,
    });

    return {
        url:     `${baseUrl}?${params.toString()}`,
        orderId,
    };
});
