import 'package:core_contracts/core_contracts.dart';

/// Domain conflict raised when an idempotency key has another payload.
class IdempotencyConflict implements Exception {
  /// Creates an idempotency conflict.
  const IdempotencyConflict();
}

/// Domain conflict raised when a barcode is already assigned to another product.
class DuplicateBarcode implements Exception {
  /// Creates a duplicate barcode conflict.
  const DuplicateBarcode();
}

/// Domain port for catalog persistence.
abstract interface class CatalogRepository {
  /// Saves a product scoped to a branch with idempotency.
  Future<ProductDto> upsert(String branchId, ProductDto product, String key);
  /// Lists products using cursor pagination.
  Future<List<ProductDto>> list(String branchId, {String? cursor, int limit = 30, String? query});
  /// Finds a product by barcode or scale PLU.
  Future<ProductDto?> lookup(String branchId, String code);
}
