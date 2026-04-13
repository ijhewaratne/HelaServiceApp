import 'package:equatable/equatable.dart';

/// User type enumeration
enum UserType { customer, worker, admin, unknown }

/// User account status
enum UserStatus { active, inactive, suspended, pendingVerification }

/// Consolidated User entity for authentication
/// 
/// Phase 2: Architecture Refactoring - Consolidates AppUser and UserEntity
/// 
/// This is the single source of truth for user identity across the app.
class User extends Equatable {
  final String uid;
  final String phoneNumber;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final UserType userType;
  final UserStatus status;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isOnboarded;
  final DateTime? createdAt;
  final DateTime? lastSignInAt;
  final Map<String, dynamic>? metadata;

  const User({
    required this.uid,
    required this.phoneNumber,
    this.email,
    this.displayName,
    this.photoUrl,
    this.userType = UserType.unknown,
    this.status = UserStatus.pendingVerification,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.isOnboarded = false,
    this.createdAt,
    this.lastSignInAt,
    this.metadata,
  });

  /// Empty user (for initial states)
  static const empty = User(
    uid: '',
    phoneNumber: '',
    userType: UserType.unknown,
    status: UserStatus.pendingVerification,
  );

  /// Check if user is empty
  bool get isEmpty => uid.isEmpty;

  /// Check if user is not empty
  bool get isNotEmpty => !isEmpty;

  /// Check if user is a customer
  bool get isCustomer => userType == UserType.customer;

  /// Check if user is a worker
  bool get isWorker => userType == UserType.worker;

  /// Check if user is an admin
  bool get isAdmin => userType == UserType.admin;

  /// Check if user can access the app
  bool get canAccessApp => status == UserStatus.active && isOnboarded;

  /// Create a copy with updated fields
  User copyWith({
    String? uid,
    String? phoneNumber,
    String? email,
    String? displayName,
    String? photoUrl,
    UserType? userType,
    UserStatus? status,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isOnboarded,
    DateTime? createdAt,
    DateTime? lastSignInAt,
    Map<String, dynamic>? metadata,
  }) {
    return User(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      userType: userType ?? this.userType,
      status: status ?? this.status,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'userType': userType.name,
      'status': status.name,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'isOnboarded': isOnboarded,
      'createdAt': createdAt?.toIso8601String(),
      'lastSignInAt': lastSignInAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'],
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      userType: _parseUserType(json['userType']),
      status: _parseUserStatus(json['status']),
      isEmailVerified: json['isEmailVerified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      isOnboarded: json['isOnboarded'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      lastSignInAt: json['lastSignInAt'] != null
          ? DateTime.parse(json['lastSignInAt'])
          : null,
      metadata: json['metadata'],
    );
  }

  /// Create from Firebase User
  factory User.fromFirebaseUser(firebaseUser, {UserType? userType}) {
    return User(
      uid: firebaseUser.uid ?? '',
      phoneNumber: firebaseUser.phoneNumber ?? '',
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      userType: userType ?? UserType.unknown,
      status: UserStatus.active,
      isEmailVerified: firebaseUser.emailVerified ?? false,
      isPhoneVerified: firebaseUser.phoneNumber != null,
      createdAt: firebaseUser.metadata?.creationTime,
      lastSignInAt: firebaseUser.metadata?.lastSignInTime,
    );
  }

  static UserType _parseUserType(String? type) {
    switch (type) {
      case 'customer':
        return UserType.customer;
      case 'worker':
        return UserType.worker;
      case 'admin':
        return UserType.admin;
      default:
        return UserType.unknown;
    }
  }

  static UserStatus _parseUserStatus(String? status) {
    switch (status) {
      case 'active':
        return UserStatus.active;
      case 'inactive':
        return UserStatus.inactive;
      case 'suspended':
        return UserStatus.suspended;
      default:
        return UserStatus.pendingVerification;
    }
  }

  @override
  List<Object?> get props => [
        uid,
        phoneNumber,
        email,
        userType,
        status,
        isOnboarded,
      ];

  @override
  String toString() => 'User(uid: $uid, type: ${userType.name}, status: ${status.name})';
}

/// Extension methods for User
extension UserX on User {
  /// Get initials from display name
  String get initials {
    if (displayName == null || displayName!.isEmpty) return '';
    final parts = displayName!.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Get formatted phone number
  String get formattedPhone {
    if (phoneNumber.isEmpty) return '';
    if (phoneNumber.startsWith('+94')) {
      // +94 77 123 4567
      return '+94 ${phoneNumber.substring(3, 5)} ${phoneNumber.substring(5, 8)} ${phoneNumber.substring(8)}';
    }
    return phoneNumber;
  }
}
