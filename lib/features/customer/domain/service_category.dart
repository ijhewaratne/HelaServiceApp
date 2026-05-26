class ServiceCategory {
  final String id;
  final String name;
  final double baseRatePerHour;
  final bool active;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.baseRatePerHour,
    required this.active,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      baseRatePerHour: (json['baseRatePerHour'] as num?)?.toDouble() ?? 0.0,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseRatePerHour': baseRatePerHour,
      'active': active,
    };
  }
}
