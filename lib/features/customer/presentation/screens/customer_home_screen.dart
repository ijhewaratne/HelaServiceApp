import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../viewmodels/customer_home_viewmodel.dart';
import '../../../../core/widgets/branded_widgets.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Hardcoded mock user ID for now since mock auth doesn't persist real UIDs perfectly
      context.read<CustomerViewModel>().fetchMyBookings('mock_user_123');
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CustomerViewModel>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Servix', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Good Morning,', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      const Text('Need a hand today?', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white),
                onPressed: () {
                  context.go('/login'); // basic logout for MVP
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Book a Service', style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              const Text('Cleaning, babysitting, & more.', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        FloatingActionButton(
                          heroTag: 'bookService',
                          onPressed: () => context.push('/customer/book'),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          elevation: 0,
                          child: const Icon(Icons.add, color: Colors.white),
                        ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                  
                  const SizedBox(height: 30),
                  Text('Active Bookings', style: Theme.of(context).textTheme.titleLarge).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 16),
                  
                  if (vm.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (vm.activeBookings.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.event_busy, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('No active bookings', style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms)
                  else
                    ...vm.activeBookings.map((b) => GlassCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Icon(Icons.cleaning_services, color: Theme.of(context).colorScheme.primary),
                        ),
                        title: Text(b.serviceType.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${b.bookingDate} at ${b.startTime}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(b.status.toUpperCase(), style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.05)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
