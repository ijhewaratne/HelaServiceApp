import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Four-layer service hierarchy:
/// Layer 1 = Category (e.g. Cleaning)
/// Layer 2 = Sub-type (e.g. Deep Clean)
/// Layer 3 = Package (e.g. 3-bedroom deep clean)
/// Layer 4 = Add-on (e.g. Inside oven cleaning)
enum ServiceLayer { category, subType, package, addOn }

enum PricingModel { hourly, fixed, packageBased }

/// Minimum verification tier required to offer this service
enum MinTierRequired { green, blue, gold, partner }

class ServiceCatalogItem extends Equatable {
  final String id;
  final String name;
  final String? description;
  final ServiceLayer layer;
  final String? parentId; // null for Layer 1; set for Layers 2-4
  final PricingModel pricingModel;
  final double baseRatePerHour;
  final double? fixedPrice; // used when pricingModel = fixed or packageBased
  final int? defaultDurationHours;
  final int? minDurationHours;
  final int? maxDurationHours;
  final MinTierRequired minTier;
  final List<String> requiredEquipment; // tools worker must bring
  final List<String> includedTasks; // checklist shown to customer
  final bool isActive;
  final bool isPopular;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const ServiceCatalogItem({
    required this.id,
    required this.name,
    this.description,
    required this.layer,
    this.parentId,
    this.pricingModel = PricingModel.hourly,
    this.baseRatePerHour = 0.0,
    this.fixedPrice,
    this.defaultDurationHours,
    this.minDurationHours,
    this.maxDurationHours,
    this.minTier = MinTierRequired.green,
    this.requiredEquipment = const [],
    this.includedTasks = const [],
    this.isActive = true,
    this.isPopular = false,
    this.imageUrl,
    this.metadata,
    required this.createdAt,
  });

  bool get isCategory => layer == ServiceLayer.category;
  bool get isAddOn => layer == ServiceLayer.addOn;

  /// Effective price for a given duration (hours)
  double priceForDuration(double hours) {
    switch (pricingModel) {
      case PricingModel.hourly:
        return baseRatePerHour * hours;
      case PricingModel.fixed:
        return fixedPrice ?? baseRatePerHour * hours;
      case PricingModel.packageBased:
        return fixedPrice ?? baseRatePerHour * (defaultDurationHours ?? hours);
    }
  }

  ServiceCatalogItem copyWith({
    String? name,
    String? description,
    PricingModel? pricingModel,
    double? baseRatePerHour,
    double? fixedPrice,
    int? defaultDurationHours,
    int? minDurationHours,
    int? maxDurationHours,
    MinTierRequired? minTier,
    List<String>? requiredEquipment,
    List<String>? includedTasks,
    bool? isActive,
    bool? isPopular,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) => ServiceCatalogItem(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    layer: layer,
    parentId: parentId,
    pricingModel: pricingModel ?? this.pricingModel,
    baseRatePerHour: baseRatePerHour ?? this.baseRatePerHour,
    fixedPrice: fixedPrice ?? this.fixedPrice,
    defaultDurationHours: defaultDurationHours ?? this.defaultDurationHours,
    minDurationHours: minDurationHours ?? this.minDurationHours,
    maxDurationHours: maxDurationHours ?? this.maxDurationHours,
    minTier: minTier ?? this.minTier,
    requiredEquipment: requiredEquipment ?? this.requiredEquipment,
    includedTasks: includedTasks ?? this.includedTasks,
    isActive: isActive ?? this.isActive,
    isPopular: isPopular ?? this.isPopular,
    imageUrl: imageUrl ?? this.imageUrl,
    metadata: metadata ?? this.metadata,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'layer': layer.name,
    'parentId': parentId,
    'pricingModel': pricingModel.name,
    'baseRatePerHour': baseRatePerHour,
    'fixedPrice': fixedPrice,
    'defaultDurationHours': defaultDurationHours,
    'minDurationHours': minDurationHours,
    'maxDurationHours': maxDurationHours,
    'minTier': minTier.name,
    'requiredEquipment': requiredEquipment,
    'includedTasks': includedTasks,
    'isActive': isActive,
    'isPopular': isPopular,
    'imageUrl': imageUrl,
    'metadata': metadata,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory ServiceCatalogItem.fromJson(Map<String, dynamic> json) =>
      ServiceCatalogItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        layer: ServiceLayer.values.firstWhere(
          (e) => e.name == (json['layer'] as String?),
          orElse: () => ServiceLayer.category,
        ),
        parentId: json['parentId'] as String?,
        pricingModel: PricingModel.values.firstWhere(
          (e) => e.name == (json['pricingModel'] as String?),
          orElse: () => PricingModel.hourly,
        ),
        baseRatePerHour: (json['baseRatePerHour'] as num?)?.toDouble() ?? 0.0,
        fixedPrice: (json['fixedPrice'] as num?)?.toDouble(),
        defaultDurationHours: json['defaultDurationHours'] as int?,
        minDurationHours: json['minDurationHours'] as int?,
        maxDurationHours: json['maxDurationHours'] as int?,
        minTier: MinTierRequired.values.firstWhere(
          (e) => e.name == (json['minTier'] as String?),
          orElse: () => MinTierRequired.green,
        ),
        requiredEquipment:
            (json['requiredEquipment'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        includedTasks:
            (json['includedTasks'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        isActive: json['isActive'] as bool? ?? true,
        isPopular: json['isPopular'] as bool? ?? false,
        imageUrl: json['imageUrl'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
        createdAt: json['createdAt'] is Timestamp
            ? (json['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  factory ServiceCatalogItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceCatalogItem.fromJson({...data, 'id': doc.id});
  }

  @override
  List<Object?> get props => [id, name, layer, isActive];
}
