import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'src/application/catalog_use_cases.dart';
import 'src/domain/catalog_permissions.dart';
import 'src/domain/catalog_repository.dart';
import 'src/features/auth_users/session_routes.dart';
import 'src/features/catalog/catalog_routes.dart';
import 'src/features/health_config/routes.dart';
import 'src/infrastructure/firebase_token_verifier.dart';
import 'src/infrastructure/in_memory_catalog_repository.dart';
import 'src/infrastructure/postgres_catalog_repository.dart';
import 'src/infrastructure/postgres_session_repository.dart';
import 'src/shared/auth_middleware.dart';
import 'src/shared/http_helpers.dart';

/// Composes public and authenticated API routes with explicit adapters.
Future<Handler> buildHandler({Pool? pool, FirebaseTokenVerifier? verifier, CatalogPermissionRepository? permissionRepository}) async {
  final CatalogRepository catalog = pool == null ? InMemoryCatalogRepository() : PostgresCatalogRepository(pool);
  final SessionRepository sessions = pool == null ? _NoSessionRepository() : PostgresSessionRepository(pool);
  final CatalogPermissionRepository permissions = pool == null ? permissionRepository ?? _NoPermissionRepository() : PostgresSessionRepository(pool);
  final publicRoutes = HealthConfigRoutes().router;
  final secureRoutes = Router();
  secureRoutes.mount('/v1/auth/', SessionRoutes(sessions).router.call);
  secureRoutes.mount('/v1/catalog/', CatalogRoutes(UpsertProductUseCase(catalog), ListProductsCursorUseCase(catalog), LookupBarcodeOrScaleUseCase(catalog), permissions).router.call);
  final secured = Pipeline().addMiddleware(firebaseAuth(verifier ?? _configuredVerifier())).addHandler(secureRoutes);
  final cascade = Cascade().add(publicRoutes).add(secured).handler;
  return const Pipeline().addMiddleware(_cors()).addMiddleware(requestContext()).addMiddleware(logRequests()).addHandler(cascade);
}

/// Builds a Firebase verifier from deployment configuration.
FirebaseTokenVerifier _configuredVerifier() {
  final projectId = Platform.environment['FIREBASE_PROJECT_ID'];
  if (projectId == null || projectId.isEmpty) return const RejectUnconfiguredFirebaseVerifier();
  return GoogleFirebaseTokenVerifier(projectId: projectId);
}

/// Applies an explicit browser origin allow-list from CORS_ALLOWED_ORIGINS.
Middleware _cors() => (inner) => (request) async {
  final configured = (Platform.environment['CORS_ALLOWED_ORIGINS'] ?? '').split(',').map((value) => value.trim()).where((value) => value.isNotEmpty).toSet();
  final origin = request.headers['origin'];
  final originAllowed = origin == null || configured.contains('*') || configured.contains(origin);
  if (!originAllowed) return Response.forbidden('Origin is not allowed.');
  final headers = <String, String>{'Access-Control-Allow-Headers': 'Authorization, Content-Type, X-Request-Id, Idempotency-Key, X-Branch-Id', 'Access-Control-Allow-Methods': 'GET, POST, OPTIONS', 'Vary': 'Origin'};
  if (origin != null) headers['Access-Control-Allow-Origin'] = configured.contains('*') ? '*' : origin;
  if (request.method == 'OPTIONS') return Response.ok('', headers: headers);
  final response = await inner(request);
  return response.change(headers: {...headers, ...response.headers});
};

/// Session repository used when no PostgreSQL connection is configured.
class _NoSessionRepository implements SessionRepository {
  /// Denies all sessions when database-backed user provisioning is unavailable.
  @override
  Future<Map<String, Object?>?> resolve(String firebaseUid) async => null;
}

/// Permission repository used when no PostgreSQL connection is configured.
class _NoPermissionRepository implements CatalogPermissionRepository {
  /// Denies all branch permissions by default.
  @override
  Future<bool> hasPermission(String firebaseUid, String branchId, String permissionCode) async => false;
}

/// Starts the HTTP server using DATABASE_URL, FIREBASE_PROJECT_ID, CORS_ALLOWED_ORIGINS and PORT.
Future<void> startServer() async {
  final databaseUrl = Platform.environment['DATABASE_URL'];
  final pool = databaseUrl == null || databaseUrl.isEmpty ? null : Pool.withUrl(databaseUrl);
  final handler = await buildHandler(pool: pool);
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final server = await io.serve(handler, '0.0.0.0', port);
  // ignore: avoid_print
  print('Shop API listening on port ' + server.port.toString());
}
