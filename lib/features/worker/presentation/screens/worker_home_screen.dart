import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../viewmodels/worker_viewmodel.dart';
import '../../../../core/widgets/branded_widgets.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerViewModel>().fetchWorkerData('mock_worker_456');
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WorkerViewModel>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Provider Hub', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 80, left: 24, right: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusPill(vm.profile?.verificationStatus ?? 'pending'),
                      const SizedBox(height: 10),
                      Text(
                        vm.profile?.name ?? 'Loading...',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Onboarding Steps', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  _buildNavCard(
                    context,
                    title: 'Basic Profile',
                    subtitle: 'Set up your bio & services',
                    icon: Icons.person_outline,
                    route: '/worker/profile',
                    delayMs: 300,
                  ),
                  _buildNavCard(
                    context,
                    title: 'Verification Documents',
                    subtitle: 'Upload NIC/Passport',
                    icon: Icons.upload_file,
                    route: '/worker/documents',
                    delayMs: 400,
                  ),
                  _buildNavCard(
                    context,
                    title: 'Availability Status',
                    subtitle: 'Go Online/Offline for jobs',
                    icon: Icons.toggle_on_outlined,
                    route: '/worker/availability',
                    delayMs: 500,
                  ),

                  const SizedBox(height: 30),
                  const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  GlassCard(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('No jobs assigned yet.', style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 4),
                          const Text('Complete verification to receive bookings.', style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                  
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;
    IconData icon;
    
    if (status == 'approved') {
      bg = Colors.green.shade100;
      fg = Colors.green.shade800;
      icon = Icons.check_circle;
    } else {
      bg = Colors.orange.shade100;
      fg = Colors.orange.shade900;
      icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(status.toUpperCase(), style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNavCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required String route, required int delayMs}) {
    return GlassCard(
      onTap: () => context.push(route),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delayMs)).slideX(begin: 0.1);
  }
}
