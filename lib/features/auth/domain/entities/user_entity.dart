/// User entity representing an authenticated user
/// 
/// @deprecated Use [User] instead
/// This class is deprecated and will be removed in a future version.
/// Use the consolidated [User] entity from 'user.dart'.
@Deprecated('Use User instead')
class UserEntity {
  final String id;
  final String phoneNumber;
  final String? email;
  final String? name;
  final String userType; // 'customer', 'worker', 'admin', 'unknown'
  final bool isOnboarded;
  final bool isActive;
  final DateTime? createdAt;

  const UserEntity({
    required this.id,
    required this.phoneNumber,
    this.email,
    this.name,
    this.userType = 'unknown',
    this.isOnboarded = false,
    this.isActive = true,
    this.createdAt,
  });

  UserEntity copyWith({
    String? id,
    String? phoneNumber,
    String? email,
    String? name,
    String? userType,
    bool? isOnboarded,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'email': email,
      'name': name,
      'userType': userType,
      'isOnboarded': isOnboarded,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'],
      name: json['name'],
      userType: json['userType'] ?? 'unknown',
      isOnboarded: json['isOnboarded'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}
