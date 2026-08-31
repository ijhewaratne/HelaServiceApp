import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../../worker/domain/entities/worker.dart';
import '../../../booking/domain/entities/review.dart';

class ProviderProfileScreen extends StatelessWidget {
  final String providerId;

  const ProviderProfileScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Profile'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // Gate 0 fix (location privacy / core-flow stabilization): `workers`
        // is owner+admin-only in firestore.rules (correctly, since it holds
        // NIC/home-address/home-coordinate fields) — there was no rule
        // granting a customer read access to it at all, so this screen was
        // being denied under the rules as actually deployed. It now reads
        // the Cloud-Function-maintained public mirror instead (see
        // functions/src/workerPublicProfile.ts), which excludes every
        // sensitive field.
        future: FirebaseFirestore.instance
            .collection('worker_public_profiles')
            .doc(providerId)
            .get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Provider not found'));
          }
          final worker = Worker.fromJson(
            snap.data!.data() as Map<String, dynamic>,
          );
          return _ProviderProfileBody(worker: worker);
        },
      ),
    );
  }
}

class _ProviderProfileBody extends StatelessWidget {
  final Worker worker;
  const _ProviderProfileBody({required this.worker});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              _ProfileHeader(worker: worker),
              _ProfileInfo(worker: worker),
              const Divider(height: 1),
              _ReviewsSection(providerId: worker.id),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Worker worker;
  const _ProfileHeader({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1B5E20),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Colors.white,
            backgroundImage: worker.profilePhotoUrl != null
                ? NetworkImage(worker.profilePhotoUrl!)
                : null,
            child: worker.profilePhotoUrl == null
                ? Text(
                    worker.fullName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            worker.businessName ?? worker.fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (worker.businessName != null)
            Text(
              worker.fullName,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                worker.rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${worker.totalJobs} jobs)',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(width: 16),
              if (worker.status == WorkerStatus.approved)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  final Worker worker;
  const _ProfileInfo({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (worker.bio != null && worker.bio!.isNotEmpty) ...[
            Text(
              'About',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              worker.bio!,
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            'Services',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: worker.services
                .map(
                  (s) => Chip(
                    label: Text(s.displayName),
                    backgroundColor: const Color(0xFFE8F5E9),
                    labelStyle: const TextStyle(color: Color(0xFF1B5E20)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            Icons.location_on,
            'Service Area',
            worker.district.isNotEmpty ? worker.district : worker.address,
          ),
          _InfoRow(
            Icons.radio_button_checked,
            'Service Radius',
            '${worker.serviceRadiusKm.toStringAsFixed(0)} km',
          ),
          if (worker.experienceYears != null)
            _InfoRow(
              Icons.work_history,
              'Experience',
              '${worker.experienceYears} years',
            ),
          _InfoRow(
            Icons.check_circle,
            'Availability',
            worker.isOnline ? 'Available Now' : 'Currently Unavailable',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/customer/book'),
              icon: const Icon(Icons.calendar_today),
              label: const Text('Request This Provider'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1B5E20)),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final String providerId;
  const _ReviewsSection({required this.providerId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reviews',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reviews')
                .where('providerId', isEqualTo: providerId)
                .where('moderationStatus', isEqualTo: 'approved')
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return Text(
                  'No reviews yet.',
                  style: TextStyle(color: Colors.grey[500]),
                );
              }
              final reviews = snap.data!.docs
                  .map((d) => Review.fromFirestore(d))
                  .toList();
              return Column(
                children: reviews.map((r) => _ReviewCard(review: r)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    Icons.star,
                    size: 16,
                    color: i < review.rating ? Colors.amber : Colors.grey[300],
                  ),
                ),
                const Spacer(),
                Text(
                  '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.reviewText!,
                style: TextStyle(color: Colors.grey[700], height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
