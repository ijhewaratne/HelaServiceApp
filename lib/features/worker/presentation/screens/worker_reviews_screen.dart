import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../booking/domain/entities/review.dart';

class WorkerReviewsScreen extends StatelessWidget {
  const WorkerReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reviews'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('providerId', isEqualTo: uid)
            .where('moderationStatus', isEqualTo: 'approved')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No reviews yet',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    'Reviews from completed bookings will appear here\nafter moderation.',
                    style:
                        TextStyle(color: Colors.grey[400], fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final reviews = snap.data!.docs
              .map((d) => Review.fromFirestore(d))
              .toList();

          final avgRating = reviews.isEmpty
              ? 0.0
              : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                  reviews.length;

          return Column(
            children: [
              _RatingSummary(
                  avgRating: avgRating, count: reviews.length),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) =>
                      _ReviewCard(review: reviews[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final double avgRating;
  final int count;
  const _RatingSummary({required this.avgRating, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFFF1F8E9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 40),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(avgRating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold)),
              Text('from $count review${count == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.grey[600])),
            ],
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
                    (i) => Icon(Icons.star,
                        size: 18,
                        color: i < review.rating
                            ? Colors.amber
                            : Colors.grey[300])),
                const Spacer(),
                Text(
                  '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            if (review.reviewText != null &&
                review.reviewText!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(review.reviewText!,
                  style: TextStyle(color: Colors.grey[700], height: 1.4)),
            ],
            if (review.punctualityRating != null ||
                review.qualityRating != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (review.punctualityRating != null)
                    _MiniStat('Punctuality',
                        '${review.punctualityRating}/5'),
                  if (review.qualityRating != null) ...[
                    const SizedBox(width: 16),
                    _MiniStat(
                        'Quality', '${review.qualityRating}/5'),
                  ],
                  if (review.wouldRecommend == true) ...[
                    const Spacer(),
                    const Icon(Icons.thumb_up,
                        size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    const Text('Recommended',
                        style: TextStyle(
                            color: Colors.green, fontSize: 12)),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
