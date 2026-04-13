import 'package:cloud_firestore/cloud_firestore.dart';

/// Pagination configuration constants
class PaginationConfig {
  PaginationConfig._();

  /// Default page size for lists
  static const int defaultPageSize = 20;

  /// Small page size for mobile (slower connections)
  static const int smallPageSize = 10;

  /// Large page size for tablets/desktop
  static const int largePageSize = 50;

  /// Maximum page size to prevent memory issues
  static const int maxPageSize = 100;
}

/// Generic paginated result wrapper
class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final int totalLoaded;

  const PaginatedResult({
    required this.items,
    this.lastDocument,
    required this.hasMore,
    required this.totalLoaded,
  });

  /// Empty result
  factory PaginatedResult.empty() => const PaginatedResult(
        items: [],
        lastDocument: null,
        hasMore: false,
        totalLoaded: 0,
      );

  /// Copy with new values
  PaginatedResult<T> copyWith({
    List<T>? items,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
    int? totalLoaded,
  }) {
    return PaginatedResult(
      items: items ?? this.items,
      lastDocument: lastDocument ?? this.lastDocument,
      hasMore: hasMore ?? this.hasMore,
      totalLoaded: totalLoaded ?? this.totalLoaded,
    );
  }

  /// Append another paginated result
  PaginatedResult<T> append(PaginatedResult<T> other) {
    return PaginatedResult(
      items: [...items, ...other.items],
      lastDocument: other.lastDocument,
      hasMore: other.hasMore,
      totalLoaded: totalLoaded + other.totalLoaded,
    );
  }
}

/// Firestore pagination helper class
/// 
/// Example usage:
/// ```dart
/// final helper = FirestorePaginationHelper<JobModel>(
///   query: FirebaseFirestore.instance.collection('jobs')
///     .where('customerId', isEqualTo: userId)
///     .orderBy('createdAt', descending: true),
///   limit: 20,
///   fromJson: (json, id) => JobModel.fromJson(json, id: id),
/// );
/// 
/// // First page
/// final result = await helper.fetchFirstPage();
/// 
/// // Next page
/// if (result.hasMore) {
///   final nextPage = await helper.fetchNextPage();
/// }
/// ```
class FirestorePaginationHelper<T> {
  final Query<Map<String, dynamic>> _baseQuery;
  final int _limit;
  final T Function(Map<String, dynamic> json, String id) _fromJson;

  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;

  FirestorePaginationHelper({
    required Query<Map<String, dynamic>> query,
    required int limit,
    required T Function(Map<String, dynamic> json, String id) fromJson,
  })  : _baseQuery = query,
        _limit = limit.clamp(1, PaginationConfig.maxPageSize),
        _fromJson = fromJson;

  /// Whether more items are available
  bool get hasMore => _hasMore;

  /// Whether currently loading
  bool get isLoading => _isLoading;

  /// Reset pagination state
  void reset() {
    _lastDocument = null;
    _hasMore = true;
    _isLoading = false;
  }

  /// Fetch the first page of results
  Future<PaginatedResult<T>> fetchFirstPage() {
    reset();
    return _fetchPage();
  }

  /// Fetch the next page of results
  Future<PaginatedResult<T>> fetchNextPage() {
    if (!_hasMore || _isLoading || _lastDocument == null) {
      return Future.value(PaginatedResult(
        items: const [],
        lastDocument: _lastDocument,
        hasMore: _hasMore,
        totalLoaded: 0,
      ));
    }
    return _fetchPage();
  }

  /// Internal method to fetch a page
  Future<PaginatedResult<T>> _fetchPage() async {
    if (_isLoading) {
      return PaginatedResult(
        items: const [],
        lastDocument: _lastDocument,
        hasMore: _hasMore,
        totalLoaded: 0,
      );
    }

    _isLoading = true;

    try {
      Query<Map<String, dynamic>> query = _baseQuery.limit(_limit);

      // Add startAfter for pagination
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        _hasMore = false;
        _isLoading = false;
        return PaginatedResult(
          items: const [],
          lastDocument: _lastDocument,
          hasMore: false,
          totalLoaded: 0,
        );
      }

      // Check if we got a full page
      _hasMore = snapshot.docs.length >= _limit;

      // Save last document for next page
      _lastDocument = snapshot.docs.last;

      // Convert to models
      final items = snapshot.docs.map((doc) {
        return _fromJson(doc.data(), doc.id);
      }).toList();

      _isLoading = false;

      return PaginatedResult(
        items: items,
        lastDocument: _lastDocument,
        hasMore: _hasMore,
        totalLoaded: items.length,
      );
    } catch (e) {
      _isLoading = false;
      rethrow;
    }
  }
}

/// Real-time paginated stream helper
/// 
/// Creates a stream that automatically handles pagination
/// for real-time Firestore listeners
class PaginatedStreamHelper<T> {
  final Query<Map<String, dynamic>> _query;
  final int _pageSize;
  final T Function(Map<String, dynamic> json, String id) _fromJson;

  PaginatedStreamHelper({
    required Query<Map<String, dynamic>> query,
    required int pageSize,
    required T Function(Map<String, dynamic> json, String id) fromJson,
  })  : _query = query,
        _pageSize = pageSize.clamp(1, PaginationConfig.maxPageSize),
        _fromJson = fromJson;

  /// Get a stream of paginated results
  /// 
  /// [startAfter] - Optional document to start after for pagination
  Stream<PaginatedResult<T>> getStream({DocumentSnapshot? startAfter}) {
    Query<Map<String, dynamic>> currentQuery =
        _query.limit(_pageSize);

    if (startAfter != null) {
      currentQuery = currentQuery.startAfterDocument(startAfter);
    }

    return currentQuery.snapshots().map((snapshot) {
      final items = snapshot.docs.map((doc) {
        return _fromJson(doc.data(), doc.id);
      }).toList();

      final hasMore = snapshot.docs.length >= _pageSize;
      final lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      return PaginatedResult(
        items: items,
        lastDocument: lastDocument,
        hasMore: hasMore,
        totalLoaded: items.length,
      );
    });
  }
}

/// Pagination state mixin for BLoCs
/// 
/// Add this mixin to your BLoC to easily manage pagination state
mixin PaginationMixin<T> {
  final List<T> _items = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  List<T> get items => List.unmodifiable(_items);
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  int get loadedCount => _items.length;

  void resetPagination() {
    _items.clear();
    _lastDocument = null;
    _hasMore = true;
    _isLoadingMore = false;
  }

  void setLoadingMore(bool value) {
    _isLoadingMore = value;
  }

  void appendItems(PaginatedResult<T> result) {
    _items.addAll(result.items);
    _lastDocument = result.lastDocument;
    _hasMore = result.hasMore;
    _isLoadingMore = false;
  }

  void replaceItems(PaginatedResult<T> result) {
    _items.clear();
    _items.addAll(result.items);
    _lastDocument = result.lastDocument;
    _hasMore = result.hasMore;
    _isLoadingMore = false;
  }
}

/// Extension on Query for easy pagination
extension QueryPaginationExtension on Query<Map<String, dynamic>> {
  /// Creates a paginated query with common optimizations
  Query<Map<String, dynamic>> paginated({
    required int limit,
    DocumentSnapshot? startAfter,
  }) {
    Query<Map<String, dynamic>> result = this.limit(limit.clamp(
      1,
      PaginationConfig.maxPageSize,
    ));

    if (startAfter != null) {
      result = result.startAfterDocument(startAfter);
    }

    return result;
  }
}
