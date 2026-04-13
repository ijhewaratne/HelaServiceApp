import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

/// Top up wallet use case
class TopUpWallet implements UseCase<WalletEntity, TopUpWalletParams> {
  final WalletRepository repository;

  TopUpWallet(this.repository);

  @override
  Future<Either<Failure, WalletEntity>> call(TopUpWalletParams params) {
    return repository.topUp(
      userId: params.userId,
      amount: params.amount,
      method: params.method,
      description: params.description,
    );
  }
}

class TopUpWalletParams extends Equatable {
  final String userId;
  final double amount;
  final WalletPaymentMethod method;
  final String? description;

  const TopUpWalletParams({
    required this.userId,
    required this.amount,
    required this.method,
    this.description,
  });

  @override
  List<Object?> get props => [userId, amount, method];
}
