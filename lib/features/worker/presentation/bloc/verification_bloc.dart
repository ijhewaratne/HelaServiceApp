import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/worker_verification.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class VerificationEvent extends Equatable {
  const VerificationEvent();
  @override
  List<Object?> get props => [];
}

class LoadVerification extends VerificationEvent {
  final String workerId;
  const LoadVerification(this.workerId);
  @override
  List<Object?> get props => [workerId];
}

class UpdateChecklist extends VerificationEvent {
  final WorkerVerification verification;
  const UpdateChecklist(this.verification);
  @override
  List<Object?> get props => [verification];
}

class PromoteToNextTier extends VerificationEvent {
  final String workerId;
  final String adminId;
  const PromoteToNextTier({required this.workerId, required this.adminId});
  @override
  List<Object?> get props => [workerId, adminId];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class VerificationState extends Equatable {
  const VerificationState();
  @override
  List<Object?> get props => [];
}

class VerificationInitial extends VerificationState {}

class VerificationLoading extends VerificationState {}

class VerificationLoaded extends VerificationState {
  final WorkerVerification verification;
  const VerificationLoaded(this.verification);
  @override
  List<Object?> get props => [verification];
}

class VerificationPromoted extends VerificationState {
  final VerificationTier newTier;
  const VerificationPromoted(this.newTier);
  @override
  List<Object?> get props => [newTier];
}

class VerificationError extends VerificationState {
  final String message;
  const VerificationError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class VerificationBloc extends Bloc<VerificationEvent, VerificationState> {
  final FirebaseFirestore _db;

  VerificationBloc({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance,
        super(VerificationInitial()) {
    on<LoadVerification>(_onLoad);
    on<UpdateChecklist>(_onUpdate);
    on<PromoteToNextTier>(_onPromote);
  }

  DocumentReference<Map<String, dynamic>> _doc(String workerId) =>
      _db.collection('worker_verifications').doc(workerId);

  Future<void> _onLoad(
      LoadVerification event, Emitter<VerificationState> emit) async {
    emit(VerificationLoading());
    try {
      final snap = await _doc(event.workerId).get();
      if (!snap.exists) {
        emit(VerificationLoaded(WorkerVerification.initial(event.workerId)));
        return;
      }
      emit(VerificationLoaded(
          WorkerVerification.fromJson(snap.data()!)));
    } catch (e) {
      emit(VerificationError('Failed to load verification: $e'));
    }
  }

  Future<void> _onUpdate(
      UpdateChecklist event, Emitter<VerificationState> emit) async {
    emit(VerificationLoading());
    try {
      await _doc(event.verification.workerId).set(
        event.verification.toJson(),
        SetOptions(merge: true),
      );
      emit(VerificationLoaded(event.verification));
    } catch (e) {
      emit(VerificationError('Failed to update checklist: $e'));
    }
  }

  Future<void> _onPromote(
      PromoteToNextTier event, Emitter<VerificationState> emit) async {
    emit(VerificationLoading());
    try {
      final snap = await _doc(event.workerId).get();
      if (!snap.exists) {
        emit(const VerificationError('Verification record not found'));
        return;
      }
      final current = WorkerVerification.fromJson(snap.data()!);
      final next = current.nextTier;
      if (next == null) {
        emit(const VerificationError('Worker already at highest tier'));
        return;
      }
      final promoted = current.copyWith(
        tier: next,
        tierGrantedAt: DateTime.now(),
        reviewedBy: event.adminId,
      );
      await _doc(event.workerId).set(promoted.toJson());
      // Mirror tier onto worker document for quick reads
      await _db.collection('workers').doc(event.workerId).update({
        'verificationTier': next.name,
      });
      emit(VerificationPromoted(next));
    } catch (e) {
      emit(VerificationError('Promotion failed: $e'));
    }
  }
}
