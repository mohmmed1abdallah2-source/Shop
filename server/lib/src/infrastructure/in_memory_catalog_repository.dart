import 'dart:convert';
import 'package:core_contracts/core_contracts.dart';
import '../domain/catalog_repository.dart';

/// In-memory adapter for tests and local development.
class InMemoryCatalogRepository implements CatalogRepository {
  final Map<String, ProductDto> _items = {};
  final Map<String, ProductDto> _keys = {};
  /// Saves and replays products for matching idempotency keys.
  @override
  Future<ProductDto> upsert(String branch, ProductDto product, String key) async {
    final scoped = branch + ':' + key;
    final prior = _keys[scoped];
    if (prior != null) {
      if (jsonEncode(prior.toJson()) != jsonEncode(product.toJson())) throw const IdempotencyConflict();
      return prior;
    }
    _items[branch + ':' + product.id] = product;
    _keys[scoped] = product;
    return product;
  }
  /// Lists branch products with a stable cursor.
  @override
  Future<List<ProductDto>> list(String branch, {String? cursor, int limit = 30, String? query}) async {
    final rows = _items.entries.where((e) => e.key.startsWith(branch + ':')).map((e) => e.value).where((p) => query == null || p.name.toLowerCase().contains(query.toLowerCase()) || p.sku.toLowerCase().contains(query.toLowerCase())).toList()..sort((a,b) => a.id.compareTo(b.id));
    final start = cursor == null ? 0 : rows.indexWhere((p) => p.id == cursor) + 1;
    if (start < 0 || start >= rows.length) return const [];
    return rows.skip(start).take(limit).toList();
  }
  /// Finds a product by unit barcode or scale PLU.
  @override
  Future<ProductDto?> lookup(String branch, String code) async {
    for (final entry in _items.entries.where((e) => e.key.startsWith(branch + ':'))) {
      final product = entry.value;
      if (product.scalePluCode == code || product.units.any((unit) => unit.barcode == code)) return product;
    }
    return null;
  }
}
