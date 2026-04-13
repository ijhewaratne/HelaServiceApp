import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Phase 5: UI/UX Polish - Skeleton Loading States
/// 
/// Skeleton widgets provide visual feedback during data loading,
/// improving perceived performance and reducing user anxiety.

/// Base skeleton widget with shimmer effect
class Skeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const Skeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin,
  });

  const Skeleton.circle({
    super.key,
    required double size,
    this.margin,
  })  : width = size,
        height = size,
        borderRadius = 1000;

  const Skeleton.text({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius = 4,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Card skeleton with header, content, and actions
class SkeletonCard extends StatelessWidget {
  final bool showHeader;
  final bool showActions;
  final int contentLines;

  const SkeletonCard({
    super.key,
    this.showHeader = true,
    this.showActions = true,
    this.contentLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              Row(
                children: [
                  const Skeleton.circle(size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Skeleton.text(width: 120, height: 16),
                        SizedBox(height: 4),
                        Skeleton.text(width: 80, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            ...List.generate(
              contentLines,
              (index) => const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Skeleton.text(),
              ),
            ),
            if (showActions) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Skeleton(width: 80, height: 32, borderRadius: 8),
                  SizedBox(width: 8),
                  Skeleton(width: 80, height: 32, borderRadius: 8),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// List item skeleton for worker/service items
class SkeletonListItem extends StatelessWidget {
  final bool showImage;
  final bool showRating;
  final int subtitleLines;

  const SkeletonListItem({
    super.key,
    this.showImage = true,
    this.showRating = true,
    this.subtitleLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showImage) ...[
            Skeleton(
              width: 80,
              height: 80,
              borderRadius: 12,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Skeleton.text(height: 18),
                    ),
                    if (showRating) ...[
                      const SizedBox(width: 8),
                      const Skeleton(width: 40, height: 16),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                ...List.generate(
                  subtitleLines,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Skeleton.text(
                      width: index == subtitleLines - 1 ? 150 : double.infinity,
                      height: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Skeleton(width: 60, height: 24, borderRadius: 12),
                    const SizedBox(width: 8),
                    Skeleton(width: 80, height: 24, borderRadius: 12),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Service category skeleton
class SkeletonCategory extends StatelessWidget {
  final int itemCount;

  const SkeletonCategory({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: const [
                Skeleton.circle(size: 60),
                SizedBox(height: 8),
                Skeleton(width: 60, height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Booking card skeleton
class SkeletonBookingCard extends StatelessWidget {
  const SkeletonBookingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Skeleton(width: 80, height: 24, borderRadius: 12),
                const SizedBox(width: 8),
                const Skeleton(width: 100, height: 16),
                const Spacer(),
                const Skeleton(width: 40, height: 16),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Skeleton.circle(size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Skeleton.text(width: 140, height: 16),
                      SizedBox(height: 4),
                      Skeleton.text(width: 100, height: 14),
                      SizedBox(height: 4),
                      Skeleton.text(width: 120, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(
                  child: Skeleton(width: double.infinity, height: 40),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Skeleton(width: double.infinity, height: 40),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile header skeleton
class SkeletonProfileHeader extends StatelessWidget {
  const SkeletonProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Skeleton.circle(size: 100),
          const SizedBox(height: 16),
          const Skeleton(width: 150, height: 24),
          const SizedBox(height: 8),
          const Skeleton(width: 200, height: 14),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatSkeleton(),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              _buildStatSkeleton(),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              _buildStatSkeleton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatSkeleton() {
    return Column(
      children: const [
        Skeleton(width: 40, height: 24),
        SizedBox(height: 4),
        Skeleton(width: 60, height: 12),
      ],
    );
  }
}

/// Search results skeleton
class SkeletonSearchResults extends StatelessWidget {
  final int itemCount;

  const SkeletonSearchResults({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const SkeletonListItem();
      },
    );
  }
}

/// Grid skeleton for service/worker cards
class SkeletonGrid extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;

  const SkeletonGrid({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Skeleton(borderRadius: 12),
            ),
            const SizedBox(height: 8),
            const Skeleton.text(width: double.infinity, height: 16),
            const SizedBox(height: 4),
            Row(
              children: const [
                Skeleton(width: 60, height: 12),
                SizedBox(width: 8),
                Skeleton(width: 40, height: 12),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Full page skeleton for complex screens
class SkeletonPage extends StatelessWidget {
  final bool showAppBar;
  final int contentSections;

  const SkeletonPage({
    super.key,
    this.showAppBar = true,
    this.contentSections = 3,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAppBar) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Skeleton(width: 200, height: 28),
            ),
            const SizedBox(height: 16),
          ],
          ...List.generate(
            contentSections,
            (index) => Column(
              children: const [
                SkeletonCard(),
                SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer container for custom skeleton layouts
class ShimmerContainer extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerContainer({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}
