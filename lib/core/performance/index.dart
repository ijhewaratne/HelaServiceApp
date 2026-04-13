/// Performance Optimization Library
/// 
/// Sprint 4: Performance Optimization for HelaService
/// 
/// This library provides utilities for:
/// - Image optimization with caching
/// - List pagination and lazy loading
/// - Firestore query pagination
/// - BLoC state optimization
/// 
/// Usage:
/// ```dart
/// import 'package:home_service_app/core/performance/index.dart';
/// ```

// Utils
export '../utils/performance_utils.dart';
export '../utils/pagination_helper.dart';

// BLoC
export '../bloc/performance_mixin.dart';

// Widgets
export '../widgets/optimized_image.dart';

/// Version of the performance optimization package
const String performanceLibraryVersion = '1.0.0';

/// Performance optimization features
class PerformanceFeatures {
  PerformanceFeatures._();

  static const bool imageCaching = true;
  static const bool listPagination = true;
  static const bool queryOptimization = true;
  static const bool blocOptimization = true;
  static const bool memoryManagement = true;
}

/// Quick configuration for common optimizations
class QuickPerformanceConfig {
  QuickPerformanceConfig._();

  /// Apply standard performance settings for list views
  static const listViewOptimization = {
    'addAutomaticKeepAlives': false,
    'addRepaintBoundaries': true,
    'cacheExtent': 200.0,
  };

  /// Apply standard performance settings for image caching
  static const imageCacheOptimization = {
    'thumbnailWidth': 100,
    'listItemWidth': 200,
    'detailImageWidth': 400,
    'fadeInDuration': 200, // milliseconds
  };

  /// Apply standard performance settings for pagination
  static const paginationOptimization = {
    'defaultPageSize': 20,
    'maxPageSize': 100,
    'loadMoreThreshold': 0.8, // 80% scroll
  };

  /// Apply standard performance settings for BLoC
  static const blocOptimization = {
    'debounceSearch': 300, // milliseconds
    'throttleLocation': 500, // milliseconds
    'throttleScroll': 100, // milliseconds
  };
}
