import 'dart:convert';
import 'package:core_contracts/core_contracts.dart';
import 'platform_store_stub.dart' if (dart.library.io) 'platform_store_native.dart' as platform;

/// Platform-neutral local cache and outgoing synchronization queue.
class LocalCacheAndSyncQueue {
  final platform.PlatformStore _store = platform.createPlatformStore();
  /// Initializes SQLite on native clients or browser local storage on web.
  Future<void> initialize() => _store.initialize();
  /// Saves product locally and creates a durable pending queue operation.
  Future<void> saveProductAndQueue(ProductDto product, String operationId) => _store.saveProduct(product.id, jsonEncode(product.toJson()), operationId, DateTime.now().toUtc().toIso8601String());
  /// Marks the queue operation and product as synchronized.
  Future<void> markSynced(String operationId, String productId) => _store.markSynced(operationId, productId);
  /// Number of pending operations.
  Future<int> get pendingCount => _store.pendingCount;
  /// Closes platform storage.
  Future<void> close() => _store.close();
}
