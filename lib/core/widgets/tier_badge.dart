import 'package:flutter/material.dart';
import '../../features/worker/domain/entities/worker_verification.dart';

// ──────────────────────────────────────────────────────────────────────────────
// TierBadge — visible trust indicator shown on worker profile cards (11.2.5)
// Green tier is not shown to customers (Green = baseline, no badge)
// ──────────────────────────────────────────────────────────────────────────────

class TierBadge extends StatelessWidget {
  final VerificationTier tier;
  final bool compact;

  const TierBadge({super.key, required this.tier, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (!tier.isVisible) return const SizedBox.shrink();

    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 4 : 8),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: compact ? 10 : 14),
          const SizedBox(width: 3),
          Text(
            tier.label.toUpperCase(),
            style: TextStyle(
              fontSize: compact ? 9 : 11,
              fontWeight: FontWeight.w800,
              color: _color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color get _color {
    switch (tier) {
      case VerificationTier.blue:
        return const Color(0xFF3B82F6);
      case VerificationTier.gold:
        return const Color(0xFFF59E0B);
      case VerificationTier.partner:
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF22C55E);
    }
  }

  IconData get _icon {
    switch (tier) {
      case VerificationTier.blue:
        return Icons.verified;
      case VerificationTier.gold:
        return Icons.workspace_premium;
      case VerificationTier.partner:
        return Icons.star;
      default:
        return Icons.check_circle;
    }
  }
}

/// Full worker profile card shown to customers during booking match
class WorkerProfileCard extends StatelessWidget {
  final String workerId;
  final String name;
  final String? photoUrl;
  final double rating;
  final int completedJobs;
  final VerificationTier tier;
  final VoidCallback? onSelect;

  const WorkerProfileCard({
    super.key,
    required this.workerId,
    required this.name,
    this.photoUrl,
    required this.rating,
    required this.completedJobs,
    required this.tier,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            backgroundColor: const Color(0xFF0F7A7A).withValues(alpha: 0.15),
            child: photoUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'W',
                    style: const TextStyle(
                      color: Color(0xFF0F7A7A),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    TierBadge(tier: tier, compact: true),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 3),
                    Text(
                      rating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_circle_outline,
                      size: 13,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$completedJobs jobs',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (onSelect != null) ...[
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: onSelect,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              child: const Text('Select', style: TextStyle(fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }
}
