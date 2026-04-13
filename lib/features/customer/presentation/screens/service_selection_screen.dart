import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../viewmodels/booking_viewmodel.dart';
import '../../../../core/widgets/branded_widgets.dart';

class ServiceSelectionScreen extends StatefulWidget {
  const ServiceSelectionScreen({super.key});

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingViewModel>().fetchServices();
    });
  }

  IconData _getIconForService(String id) {
    if (id.contains('clean')) return Icons.cleaning_services_rounded;
    if (id.contains('baby')) return Icons.child_care_rounded;
    if (id.contains('elder')) return Icons.elderly_rounded;
    return Icons.handyman_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Select Service')),
      body: vm.isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: vm.availableServices.length,
            itemBuilder: (context, index) {
              final service = vm.availableServices[index];
              return GlassCard(
                onTap: () {
                  context.read<BookingViewModel>().selectedCategory = service;
                  context.push('/customer/book/form');
                },
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getIconForService(service.id), color: Theme.of(context).colorScheme.primary, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                          const SizedBox(height: 4),
                          Text('LKR ${service.baseRatePerHour}/hour', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                  ],
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1);
            },
          ),
    );
  }
}
