/// Auth Domain Entities
/// 
/// Phase 2: Architecture Refactoring
/// 
/// This barrel file exports all auth-related entities.
/// 
/// Migration Guide:
/// - Replace `UserEntity` with `User` (consolidated entity)
/// - Replace `AppUser` with `User` (consolidated entity)
/// - Old classes are deprecated and will be removed in a future version

// New Consolidated Entity (Recommended)
export 'user.dart';

// Legacy Entities (Deprecated)
export 'user_entity.dart';
export 'app_user.dart';
