import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../shared/http_helpers.dart';

/// Public health and app configuration routes.
class HealthConfigRoutes {
  /// Builds public routes.
  Router get router {
    final r = Router();
    r.get('/health', (Request request) => success(request, {'status': 'ok'}));
    r.get('/v1/app-config', (Request request) => success(request, {'apiVersion': '1.0.0', 'minimumClientVersion': '1.0.0'}));
    return r;
  }
}
