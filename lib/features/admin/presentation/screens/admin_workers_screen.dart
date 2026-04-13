import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../viewmodels/admin_dashboard_viewmodel.dart';
import '../../../../shared/dialogs/confirm_dialog.dart';
import '../../../../core/widgets/branded_widgets.dart';

class AdminWorkersScreen extends StatefulWidget {
  const AdminWorkersScreen({super.key});

  @override
  State<AdminWorkersScreen> createState() => _AdminWorkersScreenState();
}

class _AdminWorkersScreenState extends State<AdminWorkersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Worker Approvals')),
      body: vm.isLoading
        ? const Center(child: CircularProgressIndicator())
        : vm.pendingWorkers.isEmpty 
          ? Center(child: Text('No pending workers', style: TextStyle(color: Colors.grey.shade600)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.pendingWorkers.length,
              itemBuilder: (context, index) {
                final worker = vm.pendingWorkers[index];
                return GlassCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: Icon(Icons.person, color: Colors.orange.shade800),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(worker.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('ID: ${worker.uid.substring(0,8)}... | ${worker.verificationStatus.toUpperCase()}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final confirm = await showConfirmDialog(
                            context,
                            title: 'Approve Worker',
                            message: 'Approve ${worker.name}?',
                          );
                          if (confirm && context.mounted) {
                            await context.read<AdminViewModel>().approveWorker(worker.uid);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text('Approve', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1);
              },
            ),
    );
  }
}
