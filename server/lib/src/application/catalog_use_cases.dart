import 'package:core_contracts/core_contracts.dart';
import '../domain/catalog_repository.dart';

/// Validates and stores products.
class UpsertProductUseCase {
  /// Creates the use case.
  const UpsertProductUseCase(this.repository);
  /// Catalog repository port.
  final CatalogRepository repository;
  /// Validates and persists the product.
  Future<ProductDto> call(String branch, ProductDto product, String key) {
    if (product.name.trim().isEmpty || product.sku.trim().isEmpty || product.units.isEmpty) throw ArgumentError('اسم المنتج والرمز ووحدة بيع مطلوبة.');
    if (product.units.any((u) => u.barcode.trim().isEmpty || u.retailPrice < 0 || u.wholesalePrice < 0)) throw ArgumentError('بيانات الباركود أو السعر غير صالحة.');
    return repository.upsert(branch, product, key);
  }
}

/// Cursor-paginated product listing use case.
class ListProductsCursorUseCase {
  /// Creates the use case.
  const ListProductsCursorUseCase(this.repository);
  /// Catalog repository port.
  final CatalogRepository repository;
  /// Lists products with a bounded page size.
  Future<List<ProductDto>> call(String branch, {String? cursor, int limit = 30, String? query}) {
    if (limit < 1 || limit > 100) throw RangeError.range(limit, 1, 100);
    return repository.list(branch, cursor: cursor, limit: limit, query: query);
  }
}

/// Barcode and scale PLU lookup use case.
class LookupBarcodeOrScaleUseCase {
  /// Creates the use case.
  const LookupBarcodeOrScaleUseCase(this.repository);
  /// Catalog repository port.
  final CatalogRepository repository;
  /// Finds a product by scanned code.
  Future<ProductDto?> call(String branch, String code) => repository.lookup(branch, code.trim());
}
