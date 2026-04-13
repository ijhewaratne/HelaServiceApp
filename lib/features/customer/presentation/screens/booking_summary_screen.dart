import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../viewmodels/booking_viewmodel.dart';
import '../../../../core/widgets/branded_widgets.dart';

class BookingSummaryScreen extends StatelessWidget {
  const BookingSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingViewModel>();
    final service = vm.selectedCategory;
    
    if (service == null) return const Scaffold(body: Center(child: Text('Error: No service selected')));

    final subtotal = service.baseRatePerHour * vm.durationHours;
    final platformFee = subtotal * 0.10; // 10% fee
    final total = subtotal + platformFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.receipt_long, size: 40, color: Theme.of(context).colorScheme.primary),
              ).animate().scale(duration: 400.ms),
            ),
            const SizedBox(height: 24),
            
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Service Details', style: Theme.of(context).textTheme.titleLarge),
                  const Divider(height: 30),
                  _buildRow('Service', service.name),
                  const SizedBox(height: 12),
                  _buildRow('Date', vm.bookingDate ?? ''),
                  const SizedBox(height: 12),
                  _buildRow('Time', vm.startTime ?? ''),
                  const SizedBox(height: 12),
                  _buildRow('Duration', '${vm.durationHours} Hours'),
                  const SizedBox(height: 12),
                  _buildRow('Location', vm.addressText ?? ''),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            
            const SizedBox(height: 16),

            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Summary', style: Theme.of(context).textTheme.titleLarge),
                  const Divider(height: 30),
                  _buildRow('Subtotal', 'LKR $subtotal'),
                  const SizedBox(height: 12),
                  _buildRow('Platform Fee (10%)', 'LKR $platformFee'),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        'LKR $total',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            
            const SizedBox(height: 32),
            vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : BrandedButton(
                    label: 'Confirm & Pay (Sandbox)',
                    onPressed: () async {
                      await vm.confirmBooking('mock_user_123'); // hardcoded mock user ID for test flow
                      if (vm.errorMessage == null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Confirmed!')));
                        context.go('/customer');
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.errorMessage!)));
                      }
                    },
                  ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95)),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    );
  }
}
