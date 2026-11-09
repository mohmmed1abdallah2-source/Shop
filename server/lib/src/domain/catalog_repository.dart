import 'package:core_contracts/core_contracts.dart';

/// Domain port for catalog persistence.
abstract interface class CatalogRepository {
  /// Saves a product scoped to a branch with idempotency.
  Future<ProductDto> upsert(String branchId, ProductDto product, String key);
  /// Lists products with cursor pagination.
  Future<List<ProductDto>> list(String branchId, {String? cursor, int limit = 30, String? query});
  /// Finds a product by barcode or scale PLU.
  Future<ProductDto?> lookup(String branchId, String code);
}
