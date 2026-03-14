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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      baseRatePerHour: (json['baseRatePerHour'] ?? 0).toDouble(),
      active: json['active'] ?? true,
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
