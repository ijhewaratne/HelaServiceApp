import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Performance optimization utilities for HelaService app
/// Sprint 4: Performance Optimization
class PerformanceUtils {
  PerformanceUtils._(); // Private constructor

  // ===========================================================================
  // IMAGE OPTIMIZATION
  // ===========================================================================

  /// Standard image cache widths for different use cases
  static const int thumbnailWidth = 100;
  static const int listItemWidth = 200;
  static const int detailImageWidth = 400;
  static const int fullScreenWidth = 800;

  /// Creates an optimized cached network image widget
  /// 
  /// [imageUrl] - The URL of the image
  /// [width] - Target width for memory cache optimization
  /// [height] - Optional height constraint
  /// [fit] - BoxFit mode (default: BoxFit.cover)
  /// [placeholder] - Custom placeholder widget
  /// [errorWidget] - Custom error widget
  static Widget optimizedNetworkImage({
    required String imageUrl,
    int? memCacheWidth,
    int? memCacheHeight,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    Duration fadeInDuration = const Duration(milliseconds: 200),
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth ?? listItemWidth,
      memCacheHeight: memCacheHeight,
      fadeInDuration: fadeInDuration,
      placeholder: placeholder != null
          ? (context, url) => placeholder
          : (context, url) => _defaultPlaceholder(width, height),
      errorWidget: errorWidget != null
          ? (context, url, error) => errorWidget
          : (context, url, error) => _defaultErrorWidget(width, height),
    );
  }

  /// Creates a circular profile image with optimization
  static Widget optimizedProfileImage({
    required String? imageUrl,
    required double radius,
    String? fallbackText,
    Color? backgroundColor,
  }) {
    final size = (radius * 2).toInt();

    if (imageUrl == null || imageUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[300],
        child: fallbackText != null
            ? Text(
                fallbackText.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: radius * 0.8,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              )
            : Icon(Icons.person, size: radius),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        memCacheWidth: size,
        memCacheHeight: size,
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[200],
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? Colors.grey[300],
          child: fallbackText != null
              ? Text(
                  fallbackText.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: radius * 0.8,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Icon(Icons.person, size: radius),
        ),
      ),
    );
  }

  /// Default placeholder widget
  static Widget _defaultPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  /// Default error widget
  static Widget _defaultErrorWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  // ===========================================================================
  // LIST OPTIMIZATION
  // ===========================================================================

  /// Creates an optimized ListView.builder with standard configurations
  static Widget optimizedListView<T>({
    required List<T> items,
    required Widget Function(BuildContext, T, int) itemBuilder,
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    Widget? separator,
    ScrollController? controller,
    Future<void> Function()? onRefresh,
    Widget? emptyWidget,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? cacheExtent,
  }) {
    if (items.isEmpty && emptyWidget != null) {
      return emptyWidget;
    }

    Widget listView = ListView.separated(
      controller: controller,
      padding: padding ?? const EdgeInsets.all(16),
      physics: physics ?? const AlwaysScrollableScrollPhysics(),
      shrinkWrap: shrinkWrap,
      itemCount: items.length,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      cacheExtent: cacheExtent,
      separatorBuilder: (context, index) =>
          separator ?? const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return itemBuilder(context, item, index);
      },
    );

    if (onRefresh != null) {
      listView = RefreshIndicator(
        onRefresh: onRefresh,
        child: listView,
      );
    }

    return listView;
  }

  /// Creates a sliver list for CustomScrollView with optimization
  static Widget optimizedSliverList<T>({
    required List<T> items,
    required Widget Function(BuildContext, T, int) itemBuilder,
    Widget? separator,
  }) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (separator != null && index.isOdd) {
            return separator;
          }
          final itemIndex = separator != null ? index ~/ 2 : index;
          if (itemIndex >= items.length) return null;
          return itemBuilder(context, items[itemIndex], itemIndex);
        },
        childCount: separator != null
            ? items.length * 2 - 1
            : items.length,
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
        addSemanticIndexes: true,
      ),
    );
  }

  // ===========================================================================
  // SCROLL OPTIMIZATION
  // ===========================================================================

  /// Recommended cache extent for different list types
  static const double listCacheExtent = 200.0;
  static const double gridCacheExtent = 400.0;

  /// Debounces scroll events to prevent excessive rebuilds
  static ScrollNotificationPredicate scrollNotificationPredicate =
      (notification) {
    // Only trigger on scroll end to reduce rebuilds
    if (notification is ScrollEndNotification) {
      return true;
    }
    return false;
  };
}

/// Extension for optimized scroll controller
extension ScrollControllerExtension on ScrollController {
  /// Checks if the scroll position is near the bottom (for pagination)
  bool get isNearBottom {
    if (!hasClients) return false;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;
    return currentScroll >= (maxScroll * 0.8); // 80% scrolled
  }

  /// Adds a listener for pagination triggers
  void addPaginationListener(VoidCallback onLoadMore) {
    addListener(() {
      if (isNearBottom) {
        onLoadMore();
      }
    });
  }
}
