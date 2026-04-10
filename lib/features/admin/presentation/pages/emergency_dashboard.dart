import 'package:flutter/material.dart';
import '../../../incident/domain/entities/incident.dart';

/// Admin dashboard for emergency incidents
class EmergencyDashboard extends StatelessWidget {
  const EmergencyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh incidents
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Pending'),
                Tab(text: 'Investigating'),
                Tab(text: 'Resolved'),
                Tab(text: 'All'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildIncidentList(IncidentStatus.pending),
                  _buildIncidentList(IncidentStatus.investigating),
                  _buildIncidentList(IncidentStatus.resolved),
                  _buildIncidentList(null),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentList(IncidentStatus? status) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // Placeholder
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(status ?? IncidentStatus.pending),
              child: const Icon(Icons.warning, color: Colors.white),
            ),
            title: Text('Incident #${1000 + index}'),
            subtitle: const Text('Safety Concern • 5 mins ago'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // View incident details
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.pending:
        return Colors.red;
      case IncidentStatus.investigating:
        return Colors.orange;
      case IncidentStatus.resolved:
        return Colors.green;
      case IncidentStatus.escalated:
        return Colors.purple;
    }
  }
}
