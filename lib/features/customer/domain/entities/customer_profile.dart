import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'address.dart';

class CustomerProfile extends Equatable {
  final String id;
  final String userId;
  final String fullName;
  final String mobileNumber;
  final String? email;
  final String? profilePhotoUrl;
  final Address? defaultAddress;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CustomerProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.mobileNumber,
    this.email,
    this.profilePhotoUrl,
    this.defaultAddress,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  static final empty = CustomerProfile(
    id: '',
    userId: '',
    fullName: '',
    mobileNumber: '',
    createdAt: DateTime(2000),
  );

  bool get isEmpty => id.isEmpty;

  CustomerProfile copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? mobileNumber,
    String? email,
    String? profilePhotoUrl,
    Address? defaultAddress,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      CustomerProfile(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        fullName: fullName ?? this.fullName,
        mobileNumber: mobileNumber ?? this.mobileNumber,
        email: email ?? this.email,
        profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
        defaultAddress: defaultAddress ?? this.defaultAddress,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'fullName': fullName,
        'mobileNumber': mobileNumber,
        'email': email,
        'profilePhotoUrl': profilePhotoUrl,
        'defaultAddress': defaultAddress?.toJson(),
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  factory CustomerProfile.fromJson(Map<String, dynamic> json, {String? id}) =>
      CustomerProfile(
        id: id ?? json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        mobileNumber: json['mobileNumber'] as String? ?? '',
        email: json['email'] as String?,
        profilePhotoUrl: json['profilePhotoUrl'] as String?,
        defaultAddress: json['defaultAddress'] != null
            ? Address.fromJson(json['defaultAddress'] as Map<String, dynamic>)
            : null,
        notes: json['notes'] as String?,
        createdAt: json['createdAt'] is Timestamp
            ? (json['createdAt'] as Timestamp).toDate()
            : DateTime.parse(
                json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
        updatedAt: json['updatedAt'] != null
            ? (json['updatedAt'] is Timestamp
                ? (json['updatedAt'] as Timestamp).toDate()
                : DateTime.parse(json['updatedAt'] as String))
            : null,
      );

  factory CustomerProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerProfile.fromJson(data, id: doc.id);
  }

  @override
  List<Object?> get props => [id, userId, fullName, mobileNumber];
}
