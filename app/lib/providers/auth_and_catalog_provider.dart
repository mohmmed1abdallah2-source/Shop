import 'package:api_client/api_client.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../auth/firebase_auth_adapter.dart';
import '../data/local_cache_and_sync_queue.dart';

/// Coordinates Firebase authentication, server session and local-first catalog writes.
class AuthAndCatalogProvider extends ChangeNotifier {
  /// Creates the application provider.
  AuthAndCatalogProvider({required this.cache, required this.auth, required this.api});
  /// Local cache and outgoing queue.
  final LocalCacheAndSyncQueue cache;
  /// Firebase Authentication adapter.
  final FirebaseAuthAdapter auth;
  /// Shared authenticated API client.
  final ApiClient api;
  /// Provisioned application session returned by the server.
  Map<String, dynamic>? session;
  /// Whether server connectivity is currently available.
  bool connected = false;
  /// Whether authentication is in progress.
  bool busy = false;
  /// Safe error message for the login form.
  String? errorMessage;
  /// Number of operations awaiting synchronization.
  int pending = 0;
  /// Active branch UUID from the verified server session.
  String? get branchId => session?['branchId'] as String?;

  /// Restores a prior Firebase session and exchanges its token with the API.
  Future<void> restoreSession() async {
    final token = await auth.getIdToken();
    if (token == null) return;
    try {
      final response = await api.send('POST', '/v1/auth/session');
      session = response['data'] as Map<String, dynamic>;
      connected = true;
    } catch (_) { connected = false; }
    await refreshQueue();
    notifyListeners();
  }

  /// Authenticates with Firebase and loads provisioned branch permissions.
  Future<bool> signIn(String email, String password) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await auth.signIn(email, password);
      final response = await api.send('POST', '/v1/auth/session');
      session = response['data'] as Map<String, dynamic>;
      connected = true;
      await refreshQueue();
      return true;
    } on FirebaseAuthException catch (error) {
      errorMessage = error.message;
      await auth.signOut();
      return false;
    } on ApiClientException catch (error) {
      final serverError = error.payload['error'];
      errorMessage = serverError is Map<String, dynamic> ? serverError['message'] as String? : 'تعذر إنشاء جلسة النظام.';
      await auth.signOut();
      return false;
    } catch (_) {
      errorMessage = 'تعذر الاتصال بالخادم أو إنشاء الجلسة.';
      await auth.signOut();
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Signs out and clears the Firebase refresh token.
  Future<void> signOut() async {
    await auth.signOut();
    session = null;
    connected = false;
    notifyListeners();
  }

  /// Saves locally first, then attempts an idempotent server write.
  Future<bool> saveProduct(ProductDto product) async {
    final branch = branchId;
    if (branch == null) throw StateError('لا توجد جلسة مرتبطة بفرع.');
    final operationId = const Uuid().v4();
    await cache.saveProductAndQueue(product, operationId);
    await refreshQueue();
    try {
      await api.send('POST', '/v1/catalog/products', body: product.toJson(), idempotencyKey: operationId, extraHeaders: {'X-Branch-Id': branch});
      await cache.markSynced(operationId, product.id);
      connected = true;
      await refreshQueue();
      notifyListeners();
      return true;
    } catch (_) {
      connected = false;
      notifyListeners();
      return false;
    }
  }

  /// Refreshes the number of pending operations.
  Future<void> refreshQueue() async { pending = await cache.pendingCount; notifyListeners(); }
}
