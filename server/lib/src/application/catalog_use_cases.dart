import 'package:core_contracts/core_contracts.dart';
import '../domain/catalog_repository.dart';

/// Validates and stores products.
class UpsertProductUseCase {
  /// Creates the use case.
  const UpsertProductUseCase(this.repository);
  /// Catalog repository port.
  final CatalogRepository repository;
  /// Validates identifiers, product type, units and prices before persistence.
  Future<ProductDto> call(String branch, ProductDto product, String key) {
    final uuidPattern = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$');
    if (!uuidPattern.hasMatch(product.id) || (product.categoryId != null && !uuidPattern.hasMatch(product.categoryId!))) throw ArgumentError('معرّف المنتج أو التصنيف غير صالح.');
    if (product.name.trim().isEmpty || product.sku.trim().isEmpty || product.units.isEmpty) throw ArgumentError('اسم المنتج والرمز ووحدة بيع مطلوبة.');
    if (product.kind != 'numeric' && product.kind != 'weighted') throw ArgumentError('نوع المنتج غير صالح.');
    if (product.kind == 'weighted' && (product.scalePluCode == null || product.scalePluCode!.trim().isEmpty)) throw ArgumentError('رمز الميزان مطلوب للمنتج الموزون.');
    final barcodes = <String>{};
    final unitNames = <String>{};
    for (final unit in product.units) {
      if (unit.unitName.trim().isEmpty || unit.barcode.trim().isEmpty || !unitNames.add(unit.unitName) || !barcodes.add(unit.barcode)) throw ArgumentError('اسم الوحدة والباركود مطلوبان ويجب ألا يتكررا.');
      if (!unit.retailPrice.isFinite || !unit.wholesalePrice.isFinite || unit.retailPrice < 0 || unit.wholesalePrice < 0) throw ArgumentError('أسعار الوحدات غير صالحة.');
    }
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
