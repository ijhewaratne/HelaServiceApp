import 'package:flutter/material.dart';

class ServiceSelectionPage extends StatelessWidget {
  const ServiceSelectionPage({super.key});

  final List<Map<String, dynamic>> _services = const [
    {
      'id': 'cleaning',
      'title': 'Home Cleaning',
      'icon': Icons.cleaning_services,
      'color': Colors.blue,
      'desc': 'Deep cleaning, regular sweeping, and mopping.',
    },
    {
      'id': 'babysitting',
      'title': 'Babysitting',
      'icon': Icons.child_care,
      'color': Colors.orange,
      'desc': 'Vetted child care professionals for peace of mind.',
    },
    {
      'id': 'elderly',
      'title': 'Elderly Care',
      'icon': Icons.elderly,
      'color': Colors.green,
      'desc': 'Compassionate assistance for senior daily activities.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Select a Service'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What do you need help with?',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All providers carry verified NICs and are thoroughly vetted.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final service = _services[index];
                  return _ServiceCard(
                    title: service['title'] as String,
                    icon: service['icon'] as IconData,
                    color: service['color'] as Color,
                    desc: service['desc'] as String,
                    onTap: () {
                      // Navigate to animated matching queue or form
                      // context.go('/customer/book/form');
                    },
                  );
                },
                childCount: _services.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String desc;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
