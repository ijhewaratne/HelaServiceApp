import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

/// Get wallet use case
class GetWallet implements UseCase<WalletEntity, GetWalletParams> {
  final WalletRepository repository;

  GetWallet(this.repository);

  @override
  Future<Either<Failure, WalletEntity>> call(GetWalletParams params) {
    return repository.getWallet(params.userId);
  }
}

class GetWalletParams extends Equatable {
  final String userId;

  const GetWalletParams(this.userId);

  @override
  List<Object?> get props => [userId];
}
