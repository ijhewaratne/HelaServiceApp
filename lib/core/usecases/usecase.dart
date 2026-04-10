import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../errors/failures.dart';

/// Base usecase interface
/// 
/// [T] - Return type
/// [P] - Parameter type
abstract class UseCase<T, P> {
  Future<Either<Failure, T>> call(P params);
}

/// Usecase with no parameters
abstract class NoParamsUseCase<T> {
  Future<Either<Failure, T>> call();
}

/// Stream usecase for realtime updates
abstract class StreamUseCase<T, P> {
  Stream<Either<Failure, T>> call(P params);
}

/// Parameters wrapper for usecases that don't need parameters
class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
