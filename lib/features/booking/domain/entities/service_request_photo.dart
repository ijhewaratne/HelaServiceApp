import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ServiceRequestPhoto extends Equatable {
  final String id;
  final String requestId;
  final String photoUrl;
  final DateTime uploadedAt;

  const ServiceRequestPhoto({
    required this.id,
    required this.requestId,
    required this.photoUrl,
    required this.uploadedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'requestId': requestId,
        'photoUrl': photoUrl,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
      };

  factory ServiceRequestPhoto.fromJson(Map<String, dynamic> json,
          {String? id}) =>
      ServiceRequestPhoto(
        id: id ?? json['id'] as String? ?? '',
        requestId: json['requestId'] as String? ?? '',
        photoUrl: json['photoUrl'] as String? ?? '',
        uploadedAt: json['uploadedAt'] is Timestamp
            ? (json['uploadedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  factory ServiceRequestPhoto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceRequestPhoto.fromJson(data, id: doc.id);
  }

  @override
  List<Object?> get props => [id, requestId, photoUrl];
}
