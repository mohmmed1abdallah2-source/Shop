import 'dart:convert';
import 'package:core_contracts/core_contracts.dart';
import 'platform_store_stub.dart' if (dart.library.io) 'platform_store_native.dart' as platform;

/// Platform-neutral local cache and outgoing synchronization queue.
class LocalCacheAndSyncQueue {
  final platform.PlatformStore _store = platform.createPlatformStore();
  /// Initializes native or browser storage.
  Future<void> initialize() => _store.initialize();
  /// Saves product locally and creates a durable pending operation.
  Future<void> saveProductAndQueue(ProductDto product, String operationId) => _store.saveProduct(product.id, jsonEncode(product.toJson()), operationId, DateTime.now().toUtc().toIso8601String());
  /// Loads products from the local cache.
  Future<List<ProductDto>> listProducts() => _store.listProducts();
  /// Reads pending operations for retry.
  Future<List<Map<String, Object?>>> pendingOperations() => _store.pendingOperations();
  /// Marks a queue operation and product synchronized.
  Future<void> markSynced(String operationId, String productId) => _store.markSynced(operationId, productId);
  /// Number of pending operations.
  Future<int> get pendingCount => _store.pendingCount;
  /// Closes platform storage.
  Future<void> close() => _store.close();
}
