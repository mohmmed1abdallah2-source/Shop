/// Port for branch-scoped permission checks.
abstract interface class CatalogPermissionRepository {
  /// Returns whether a verified Firebase user has a permission in the requested branch.
  Future<bool> hasPermission(String firebaseUid, String branchId, String permissionCode);
}
