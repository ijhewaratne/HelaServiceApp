import 'package:equatable/equatable.dart';

class UserSession extends Equatable {
  final String id;
  final String platform;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final DateTime? revokedAt;
  final bool isCurrent;

  const UserSession({
    required this.id,
    required this.platform,
    required this.createdAt,
    required this.lastActiveAt,
    this.revokedAt,
    this.isCurrent = false,
  });

  @override
  List<Object?> get props => [
    id,
    platform,
    createdAt,
    lastActiveAt,
    revokedAt,
    isCurrent,
  ];
}
