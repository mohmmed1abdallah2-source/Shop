import 'dart:convert';
import 'package:api_client/api_client.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../auth/firebase_auth_adapter.dart';
import '../data/local_cache_and_sync_queue.dart';

/// Coordinates Firebase authentication, cached offline session and catalog synchronization.
class AuthAndCatalogProvider extends ChangeNotifier {
  /// Creates the application provider.
  AuthAndCatalogProvider({required this.cache, required this.auth, required this.api, FlutterSecureStorage? secureStorage}) : _secureStorage = secureStorage ?? const FlutterSecureStorage();
  /// Local cache and outgoing queue.
  final LocalCacheAndSyncQueue cache;
  /// Firebase Authentication adapter.
  final FirebaseAuthAdapter auth;
  /// Shared authenticated API client.
  final ApiClient api;
  final FlutterSecureStorage _secureStorage;
  static const _sessionKey = 'shop.application.session';
  /// Provisioned application session returned by the server or securely cached for offline use.
  Map<String, dynamic>? session;
  /// Products currently visible in the catalog.
  List<ProductDto> products = [];
  /// Product UUIDs with operations awaiting synchronization.
  Set<String> pendingProductIds = {};
  String? _catalogEtag;
  /// Whether server connectivity is currently available.
  bool connected = false;
  /// Whether authentication is in progress.
  bool busy = false;
  /// Safe error message for the login form.
  String? errorMessage;
  /// Number of operations awaiting synchronization.
  int pending = 0;
  /// Active branch UUID from the verified or securely cached session.
  String? get branchId => session?['branchId'] as String?;
  /// Checks a permission in the active server-issued or cached session.
  bool hasPermission(String code) => session?['permissions'] is List && (session!['permissions'] as List).contains(code);

  /// Restores a recent secure offline session and attempts server revalidation.
  Future<void> restoreSession() async {
    try {
      final rawSession = await _secureStorage.read(key: _sessionKey);
      if (rawSession != null) {
        final cached = jsonDecode(rawSession) as Map<String, dynamic>;
        final cachedAt = DateTime.tryParse(cached['cachedAt'] as String? ?? '');
        final cacheAge = cachedAt == null ? null : DateTime.now().difference(cachedAt);
        if (cacheAge != null && cacheAge >= Duration.zero && cacheAge <= const Duration(days: 7)) {
          session = cached['session'] as Map<String, dynamic>;
        } else {
          await _secureStorage.delete(key: _sessionKey);
        }
      }
      products = await cache.listProducts();
      final token = await auth.getIdToken();
      if (token == null) {
        connected = false;
        await refreshQueue();
        notifyListeners();
        return;
      }
      final response = await api.send('POST', '/v1/auth/session');
      session = response['data'] as Map<String, dynamic>;
      await _persistSession();
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
      await _persistSession();
      connected = true;
      await syncPendingOperations();
      await loadProducts();
      await refreshQueue();
      return true;
    } on FirebaseAuthException catch (error) {
      errorMessage = error.message;
      session = null;
      await _secureStorage.delete(key: _sessionKey);
      await auth.signOut();
      return false;
    } on ApiClientException catch (error) {
      final serverError = error.payload['error'];
      errorMessage = serverError is Map<String, dynamic> ? serverError['message'] as String? : 'تعذر إنشاء جلسة النظام.';
      session = null;
      await _secureStorage.delete(key: _sessionKey);
      await auth.signOut();
      return false;
    } catch (_) {
      errorMessage = 'تعذر الاتصال بالخادم أو إنشاء الجلسة.';
      session = null;
      await _secureStorage.delete(key: _sessionKey);
      await auth.signOut();
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Signs out and removes both Firebase and application session tokens.
  Future<void> signOut() async {
    await auth.signOut();
    await _secureStorage.delete(key: _sessionKey);
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

  /// Loads the branch catalog and caches each server product for offline reading.
  Future<void> loadProducts() async {
    final branch = branchId;
    if (branch == null) return;
    try {
      final loaded = <ProductDto>[];
      String? cursor;
      do {
        final query = 'limit=100' + (cursor == null ? '' : '&cursor=' + Uri.encodeQueryComponent(cursor));
        final headers = <String, String>{'X-Branch-Id': branch};
        if (cursor == null && products.isNotEmpty && products.length < 100 && _catalogEtag != null) headers['If-None-Match'] = _catalogEtag!;
        final response = await api.send('GET', '/v1/catalog/products?' + query, extraHeaders: headers);
        if (response['_notModified'] == true) {
          _catalogEtag = response['_etag'] as String? ?? _catalogEtag;
          connected = true;
          notifyListeners();
          return;
        }
        loaded.addAll((response['data'] as List<dynamic>).map((item) => ProductDto.fromJson(item as Map<String, dynamic>)));
        final meta = response['meta'] as Map<String, dynamic>?;
        cursor = meta?['nextCursor'] as String?;
        if (cursor == null && loaded.length < 100) _catalogEtag = response['_etag'] as String?;
        else _catalogEtag = null;
      } while (cursor != null && loaded.length < 10000);
      products = loaded;
      await Future.wait(products.map(cache.cacheProductSnapshot));
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

  /// Refreshes pending count and pending product identifiers from the durable queue.
  Future<void> refreshQueue() async {
    final operations = await cache.pendingOperations();
    pending = operations.length;
    pendingProductIds = operations.map((operation) {
      try { return (jsonDecode(operation['payload'] as String) as Map<String, dynamic>)['id'] as String?; } catch (_) { return null; }
    }).whereType<String>().toSet();
    notifyListeners();
  }

  /// Stores the current server session with a bounded offline validity window.
  Future<void> _persistSession() async => _secureStorage.write(key: _sessionKey, value: jsonEncode({'session': session, 'cachedAt': DateTime.now().toUtc().toIso8601String()}));
}
