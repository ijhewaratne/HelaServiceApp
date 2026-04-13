/// Example Usage: Performance Optimizations
/// 
/// This file demonstrates how to use the performance optimization utilities
/// throughout the HelaService app.

// ============================================================================
// EXAMPLE 1: Image Optimization in Worker Card
// ============================================================================

/*
import 'package:flutter/material.dart';
import '../widgets/optimized_image.dart';

class OptimizedWorkerCard extends StatelessWidget {
  final Worker worker;
  
  const OptimizedWorkerCard({super.key, required this.worker});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        // Optimized profile image with fallback
        leading: OptimizedProfileImage(
          imageUrl: worker.profilePhotoUrl,
          radius: 30,
          fallbackText: worker.name,
        ),
        title: Text(worker.name),
        subtitle: Text(worker.serviceCategory),
        // Optimized thumbnail for service images
        trailing: worker.servicePhotos.isNotEmpty
            ? OptimizedListImage(
                imageUrl: worker.servicePhotos.first,
                width: 60,
                height: 60,
                borderRadius: BorderRadius.circular(8),
              )
            : null,
      ),
    );
  }
}
*/

// ============================================================================
// EXAMPLE 2: Paginated Job List with BLoC
// ============================================================================

/*
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/pagination_helper.dart';
import '../bloc/performance_mixin.dart';

// State
class PaginatedJobsState extends OptimizedState {
  final List<Job> jobs;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  
  const PaginatedJobsState({
    this.jobs = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });
  
  @override
  List<Object?> get props => [jobs, isLoading, isLoadingMore, hasMore, error];
  
  PaginatedJobsState copyWith({
    List<Job>? jobs,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return PaginatedJobsState(
      jobs: jobs ?? this.jobs,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }
}

// Events
abstract class PaginatedJobsEvent {}

class LoadJobs extends PaginatedJobsEvent {}
class LoadMoreJobs extends PaginatedJobsEvent {}
class RefreshJobs extends PaginatedJobsEvent {}

// BLoC with Pagination Mixin
class PaginatedJobsBloc extends Bloc<PaginatedJobsEvent, PaginatedJobsState>
    with PaginationMixin<Job> {
  
  final JobsRepository _repository;
  late final FirestorePaginationHelper<Job> _paginationHelper;
  
  PaginatedJobsBloc(this._repository) : super(const PaginatedJobsState()) {
    _paginationHelper = FirestorePaginationHelper<Job>(
      query: FirebaseFirestore.instance
          .collection('jobs')
          .orderBy('createdAt', descending: true),
      limit: PaginationConfig.defaultPageSize,
      fromJson: (json, id) => Job.fromJson(json, id: id),
    );
    
    on<LoadJobs>(_onLoadJobs);
    on<LoadMoreJobs>(_onLoadMoreJobs, 
      transformer: EventTransformers.throttle(const Duration(milliseconds: 500)));
    on<RefreshJobs>(_onRefreshJobs);
  }
  
  Future<void> _onLoadJobs(
    LoadJobs event,
    Emitter<PaginatedJobsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      resetPagination();
      final result = await _paginationHelper.fetchFirstPage();
      appendItems(result);
      
      emit(state.copyWith(
        jobs: items,
        isLoading: false,
        hasMore: hasMore,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
  
  Future<void> _onLoadMoreJobs(
    LoadMoreJobs event,
    Emitter<PaginatedJobsState> emit,
  ) async {
    if (isLoadingMore || !hasMore) return;
    
    setLoadingMore(true);
    emit(state.copyWith(isLoadingMore: true));
    
    try {
      final result = await _paginationHelper.fetchNextPage();
      appendItems(result);
      
      emit(state.copyWith(
        jobs: items,
        isLoadingMore: false,
        hasMore: hasMore,
      ));
    } catch (e) {
      setLoadingMore(false);
      emit(state.copyWith(isLoadingMore: false, error: e.toString()));
    }
  }
  
  Future<void> _onRefreshJobs(
    RefreshJobs event,
    Emitter<PaginatedJobsState> emit,
  ) async {
    add(LoadJobs());
  }
}

// Widget
class OptimizedJobList extends StatefulWidget {
  const OptimizedJobList({super.key});
  
  @override
  State<OptimizedJobList> createState() => _OptimizedJobListState();
}

class _OptimizedJobListState extends State<OptimizedJobList> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _scrollController.addPaginationListener(_onLoadMore);
  }
  
  void _onLoadMore() {
    context.read<PaginatedJobsBloc>().add(LoadMoreJobs());
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaginatedJobsBloc, PaginatedJobsState>(
      builder: (context, state) {
        if (state.isLoading && state.jobs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            context.read<PaginatedJobsBloc>().add(RefreshJobs());
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: state.jobs.length + (state.hasMore ? 1 : 0),
            cacheExtent: PerformanceUtils.listCacheExtent,
            itemBuilder: (context, index) {
              if (index >= state.jobs.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return JobListItem(job: state.jobs[index]);
            },
          ),
        );
      },
    );
  }
}
*/

// ============================================================================
// EXAMPLE 3: Optimized Search with Debouncing
// ============================================================================

/*
// Events
class SearchQueryChanged extends PaginatedJobsEvent {
  final String query;
  SearchQueryChanged(this.query);
}

// In BLoC
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(SearchState()) {
    on<SearchQueryChanged>(
      _onSearchQueryChanged,
      // Debounce to wait for user to stop typing
      transformer: EventTransformers.debounce(const Duration(milliseconds: 300)),
    );
  }
  
  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.length < 2) {
      emit(state.copyWith(results: [], isSearching: false));
      return;
    }
    
    emit(state.copyWith(isSearching: true));
    
    // Perform search
    final results = await _searchRepository.search(event.query);
    
    emit(state.copyWith(
      results: results,
      isSearching: false,
    ));
  }
}

// Widget with optimized buildWhen
class SearchResults extends StatelessWidget {
  const SearchResults({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search field that triggers events
        TextField(
          onChanged: (value) {
            context.read<SearchBloc>().add(SearchQueryChanged(value));
          },
        ),
        
        // Results - only rebuild when results change
        BlocBuilder<SearchBloc, SearchState>(
          buildWhen: (prev, curr) => 
            BuildOptimization.whenPropertyChanged(prev, curr, (s) => s.results),
          builder: (context, state) {
            return ListView.builder(
              shrinkWrap: true,
              itemCount: state.results.length,
              itemBuilder: (context, index) {
                return SearchResultItem(result: state.results[index]);
              },
            );
          },
        ),
        
        // Loading indicator - only rebuild when isSearching changes
        BlocBuilder<SearchBloc, SearchState>(
          buildWhen: (prev, curr) => prev.isSearching != curr.isSearching,
          builder: (context, state) {
            if (state.isSearching) {
              return const LinearProgressIndicator();
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
*/

// ============================================================================
// EXAMPLE 4: Optimized Chat with Throttling
// ============================================================================

/*
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc() : super(ChatState()) {
    // Throttle typing indicators
    on<UserTyping>(
      _onUserTyping,
      transformer: EventTransformers.throttle(const Duration(seconds: 1)),
    );
    
    // Debounce message drafts
    on<DraftChanged>(
      _onDraftChanged,
      transformer: EventTransformers.debounce(const Duration(milliseconds: 500)),
    );
    
    on<SendMessage>(_onSendMessage);
  }
  
  Future<void> _onUserTyping(
    UserTyping event,
    Emitter<ChatState> emit,
  ) async {
    // Update typing status (max once per second)
    await _chatRepository.updateTypingStatus(true);
  }
  
  Future<void> _onDraftChanged(
    DraftChanged event,
    Emitter<ChatState> emit,
  ) async {
    // Save draft after user stops typing
    await _chatRepository.saveDraft(event.text);
  }
  
  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    // Send immediately (no transformer)
    await _chatRepository.sendMessage(event.message);
  }
}
*/

// ============================================================================
// EXAMPLE 5: Multiple Property Build Optimization
// ============================================================================

/*
class WorkerDashboard extends StatelessWidget {
  const WorkerDashboard({super.key});
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkerBloc, WorkerState>(
      // Only rebuild when specific properties change
      buildWhen: (prev, curr) => BuildOptimization.whenAnyPropertyChanged(
        prev,
        curr,
        [
          (s) => s.isOnline,
          (s) => s.currentJob,
          (s) => s.earningsToday,
        ],
      ),
      builder: (context, state) {
        return Column(
          children: [
            OnlineStatusIndicator(isOnline: state.isOnline),
            CurrentJobCard(job: state.currentJob),
            EarningsCard(earnings: state.earningsToday),
          ],
        );
      },
    );
  }
}

// Or use selective builders for even better performance
class SelectiveWorkerDashboard extends StatelessWidget {
  const SelectiveWorkerDashboard({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Online status - only rebuilds when isOnline changes
        BlocBuilder<WorkerBloc, WorkerState>(
          buildWhen: (prev, curr) => prev.isOnline != curr.isOnline,
          builder: (context, state) => 
            OnlineStatusIndicator(isOnline: state.isOnline),
        ),
        
        // Current job - only rebuilds when currentJob changes
        BlocBuilder<WorkerBloc, WorkerState>(
          buildWhen: (prev, curr) => prev.currentJob != curr.currentJob,
          builder: (context, state) => 
            CurrentJobCard(job: state.currentJob),
        ),
        
        // Earnings - only rebuilds when earningsToday changes
        BlocBuilder<WorkerBloc, WorkerState>(
          buildWhen: (prev, curr) => prev.earningsToday != curr.earningsToday,
          builder: (context, state) => 
            EarningsCard(earnings: state.earningsToday),
        ),
      ],
    );
  }
}
*/

// ============================================================================
// EXAMPLE 6: Using PerformanceUtils.optimizedListView
// ============================================================================

/*
class WorkerListPage extends StatelessWidget {
  const WorkerListPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkersBloc, WorkersState>(
      builder: (context, state) {
        return PerformanceUtils.optimizedListView<Worker>(
          items: state.workers,
          itemBuilder: (context, worker, index) => WorkerListItem(worker: worker),
          onRefresh: () async {
            context.read<WorkersBloc>().add(RefreshWorkers());
          },
          emptyWidget: const EmptyWorkersWidget(),
          separator: const Divider(),
        );
      },
    );
  }
}
*/
