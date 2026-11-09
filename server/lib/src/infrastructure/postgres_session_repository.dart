import 'package:postgres/postgres.dart';
import '../features/auth_users/session_routes.dart';

/// PostgreSQL adapter for user session lookup.
class PostgresSessionRepository implements SessionRepository {
  /// Creates the adapter.
  const PostgresSessionRepository(this.pool);
  /// Shared PostgreSQL pool.
  final Pool pool;
  /// Resolves active user, branch, role and permission codes by Firebase UID.
  @override
  Future<Map<String, Object?>?> resolve(String uid) async {
    final rows = await pool.execute(Sql.named('SELECT u.id,u.branch_id,r.name,COALESCE(array_agg(rp.permission_code) FILTER (WHERE rp.permission_code IS NOT NULL),ARRAY[]::text[]) FROM users u JOIN roles r ON r.id=u.role_id LEFT JOIN role_permissions rp ON rp.role_id=r.id WHERE u.firebase_uid=@uid AND u.active=true AND u.deleted_at IS NULL GROUP BY u.id,r.name'), parameters: {'uid': uid});
    if (rows.isEmpty) return null;
    return {'userId': rows.first[0].toString(), 'branchId': rows.first[1].toString(), 'role': rows.first[2], 'permissions': rows.first[3]};
  }
}
