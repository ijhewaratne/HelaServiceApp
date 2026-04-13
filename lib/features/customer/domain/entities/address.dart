import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Address type enumeration
enum AddressType { home, work, other }

/// Address entity for customer addresses
/// 
/// Phase 2: Architecture Refactoring - Replaces Map<String, dynamic>
class Address extends Equatable {
  final String id;
  final String customerId;
  final String label; // e.g., "Home", "Office"
  final AddressType type;
  final String houseNumber;
  final String? street;
  final String? landmark;
  final String city;
  final String district;
  final String zoneId;
  final double latitude;
  final double longitude;
  final String? geohash;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Address({
    required this.id,
    required this.customerId,
    required this.label,
    this.type = AddressType.home,
    required this.houseNumber,
    this.street,
    this.landmark,
    required this.city,
    required this.district,
    required this.zoneId,
    required this.latitude,
    required this.longitude,
    this.geohash,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Empty address (for initial states)
  static const empty = Address(
    id: '',
    customerId: '',
    label: '',
    houseNumber: '',
    city: '',
    district: '',
    zoneId: '',
    latitude: 0.0,
    longitude: 0.0,
    createdAt: null, // ignore: avoid_field_initializing_in_const
  );

  /// Check if address is empty
  bool get isEmpty => id.isEmpty;

  /// Get full address string
  String get fullAddress {
    final parts = <String>[
      houseNumber,
      if (street != null && street!.isNotEmpty) street!,
      if (landmark != null && landmark!.isNotEmpty) 'Near $landmark',
      city,
      district,
    ];
    return parts.join(', ');
  }

  /// Get short address (for lists)
  String get shortAddress => '$houseNumber, $city';

  /// Create a copy with updated fields
  Address copyWith({
    String? id,
    String? customerId,
    String? label,
    AddressType? type,
    String? houseNumber,
    String? street,
    String? landmark,
    String? city,
    String? district,
    String? zoneId,
    double? latitude,
    double? longitude,
    String? geohash,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      label: label ?? this.label,
      type: type ?? this.type,
      houseNumber: houseNumber ?? this.houseNumber,
      street: street ?? this.street,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      district: district ?? this.district,
      zoneId: zoneId ?? this.zoneId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geohash: geohash ?? this.geohash,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'label': label,
      'type': type.name,
      'houseNumber': houseNumber,
      'street': street,
      'landmark': landmark,
      'city': city,
      'district': district,
      'zoneId': zoneId,
      'latitude': latitude,
      'longitude': longitude,
      'geohash': geohash,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Create from Firestore document
  factory Address.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Address.fromJson(data, id: doc.id);
  }

  /// Create from JSON
  factory Address.fromJson(Map<String, dynamic> json, {String? id}) {
    return Address(
      id: id ?? json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      label: json['label'] ?? '',
      type: _parseAddressType(json['type']),
      houseNumber: json['houseNumber'] ?? '',
      street: json['street'],
      landmark: json['landmark'],
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      zoneId: json['zoneId'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      geohash: json['geohash'],
      isDefault: json['isDefault'] ?? false,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is Timestamp
              ? (json['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(json['updatedAt']))
          : null,
    );
  }

  static AddressType _parseAddressType(String? type) {
    switch (type) {
      case 'work':
        return AddressType.work;
      case 'other':
        return AddressType.other;
      default:
        return AddressType.home;
    }
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        houseNumber,
        city,
        zoneId,
      ];

  @override
  String toString() => 'Address($label: $shortAddress)';
}

/// Extension for address utilities
extension AddressX on Address {
  /// Calculate distance from another address (Haversine formula)
  double distanceFrom(double lat, double lng) {
    const earthRadius = 6371; // km
    final dLat = _toRadians(lat - latitude);
    final dLng = _toRadians(lng - longitude);
    final a = 
        (dLat / 2).sin() * (dLat / 2).sin() +
        _toRadians(latitude).cos() * 
        _toRadians(lat).cos() * 
        (dLng / 2).sin() * (dLng / 2).sin();
    final c = 2 * (a.sqrt()).atan2((1 - a).sqrt(), a.sqrt());
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * 3.14159265359 / 180;
}

/// Math extensions for double
extension _DoubleMath on double {
  double sin() => this.sin();
  double cos() => this.cos();
  double sqrt() => this.sqrt();
  double atan2(double y, double x) => this.atan2(y, x);
}
