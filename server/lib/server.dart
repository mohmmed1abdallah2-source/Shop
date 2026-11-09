import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'src/application/catalog_use_cases.dart';
import 'src/features/catalog/catalog_routes.dart';
import 'src/features/health_config/routes.dart';
import 'src/infrastructure/in_memory_catalog_repository.dart';
import 'src/shared/auth_middleware.dart';
import 'src/shared/http_helpers.dart';

/// Composes HTTP routes with infrastructure adapters.
Future<Handler> buildHandler({FirebaseTokenVerifier? verifier}) async {
  final catalog = InMemoryCatalogRepository();
  final router = Router();
  router.mount('/', HealthConfigRoutes().router.call);
  router.mount('/v1/catalog/', CatalogRoutes(UpsertProductUseCase(catalog), ListProductsCursorUseCase(catalog), LookupBarcodeOrScaleUseCase(catalog)).router.call);
  final api = const Pipeline().addMiddleware(logRequests()).addMiddleware(requestContext()).addHandler(router);
  return Pipeline().addMiddleware(firebaseAuth(verifier ?? const RejectUnconfiguredFirebaseVerifier())).addHandler(api);
}

/// Starts the HTTP server.
Future<void> startServer() async {
  final handler = await buildHandler();
  final server = await io.serve(handler, '0.0.0.0', int.tryParse(const String.fromEnvironment('PORT', defaultValue: '8080')) ?? 8080);
  // ignore: avoid_print
  print('Shop API listening on port ' + server.port.toString());
}
