import 'package:api_client/api_client.dart';
import 'package:core_contracts/core_contracts.dart';
import 'local_cache_and_sync_queue.dart';

/// Coordinates local-first product persistence and remote synchronization.
class CatalogSyncRepository {
  /// Creates a repository using the API client and local queue.
  const CatalogSyncRepository({required this.api, required this.cache, required this.branchId});
  /// Shared API client.
  final ApiClient api;
  /// Local-first storage.
  final LocalCacheAndSyncQueue cache;
  /// Current branch UUID.
  final String branchId;
  /// Saves locally first, then sends the same idempotent operation to the server.
  Future<void> saveProduct(ProductDto product, String operationId) async {
    await cache.saveProductAndQueue(product, operationId);
    final response = await api.send('POST', '/v1/catalog/products', body: product.toJson(), idempotencyKey: operationId, extraHeaders: {'X-Branch-Id': branchId});
    if (response['data'] is Map<String, dynamic>) await cache.markSynced(operationId, product.id);
  }
  /// Loads a branch-scoped cursor page from the API.
  Future<List<ProductDto>> fetchProducts({String? cursor, int limit = 30}) async {
    final query = 'limit=' + limit.toString() + (cursor == null ? '' : '&cursor=' + Uri.encodeQueryComponent(cursor));
    final response = await api.send('GET', '/v1/catalog/products?' + query, extraHeaders: {'X-Branch-Id': branchId});
    return (response['data'] as List<dynamic>).map((item) => ProductDto.fromJson(item as Map<String, dynamic>)).toList();
  }
}
