import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/widgets/branded_widgets.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operations Command Center', style: TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),
            
            _buildAdminCard(
              context,
              title: 'Worker Approvals',
              subtitle: 'Verify documents & activate accounts',
              icon: Icons.verified_user_outlined,
              route: '/admin/workers',
              delayMs: 200,
            ),
            _buildAdminCard(
              context,
              title: 'Dispatch Board',
              subtitle: 'Assign available workers to open bookings',
              icon: Icons.business_center_outlined,
              route: '/admin/bookings',
              delayMs: 300,
            ),
            _buildAdminCard(
              context,
              title: 'Support & Incidents',
              subtitle: 'Resolve complaints and platform issues',
              icon: Icons.support_agent_outlined,
              route: '/admin/incidents',
              delayMs: 400,
            ),
            
            const SizedBox(height: 40),
            Center(
              child: Opacity(
                opacity: 0.5,
                child: Column(
                  children: [
                    Icon(Icons.dashboard_customize, size: 48, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    const Text('Servix Admin V1.0'),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required String route, required int delayMs}) {
    return GlassCard(
      onTap: () => context.push(route),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delayMs)).slideY(begin: 0.1);
  }
}
