import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../shared/http_helpers.dart';

/// Port resolving verified Firebase UIDs to provisioned app users.
abstract interface class SessionRepository {
  /// Returns application session data for an active UID.
  Future<Map<String, Object?>?> resolve(String firebaseUid);
}

/// Firebase-to-application session exchange route.
class SessionRoutes {
  /// Creates session routes.
  const SessionRoutes(this.repository);
  /// Session repository.
  final SessionRepository repository;
  /// Builds the route.
  Router get router {
    final r = Router();
    r.post('/v1/auth/session', _create);
    return r;
  }
  Future<Response> _create(Request request) async {
    final uid = request.context['firebaseUid'] as String?;
    if (uid == null) return failure(request, 401, 'UNAUTHENTICATED', 'يلزم تسجيل الدخول.');
    final session = await repository.resolve(uid);
    if (session == null) return failure(request, 403, 'USER_NOT_PROVISIONED', 'الحساب غير مفعّل في هذا الفرع.');
    return success(request, session);
  }
}
