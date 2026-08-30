import 'package:equatable/equatable.dart';

enum ConsentDocumentType { terms, privacy }

/// A single, immutable record that a user accepted a specific version of a
/// legal document at a specific time. Never updated or deleted — a new
/// document version requires a new record, not an edit to an old one.
class ConsentRecord extends Equatable {
  final String id;
  final String userId;
  final ConsentDocumentType documentType;
  final String version;
  final DateTime acceptedAt;

  const ConsentRecord({
    required this.id,
    required this.userId,
    required this.documentType,
    required this.version,
    required this.acceptedAt,
  });

  @override
  List<Object?> get props => [id, userId, documentType, version, acceptedAt];
}
