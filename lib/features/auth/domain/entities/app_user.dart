/// @deprecated Use [User] instead
/// This class is deprecated and will be removed in a future version.
/// Use the consolidated [User] entity from 'user.dart'.
@Deprecated('Use User instead')
class AppUser {
  final String uid;
  final String role;
  final String name;
  final String phone;
  final bool isActive;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.role,
    required this.name,
    required this.phone,
    required this.isActive,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] ?? '',
      role: json['role'] ?? 'customer',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString()) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'role': role,
      'name': name,
      'phone': phone,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
