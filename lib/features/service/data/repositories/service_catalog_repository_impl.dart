import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/service_catalog_item.dart';
import '../../domain/repositories/service_catalog_repository.dart';

class ServiceCatalogRepositoryImpl implements ServiceCatalogRepository {
  final FirebaseFirestore _db;

  ServiceCatalogRepositoryImpl({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('service_catalog');

  @override
  Future<Either<Failure, List<ServiceCatalogItem>>> getCategories() async {
    try {
      final snap = await _col
          .where('layer', isEqualTo: 'category')
          .where('isActive', isEqualTo: true)
          .get();
      return Right(snap.docs.map(ServiceCatalogItem.fromFirestore).toList());
    } catch (e) {
      return Left(ServerFailure('Failed to load categories: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ServiceCatalogItem>>> getChildren(
    String parentId,
  ) async {
    try {
      final snap = await _col
          .where('parentId', isEqualTo: parentId)
          .where('isActive', isEqualTo: true)
          .get();
      return Right(snap.docs.map(ServiceCatalogItem.fromFirestore).toList());
    } catch (e) {
      return Left(ServerFailure('Failed to load children: $e'));
    }
  }

  @override
  Future<Either<Failure, ServiceCatalogItem>> getItem(String id) async {
    try {
      final doc = await _col.doc(id).get();
      if (!doc.exists) return Left(NotFoundFailure('Service item not found'));
      return Right(ServiceCatalogItem.fromFirestore(doc));
    } catch (e) {
      return Left(ServerFailure('Failed to get item: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ServiceCatalogItem>>> getPopularItems() async {
    try {
      final snap = await _col
          .where('isActive', isEqualTo: true)
          .where('isPopular', isEqualTo: true)
          .get();
      return Right(snap.docs.map(ServiceCatalogItem.fromFirestore).toList());
    } catch (e) {
      return Left(ServerFailure('Failed to load popular items: $e'));
    }
  }

  @override
  Future<Either<Failure, ServiceCatalogItem>> upsertItem(
    ServiceCatalogItem item,
  ) async {
    try {
      final ref = item.id.isEmpty ? _col.doc() : _col.doc(item.id);
      final updated = item.id.isEmpty ? item.copyWith() : item;
      await ref.set({...updated.toJson(), 'id': ref.id});
      final doc = await ref.get();
      return Right(ServiceCatalogItem.fromFirestore(doc));
    } catch (e) {
      return Left(ServerFailure('Failed to save catalog item: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> setActive(
    String id, {
    required bool active,
  }) async {
    try {
      await _col.doc(id).update({'isActive': active});
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to update active state: $e'));
    }
  }

  @override
  Stream<List<ServiceCatalogItem>> watchAll() {
    return _col
        .orderBy('layer')
        .orderBy('name')
        .snapshots()
        .map(
          (snap) => snap.docs.map(ServiceCatalogItem.fromFirestore).toList(),
        );
  }
}
