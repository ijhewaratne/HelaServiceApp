import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/feedback.dart';
import '../../domain/repositories/feedback_repository.dart';

/// BLoC for managing feedback operations
class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  final FeedbackRepository _repository;

  FeedbackBloc({required FeedbackRepository repository})
      : _repository = repository,
        super(FeedbackInitial()) {
    on<SubmitFeedback>(_onSubmitFeedback);
    on<LoadUserFeedback>(_onLoadUserFeedback);
    on<LoadFeedbackById>(_onLoadFeedbackById);
    on<DeleteFeedback>(_onDeleteFeedback);
    on<WatchUserFeedback>(_onWatchUserFeedback);
  }

  Future<void> _onSubmitFeedback(
    SubmitFeedback event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(FeedbackSubmitting());

    final result = await _repository.submitFeedback(
      userId: event.userId,
      userType: event.userType,
      category: event.category,
      message: event.message,
      rating: event.rating,
      attachments: event.attachments,
    );

    result.fold(
      (failure) => emit(FeedbackError(message: failure.message)),
      (feedback) => emit(FeedbackSubmitted(feedback: feedback)),
    );
  }

  Future<void> _onLoadUserFeedback(
    LoadUserFeedback event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(FeedbackLoading());

    final result = await _repository.getUserFeedback(event.userId);

    result.fold(
      (failure) => emit(FeedbackError(message: failure.message)),
      (feedbackList) => emit(FeedbackLoaded(feedbackList: feedbackList)),
    );
  }

  Future<void> _onLoadFeedbackById(
    LoadFeedbackById event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(FeedbackLoading());

    final result = await _repository.getFeedbackById(event.feedbackId);

    result.fold(
      (failure) => emit(FeedbackError(message: failure.message)),
      (feedback) => emit(FeedbackDetailLoaded(feedback: feedback)),
    );
  }

  Future<void> _onDeleteFeedback(
    DeleteFeedback event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(FeedbackDeleting());

    final result = await _repository.deleteFeedback(event.feedbackId);

    result.fold(
      (failure) => emit(FeedbackError(message: failure.message)),
      (_) => emit(FeedbackDeleted()),
    );
  }

  Future<void> _onWatchUserFeedback(
    WatchUserFeedback event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(FeedbackLoading());

    await emit.forEach(
      _repository.watchUserFeedback(event.userId),
      onData: (result) => result.fold(
        (failure) => FeedbackError(message: failure.message),
        (feedbackList) => FeedbackLoaded(feedbackList: feedbackList),
      ),
      onError: (error, _) => FeedbackError(message: error.toString()),
    );
  }
}

// ==================== EVENTS ====================

abstract class FeedbackEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Submit new feedback
class SubmitFeedback extends FeedbackEvent {
  final String userId;
  final String userType;
  final FeedbackCategory category;
  final String message;
  final int? rating;
  final List<String>? attachments;

  SubmitFeedback({
    required this.userId,
    required this.userType,
    required this.category,
    required this.message,
    this.rating,
    this.attachments,
  });

  @override
  List<Object?> get props => [userId, userType, category, message, rating, attachments];
}

/// Load all feedback for a user
class LoadUserFeedback extends FeedbackEvent {
  final String userId;

  LoadUserFeedback({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Load single feedback by ID
class LoadFeedbackById extends FeedbackEvent {
  final String feedbackId;

  LoadFeedbackById({required this.feedbackId});

  @override
  List<Object?> get props => [feedbackId];
}

/// Delete feedback
class DeleteFeedback extends FeedbackEvent {
  final String feedbackId;

  DeleteFeedback({required this.feedbackId});

  @override
  List<Object?> get props => [feedbackId];
}

/// Watch user feedback stream
class WatchUserFeedback extends FeedbackEvent {
  final String userId;

  WatchUserFeedback({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// ==================== STATES ====================

abstract class FeedbackState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Initial state
class FeedbackInitial extends FeedbackState {}

/// Loading state
class FeedbackLoading extends FeedbackState {}

/// Submitting feedback
class FeedbackSubmitting extends FeedbackState {}

/// Deleting feedback
class FeedbackDeleting extends FeedbackState {}

/// Feedback successfully submitted
class FeedbackSubmitted extends FeedbackState {
  final Feedback feedback;

  FeedbackSubmitted({required this.feedback});

  @override
  List<Object?> get props => [feedback];
}

/// List of feedback loaded
class FeedbackLoaded extends FeedbackState {
  final List<Feedback> feedbackList;

  FeedbackLoaded({required this.feedbackList});

  @override
  List<Object?> get props => [feedbackList];
}

/// Single feedback detail loaded
class FeedbackDetailLoaded extends FeedbackState {
  final Feedback feedback;

  FeedbackDetailLoaded({required this.feedback});

  @override
  List<Object?> get props => [feedback];
}

/// Feedback deleted
class FeedbackDeleted extends FeedbackState {}

/// Error state
class FeedbackError extends FeedbackState {
  final String message;

  FeedbackError({required this.message});

  @override
  List<Object?> get props => [message];
}
