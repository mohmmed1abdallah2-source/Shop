import 'dart:convert';
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
  /// Products currently visible in the catalog.
  List<ProductDto> products = [];
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

  /// Restores Firebase session, local products and pending synchronization state.
  Future<void> restoreSession() async {
    try {
      final token = await auth.getIdToken();
      if (token == null) {
        products = await cache.listProducts();
        await refreshQueue();
        notifyListeners();
        return;
      }
      final response = await api.send('POST', '/v1/auth/session');
      session = response['data'] as Map<String, dynamic>;
      connected = true;
      await syncPendingOperations();
      await loadProducts();
    } catch (_) {
      connected = false;
      products = await cache.listProducts();
    }
    await refreshQueue();
    notifyListeners();
  }

  /// Authenticates with Firebase and loads branch permissions and catalog.
  Future<bool> signIn(String email, String password) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await auth.signIn(email, password);
      final response = await api.send('POST', '/v1/auth/session');
      session = response['data'] as Map<String, dynamic>;
      connected = true;
      await syncPendingOperations();
      await loadProducts();
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
    products = [...products.where((p) => p.id != product.id), product];
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

  /// Loads the branch catalog, retaining cached products when the API is unavailable.
  Future<void> loadProducts() async {
    final branch = branchId;
    if (branch == null) return;
    try {
      final response = await api.send('GET', '/v1/catalog/products?limit=100', extraHeaders: {'X-Branch-Id': branch});
      products = (response['data'] as List<dynamic>).map((item) => ProductDto.fromJson(item as Map<String, dynamic>)).toList();
      connected = true;
    } catch (_) {
      connected = false;
      if (products.isEmpty) products = await cache.listProducts();
    }
    notifyListeners();
  }

  /// Replays queued product writes with their original idempotency keys.
  Future<void> syncPendingOperations() async {
    final branch = branchId;
    if (branch == null) return;
    for (final operation in await cache.pendingOperations()) {
      if (operation['operation'] != 'UPSERT_PRODUCT') continue;
      try {
        final id = operation['id'] as String;
        final payload = jsonDecode(operation['payload'] as String) as Map<String, dynamic>;
        final product = ProductDto.fromJson(payload);
        await api.send('POST', '/v1/catalog/products', body: product.toJson(), idempotencyKey: id, extraHeaders: {'X-Branch-Id': branch});
        await cache.markSynced(id, product.id);
      } catch (_) { connected = false; break; }
    }
    await refreshQueue();
    notifyListeners();
  }

  /// Refreshes the number of pending operations.
  Future<void> refreshQueue() async { pending = await cache.pendingCount; notifyListeners(); }
}
