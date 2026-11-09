import 'dart:convert';
import 'package:core_contracts/core_contracts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Browser storage using persistent local storage through SharedPreferences.
class PlatformStore {
  SharedPreferences? _preferences;
  /// Opens browser local storage.
  Future<void> initialize() async { _preferences = await SharedPreferences.getInstance(); }
  /// Persists product and queue records in local storage.
  Future<void> saveProduct(String id, String payload, String operationId, String createdAt) async {
    final products = _read('shop.products');
    products[id] = {'payload': payload, 'sync_state': 'PENDING'};
    final queue = _read('shop.sync_queue');
    queue[operationId] = {'operation': 'UPSERT_PRODUCT', 'payload': payload, 'state': 'PENDING', 'created_at': createdAt};
    await _preferences!.setString('shop.products', jsonEncode(products));
    await _preferences!.setString('shop.sync_queue', jsonEncode(queue));
  }
  /// Caches a server product without creating an outgoing operation.
  Future<void> cacheProduct(String id, String payload) async {
    final products = _read('shop.products');
    products[id] = {'payload': payload, 'sync_state': 'SYNCED'};
    await _preferences!.setString('shop.products', jsonEncode(products));
  }
  /// Loads all locally cached products.
  Future<List<ProductDto>> listProducts() async => _read('shop.products').values.map((value) => ProductDto.fromJson(jsonDecode((value as Map)['payload'] as String) as Map<String, dynamic>)).toList();
  /// Returns pending operations ordered by creation time.
  Future<List<Map<String, Object?>>> pendingOperations() async => _read('shop.sync_queue').entries.where((e) => e.value is Map && (e.value as Map)['state'] == 'PENDING').map((e) => <String, Object?>{'id': e.key, ...Map<String, Object?>.from(e.value as Map)}).toList()..sort((a,b) => (a['created_at'] as String).compareTo(b['created_at'] as String));
  /// Marks a product synchronized and removes its completed queue row.
  Future<void> markSynced(String operationId, String productId) async {
    final products = _read('shop.products');
    final queue = _read('shop.sync_queue');
    if (products[productId] is Map) (products[productId] as Map)['sync_state'] = 'SYNCED';
    queue.remove(operationId);
    await _preferences!.setString('shop.products', jsonEncode(products));
    await _preferences!.setString('shop.sync_queue', jsonEncode(queue));
  }
  /// Counts pending browser queue entries.
  Future<int> get pendingCount async => (await pendingOperations()).length;
  /// Reads a stored JSON map, returning an empty map for absent or malformed data.
  Map<String, dynamic> _read(String key) {
    final raw = _preferences?.getString(key);
    if (raw == null || raw.isEmpty) return {};
    final value = jsonDecode(raw);
    return value is Map<String, dynamic> ? value : {};
  }
  /// Releases browser storage references.
  Future<void> close() async {}
}

/// Creates browser storage.
PlatformStore createPlatformStore() => PlatformStore();
