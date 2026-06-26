import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../booking/domain/entities/booking.dart';
import '../../../booking/domain/entities/review.dart';

class ReviewProviderScreen extends StatefulWidget {
  final String requestId;
  final Booking? booking;

  const ReviewProviderScreen({
    super.key,
    required this.requestId,
    this.booking,
  });

  @override
  State<ReviewProviderScreen> createState() => _ReviewProviderScreenState();
}

class _ReviewProviderScreenState extends State<ReviewProviderScreen> {
  int _rating = 0;
  int _punctualityRating = 0;
  int _qualityRating = 0;
  bool _wouldRecommend = true;
  bool _providerOnTime = true;
  final _textController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an overall rating')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final booking = widget.booking;
    final providerId = booking?.workerId;
    if (providerId == null || providerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot find provider for this booking')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final existing = await FirebaseFirestore.instance
          .collection('reviews')
          .where('requestId', isEqualTo: widget.requestId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('You have already reviewed this booking')),
          );
        }
        return;
      }

      final review = Review(
        id: '',
        requestId: widget.requestId,
        customerId: uid,
        providerId: providerId,
        rating: _rating,
        reviewText: _textController.text.trim().isEmpty
            ? null
            : _textController.text.trim(),
        punctualityRating:
            _punctualityRating == 0 ? null : _punctualityRating,
        qualityRating: _qualityRating == 0 ? null : _qualityRating,
        wouldRecommend: _wouldRecommend,
        wasProviderOnTime: _providerOnTime,
        moderationStatus: ReviewModerationStatus.pending,
        createdAt: DateTime.now(),
      );

      final docRef =
          FirebaseFirestore.instance.collection('reviews').doc();
      await docRef.set(review.copyWith(id: docRef.id).toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Review submitted — thank you! It will appear after moderation.')),
        );
        context.go('/customer/bookings');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Provider'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How was your experience?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your honest feedback helps maintain quality for the community.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            _SectionLabel('Overall Rating *'),
            _StarPicker(
              value: _rating,
              onChanged: (v) => setState(() => _rating = v),
              size: 40,
            ),
            const SizedBox(height: 24),
            _SectionLabel('Punctuality'),
            _StarPicker(
              value: _punctualityRating,
              onChanged: (v) => setState(() => _punctualityRating = v),
              size: 32,
            ),
            const SizedBox(height: 24),
            _SectionLabel('Quality of Work'),
            _StarPicker(
              value: _qualityRating,
              onChanged: (v) => setState(() => _qualityRating = v),
              size: 32,
            ),
            const SizedBox(height: 24),
            _SectionLabel('Write a Review (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Share details about your experience...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1B5E20)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Was the provider on time?'),
              value: _providerOnTime,
              onChanged: (v) => setState(() => _providerOnTime = v),
              activeColor: const Color(0xFF1B5E20),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Would you recommend this provider?'),
              value: _wouldRecommend,
              onChanged: (v) => setState(() => _wouldRecommend = v),
              activeColor: const Color(0xFF1B5E20),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Review',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15));
  }
}

class _StarPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  const _StarPicker(
      {required this.value, required this.onChanged, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => GestureDetector(
          onTap: () => onChanged(i + 1),
          child: Icon(
            i < value ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: size,
          ),
        ),
      ),
    );
  }
}
