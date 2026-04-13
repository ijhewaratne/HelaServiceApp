# Sprint 4: Performance Optimization Guide

This document outlines the performance optimizations implemented in the HelaService app.

## Table of Contents

1. [Image Optimization](#image-optimization)
2. [List Optimization](#list-optimization)
3. [Query Optimization](#query-optimization)
4. [BLoC Optimization](#bloc-optimization)

---

## Image Optimization

### Use Optimized Widgets

Replace `Image.network` with optimized widgets from `core/widgets/optimized_image.dart`:

```dart
// ❌ Don't use this
Image.network(url)

// ✅ Use this for lists
OptimizedListImage(
  imageUrl: worker.profilePhotoUrl!,
  width: 80,
  height: 80,
  borderRadius: BorderRadius.circular(8),
)

// ✅ Use this for profile photos
OptimizedProfileImage(
  imageUrl: worker.profilePhotoUrl,
  radius: 40,
  fallbackText: worker.name,
)

// ✅ Use this for detail views
OptimizedDetailImage(
  imageUrl: job.imageUrl!,
  height: 200,
  fit: BoxFit.cover,
)
```

### Cache Size Guidelines

| Use Case | Cache Width | Memory Impact |
|----------|-------------|---------------|
| Thumbnails | 100px | Very Low |
| List Items | 200px | Low |
| Detail Images | 400px | Medium |
| Full Screen | 800px | High |

### Manual Cache Configuration

```dart
OptimizedNetworkImage(
  imageUrl: url,
  memCacheWidth: 200,  // Resize for memory cache
  memCacheHeight: 200,
)
```

---

## List Optimization

### Use ListView.builder

```dart
// ❌ Don't use this for long lists
ListView(
  children: items.map((item) => ItemWidget(item)).toList(),
)

// ✅ Use this
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
  addAutomaticKeepAlives: false,  // For better memory
  addRepaintBoundaries: true,     // For better performance
  cacheExtent: 200.0,             // Preload off-screen items
)
```

### Use Performance Utils

```dart
PerformanceUtils.optimizedListView<JobModel>(
  items: jobs,
  itemBuilder: (context, job, index) => JobCard(job: job),
  onRefresh: () async {
    context.read<JobsBloc>().add(LoadJobs());
  },
  emptyWidget: EmptyJobsWidget(),
)
```

### Pagination with Scroll Listener

```dart
class _JobListState extends State<JobList> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _scrollController.addPaginationListener(_loadMore);
  }
  
  void _loadMore() {
    if (context.read<JobsBloc>().state.hasMore) {
      context.read<JobsBloc>().add(LoadMoreJobs());
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      // ...
    );
  }
}
```

---

## Query Optimization

### Add Pagination

```dart
// ❌ Don't fetch everything
FirebaseFirestore.instance
  .collection('jobs')
  .where('customerId', isEqualTo: userId)
  .get();

// ✅ Use pagination
FirebaseFirestore.instance
  .collection('jobs')
  .where('customerId', isEqualTo: userId)
  .orderBy('createdAt', descending: true)
  .limit(20)  // Paginate
  .get();
```

### Use Pagination Helper

```dart
final helper = FirestorePaginationHelper<JobModel>(
  query: FirebaseFirestore.instance
    .collection('jobs')
    .where('customerId', isEqualTo: userId)
    .orderBy('createdAt', descending: true),
  limit: PaginationConfig.defaultPageSize,
  fromJson: (json, id) => JobModel.fromJson(json, id: id),
);

// First page
final result = await helper.fetchFirstPage();

// Next page
if (result.hasMore) {
  final nextPage = await helper.fetchNextPage();
}
```

### Use BLoC with Pagination Mixin

```dart
class JobsBloc extends Bloc<JobsEvent, JobsState> with PaginationMixin<JobModel> {
  final JobsRepository _repository;
  
  JobsBloc(this._repository) : super(JobsState()) {
    on<LoadJobs>(_onLoadJobs);
    on<LoadMoreJobs>(_onLoadMoreJobs, 
      transformer: EventTransformers.throttle(const Duration(milliseconds: 500)));
  }
  
  Future<void> _onLoadJobs(LoadJobs event, Emitter<JobsState> emit) async {
    resetPagination();
    // ... fetch and use appendItems()
  }
  
  Future<void> _onLoadMoreJobs(LoadMoreJobs event, Emitter<JobsState> emit) async {
    if (isLoadingMore || !hasMore) return;
    setLoadingMore(true);
    // ... fetch and use appendItems()
  }
}
```

---

## BLoC Optimization

### Use buildWhen to Prevent Unnecessary Rebuilds

```dart
// ❌ Rebuilds on every state change
BlocBuilder<WorkerBloc, WorkerState>(
  builder: (context, state) {
    return Text('Online: ${state.isOnline}');
  },
)

// ✅ Only rebuilds when isOnline changes
BlocBuilder<WorkerBloc, WorkerState>(
  buildWhen: (previous, current) => 
    previous.isOnline != current.isOnline,
  builder: (context, state) {
    return Text('Online: ${state.isOnline}');
  },
)
```

### Use BuildOptimization Predicates

```dart
// Using predefined predicates
BlocBuilder<MyBloc, MyState>(
  buildWhen: (prev, curr) => 
    BuildOptimization.whenPropertyChanged(prev, curr, (s) => s.count),
  builder: (context, state) => Text('${state.count}'),
)

// Multiple properties
BlocBuilder<MyBloc, MyState>(
  buildWhen: (prev, curr) => BuildOptimization.whenAnyPropertyChanged(
    prev, 
    curr, 
    [(s) => s.name, (s) => s.avatar],
  ),
  builder: (context, state) => ProfileHeader(state),
)
```

### Use Event Transformers

```dart
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(SearchState()) {
    // Debounce search input
    on<SearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: EventTransformers.debounce(const Duration(milliseconds: 300)),
    );
    
    // Throttle rapid updates
    on<LocationUpdated>(
      _onLocationUpdated,
      transformer: EventTransformers.throttle(const Duration(milliseconds: 500)),
    );
  }
}
```

### Use Optimized State Classes

```dart
class JobsState extends OptimizedState {
  final List<Job> jobs;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  
  const JobsState({
    this.jobs = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });
  
  @override
  List<Object?> get props => [jobs, isLoading, hasMore, error];
  
  JobsState copyWith({...}) => ...
}
```

### Enable Performance Monitoring

```dart
// In main.dart
void main() {
  if (kDebugMode) {
    Bloc.observer = PerformanceBlocObserver(
      trackEventProcessingTime: true,
      logStateChanges: true,
    );
  }
  runApp(MyApp());
}
```

---

## Best Practices Checklist

- [ ] Replace all `Image.network` with `OptimizedNetworkImage`
- [ ] Use appropriate cache sizes for different image sizes
- [ ] Convert long lists to `ListView.builder`
- [ ] Add pagination to all Firestore list queries
- [ ] Use `buildWhen` in BlocBuilder where applicable
- [ ] Apply event transformers for input fields and rapid events
- [ ] Implement proper loading states and skeleton screens
- [ ] Monitor performance in debug mode with PerformanceBlocObserver

---

## Performance Targets

| Metric | Target |
|--------|--------|
| Time to First Frame | < 1s |
| List Scroll FPS | 60 FPS |
| Image Load Time | < 300ms |
| BLoC Transition | < 16ms |
| Memory Usage | < 150MB |

---

## Troubleshooting

### Images Loading Slowly
- Check cache size settings
- Verify CDN/image hosting performance
- Use lower resolution images for thumbnails

### List Jank
- Ensure proper use of `ListView.builder`
- Check for expensive operations in `itemBuilder`
- Use `const` constructors where possible

### High Memory Usage
- Reduce image cache sizes
- Implement proper disposal of controllers
- Check for memory leaks in streams

### Slow Firestore Queries
- Add proper indexes
- Use pagination
- Reduce query complexity
