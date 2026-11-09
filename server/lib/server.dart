import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'src/application/catalog_use_cases.dart';
import 'src/features/auth_users/session_routes.dart';
import 'src/features/catalog/catalog_routes.dart';
import 'src/features/health_config/routes.dart';
import 'src/infrastructure/firebase_token_verifier.dart';
import 'src/infrastructure/in_memory_catalog_repository.dart';
import 'src/infrastructure/postgres_catalog_repository.dart';
import 'src/infrastructure/postgres_session_repository.dart';
import 'src/shared/auth_middleware.dart';
import 'src/shared/http_helpers.dart';

/// Composes the API from public routes and authenticated application routes.
Future<Handler> buildHandler({Pool? pool, FirebaseTokenVerifier? verifier}) async {
  final catalog = pool == null ? InMemoryCatalogRepository() : PostgresCatalogRepository(pool);
  final publicRoutes = HealthConfigRoutes().router;
  final secureRoutes = Router();
  secureRoutes.mount('/v1/auth/', SessionRoutes(pool == null ? _NoSessionRepository() : PostgresSessionRepository(pool)).router.call);
  secureRoutes.mount('/v1/catalog/', CatalogRoutes(UpsertProductUseCase(catalog), ListProductsCursorUseCase(catalog), LookupBarcodeOrScaleUseCase(catalog)).router.call);
  final secured = Pipeline().addMiddleware(firebaseAuth(verifier ?? _configuredVerifier())).addHandler(secureRoutes);
  final cascade = Cascade().add(publicRoutes).add(secured).handler;
  return const Pipeline().addMiddleware(_cors()).addMiddleware(requestContext()).addMiddleware(logRequests()).addHandler(cascade);
}

FirebaseTokenVerifier _configuredVerifier() {
  final projectId = Platform.environment['FIREBASE_PROJECT_ID'];
  if (projectId == null || projectId.isEmpty) return const RejectUnconfiguredFirebaseVerifier();
  return GoogleFirebaseTokenVerifier(projectId: projectId);
}

Middleware _cors() => (inner) => (request) async {
  const headers = {'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'Authorization, Content-Type, X-Request-Id, Idempotency-Key, X-Branch-Id', 'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'};
  if (request.method == 'OPTIONS') return Response.ok('', headers: headers);
  final response = await inner(request);
  return response.change(headers: {...headers, ...response.headers});
};

/// Session repository used when no database is configured; it denies all sessions.
class _NoSessionRepository implements SessionRepository {
  /// Denies all unprovisioned sessions.
  @override
  Future<Map<String, Object?>?> resolve(String firebaseUid) async => null;
}

/// Starts the HTTP server using environment-provided infrastructure.
Future<void> startServer() async {
  final databaseUrl = Platform.environment['DATABASE_URL'];
  final pool = databaseUrl == null || databaseUrl.isEmpty ? null : Pool.withUrl(databaseUrl);
  final handler = await buildHandler(pool: pool);
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final server = await io.serve(handler, '0.0.0.0', port);
  // ignore: avoid_print
  print('Shop API listening on port ' + server.port.toString());
}
