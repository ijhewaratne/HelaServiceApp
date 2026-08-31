import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/payment_bloc.dart';
import '../../domain/entities/payment_result.dart';

/// Payment page for processing PayHere payments
class PaymentPage extends StatelessWidget {
  final String bookingId;
  final int amount; // Amount in cents (e.g., 150000 = LKR 1,500.00)
  final String? description;

  const PaymentPage({
    Key? key,
    required this.bookingId,
    required this.amount,
    this.description,
  }) : super(key: key);

  // Gate 0: in-app payments (PayHere) are disabled for this MVP release —
  // see functions/src/payhereWebhook.ts's PAYMENTS_ENABLED flag, which is
  // the authoritative, server-side enforcement of this. This screen-level
  // short-circuit exists so a user sees a clear, honest message instead of
  // a raw Cloud Function error after tapping "Pay".
  static const bool _paymentsEnabled = false;

  @override
  Widget build(BuildContext context) {
    if (!_paymentsEnabled) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.payments_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Payments are not available in this release.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'Please arrange payment directly with your service provider for now.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentInitiated) {
            _launchCheckout(context, state.checkoutUrl);
          } else if (state is PaymentSuccess) {
            _showSuccessDialog(context, state.payment);
          } else if (state is PaymentFailed) {
            _showErrorDialog(context, state.message);
          } else if (state is PaymentError) {
            _showErrorDialog(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is PaymentProcessing || state is PaymentLoading) {
            return const _ProcessingView();
          }

          if (state is PaymentInitiated) {
            return _AwaitingWebhookView(orderId: state.orderId);
          }

          if (state is PaymentSuccess) {
            return _SuccessView(payment: state.payment);
          }

          if (state is PaymentFailed) {
            return _FailedView(
              message: state.message,
              onRetry: () => _initiatePayment(context),
            );
          }

          // Initial state - show payment summary
          return _PaymentSummaryView(
            amount: amount,
            description: description,
            onPay: () => _initiatePayment(context),
          );
        },
      ),
    );
  }

  Future<void> _launchCheckout(BuildContext context, String checkoutUrl) async {
    final uri = Uri.tryParse(checkoutUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open PayHere checkout.')),
        );
      }
    }
  }

  void _initiatePayment(BuildContext context) {
    context.read<PaymentBloc>().add(
      ProcessPayment(
        bookingId: bookingId,
        amount: amount,
        description: description ?? 'HelaService Booking',
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, PaymentResult payment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: const Text('Payment Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Payment ID: ${payment.paymentId}'),
            const SizedBox(height: 8),
            Text(
              'Amount: LKR ${payment.amount?.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.pop(); // Close dialog
              context.pop(true); // Return to previous screen with success
            },
            child: const Text('DONE'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 64),
        title: const Text('Payment Failed'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('OK')),
        ],
      ),
    );
  }
}

class _PaymentSummaryView extends StatelessWidget {
  final int amount;
  final String? description;
  final VoidCallback onPay;

  const _PaymentSummaryView({
    required this.amount,
    required this.description,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final amountInRupees = amount / 100.0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Amount to Pay',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'LKR ${amountInRupees.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      description!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Spacer(),
          const _PaymentMethodsInfo(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onPay,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'PAY NOW',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Secured by PayHere',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodsInfo extends StatelessWidget {
  const _PaymentMethodsInfo();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Methods',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: const [
                _PaymentMethodChip(
                  icon: Icons.credit_card,
                  label: 'Visa/Master',
                ),
                _PaymentMethodChip(icon: Icons.account_balance, label: 'Bank'),
                _PaymentMethodChip(icon: Icons.phone_android, label: 'eZCash'),
                _PaymentMethodChip(icon: Icons.phone_iphone, label: 'mCash'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PaymentMethodChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey[100],
    );
  }
}

class _ProcessingView extends StatelessWidget {
  const _ProcessingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text('Processing payment...'),
          SizedBox(height: 8),
          Text(
            'Please complete the payment in the PayHere window',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Shown after the PayHere URL has been launched. Guides the user to complete
/// payment in the browser and return here; the webhook will update Firestore.
class _AwaitingWebhookView extends StatelessWidget {
  final String orderId;
  const _AwaitingWebhookView({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.open_in_browser, size: 72, color: Colors.indigo),
          const SizedBox(height: 24),
          Text(
            'Complete your payment',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'The PayHere checkout has been opened in your browser. '
            'Complete the payment there and return to this screen.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Order ID: $orderId',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            'Waiting for payment confirmation…',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final PaymentResult payment;

  const _SuccessView({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 24),
          const Text(
            'Payment Successful!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text('Payment ID: ${payment.paymentId}'),
          Text('LKR ${payment.amount?.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}

class _FailedView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FailedView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 80),
            const SizedBox(height: 24),
            const Text(
              'Payment Failed',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: onRetry, child: const Text('TRY AGAIN')),
          ],
        ),
      ),
    );
  }
}
