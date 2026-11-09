import 'package:postgres/postgres.dart';
import '../domain/catalog_permissions.dart';
import '../features/auth_users/session_routes.dart';

/// PostgreSQL adapter for user sessions and branch permission checks.
class PostgresSessionRepository implements SessionRepository, CatalogPermissionRepository {
  /// Creates the adapter.
  const PostgresSessionRepository(this.pool);
  /// Shared PostgreSQL pool.
  final Pool pool;
  /// Resolves active user, branch, role and permission codes by Firebase UID.
  @override
  Future<Map<String, Object?>?> resolve(String uid) async {
    final rows = await pool.execute(Sql.named('SELECT u.id,u.branch_id,r.name,COALESCE(array_agg(rp.permission_code) FILTER (WHERE rp.permission_code IS NOT NULL AND rp.deleted_at IS NULL),ARRAY[]::text[]) FROM users u JOIN branches b ON b.id=u.branch_id AND b.deleted_at IS NULL JOIN roles r ON r.id=u.role_id AND r.deleted_at IS NULL LEFT JOIN role_permissions rp ON rp.role_id=r.id WHERE u.firebase_uid=@uid AND u.active=true AND u.deleted_at IS NULL GROUP BY u.id,r.name'), parameters: {'uid': uid});
    if (rows.isEmpty) return null;
    return {'userId': rows.first[0].toString(), 'branchId': rows.first[1].toString(), 'role': rows.first[2], 'permissions': rows.first[3]};
  }
  /// Checks a permission only for an active user and branch.
  @override
  Future<bool> hasPermission(String uid, String branchId, String permissionCode) async {
    final rows = await pool.execute(Sql.named('SELECT 1 FROM users u JOIN branches b ON b.id=u.branch_id AND b.deleted_at IS NULL JOIN roles r ON r.id=u.role_id AND r.deleted_at IS NULL JOIN role_permissions rp ON rp.role_id=r.id WHERE u.firebase_uid=@uid AND u.branch_id=@branch AND u.active=true AND u.deleted_at IS NULL AND rp.permission_code=@permission AND rp.deleted_at IS NULL LIMIT 1'), parameters: {'uid': uid, 'branch': branchId, 'permission': permissionCode});
    return rows.isNotEmpty;
  }
}
