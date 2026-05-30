import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/service_catalog_item.dart';

abstract class ServiceCatalogRepository {
  /// All active Layer-1 categories
  Future<Either<Failure, List<ServiceCatalogItem>>> getCategories();

  /// All active children of a parent (Layer 2/3/4)
  Future<Either<Failure, List<ServiceCatalogItem>>> getChildren(
      String parentId);

  /// Single item by id
  Future<Either<Failure, ServiceCatalogItem>> getItem(String id);

  /// Popular items across any layer
  Future<Either<Failure, List<ServiceCatalogItem>>> getPopularItems();

  /// Admin: create or update a catalog item
  Future<Either<Failure, ServiceCatalogItem>> upsertItem(
      ServiceCatalogItem item);

  /// Admin: toggle active state
  Future<Either<Failure, void>> setActive(String id, {required bool active});

  /// Live stream of a category tree (for admin catalog management)
  Stream<List<ServiceCatalogItem>> watchAll();
}
