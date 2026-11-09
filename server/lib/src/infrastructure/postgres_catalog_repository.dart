import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'package:core_contracts/core_contracts.dart';
import '../domain/catalog_repository.dart';

/// Raised when an idempotency key is reused with a different payload.
class IdempotencyConflict implements Exception {
  /// Creates the conflict.
  const IdempotencyConflict();
}

/// PostgreSQL adapter implementing catalog persistence.
class PostgresCatalogRepository implements CatalogRepository {
  /// Creates the adapter from a shared pool.
  const PostgresCatalogRepository(this.pool);
  /// PostgreSQL pool.
  final Pool pool;
  /// Atomically reserves the key and persists product and units.
  @override
  Future<ProductDto> upsert(String branch, ProductDto product, String key) => pool.runTx((session) async {
    final payload = jsonEncode(product.toJson());
    final hash = base64Encode(utf8.encode(payload));
    await session.execute(Sql.named('INSERT INTO idempotency_keys(branch_id,idempotency_key,request_hash) VALUES(@branch,@key,@hash) ON CONFLICT(branch_id,idempotency_key) DO NOTHING'), parameters: {'branch': branch, 'key': key, 'hash': hash});
    final reservation = await session.execute(Sql.named('SELECT request_hash,response_body FROM idempotency_keys WHERE branch_id=@branch AND idempotency_key=@key FOR UPDATE'), parameters: {'branch': branch, 'key': key});
    if (reservation.isEmpty || reservation.first[0] != hash) throw const IdempotencyConflict();
    final prior = reservation.first[1];
    if (prior != null) return ProductDto.fromJson(prior is String ? jsonDecode(prior) as Map<String, dynamic> : prior as Map<String, dynamic>);
    final saved = await session.execute(Sql.named('INSERT INTO products(id,branch_id,category_id,name,sku,kind,scale_plu_code) VALUES(@id,@branch,@category,@name,@sku,@kind,@plu) ON CONFLICT(id) DO UPDATE SET name=EXCLUDED.name,sku=EXCLUDED.sku,kind=EXCLUDED.kind,scale_plu_code=EXCLUDED.scale_plu_code,updated_at=now() WHERE products.branch_id=EXCLUDED.branch_id RETURNING id'), parameters: {'id': product.id, 'branch': branch, 'category': product.categoryId, 'name': product.name, 'sku': product.sku, 'kind': product.kind, 'plu': product.scalePluCode});
    if (saved.isEmpty) throw StateError('Product identity belongs to another branch.');
    await session.execute(Sql.named('DELETE FROM product_units_barcodes WHERE product_id=@id'), parameters: {'id': product.id});
    for (final unit in product.units) {
      await session.execute(Sql.named('INSERT INTO product_units_barcodes(product_id,unit_name,barcode,retail_price,wholesale_price) VALUES(@id,@unit,@barcode,@retail,@wholesale)'), parameters: {'id': product.id, 'unit': unit.unitName, 'barcode': unit.barcode, 'retail': unit.retailPrice, 'wholesale': unit.wholesalePrice});
    }
    await session.execute(Sql.named('UPDATE idempotency_keys SET response_status=201,response_body=@body::jsonb,updated_at=now() WHERE branch_id=@branch AND idempotency_key=@key'), parameters: {'body': payload, 'branch': branch, 'key': key});
    return product;
  });
  /// Lists products scoped to a branch in UUID cursor order.
  @override
  Future<List<ProductDto>> list(String branch, {String? cursor, int limit = 30, String? query}) async {
    final rows = await pool.execute(Sql.named("SELECT p.id,p.name,p.sku,p.kind,p.scale_plu_code,p.category_id,COALESCE(json_agg(json_build_object('unitName',u.unit_name,'barcode',u.barcode,'retailPrice',u.retail_price,'wholesalePrice',u.wholesale_price)) FILTER (WHERE u.id IS NOT NULL),'[]'::json) FROM products p LEFT JOIN product_units_barcodes u ON u.product_id=p.id AND u.deleted_at IS NULL WHERE p.branch_id=@branch AND p.deleted_at IS NULL AND (@cursor::uuid IS NULL OR p.id>@cursor::uuid) AND (@query::text IS NULL OR p.name ILIKE '%'||@query||'%' OR p.sku ILIKE '%'||@query||'%') GROUP BY p.id ORDER BY p.id LIMIT @limit"), parameters: {'branch': branch, 'cursor': cursor, 'query': query, 'limit': limit});
    return rows.map((r) => ProductDto.fromJson({'id': r[0].toString(), 'name': r[1], 'sku': r[2], 'kind': r[3], 'scalePluCode': r[4], 'categoryId': r[5]?.toString(), 'units': r[6] is String ? jsonDecode(r[6] as String) : r[6]})).toList();
  }
  /// Finds a product by barcode or scale PLU.
  @override
  Future<ProductDto?> lookup(String branch, String code) async {
    final rows = await pool.execute(Sql.named('SELECT p.id FROM products p LEFT JOIN product_units_barcodes u ON u.product_id=p.id WHERE p.branch_id=@branch AND p.deleted_at IS NULL AND (u.barcode=@code OR p.scale_plu_code=@code) LIMIT 1'), parameters: {'branch': branch, 'code': code});
    if (rows.isEmpty) return null;
    final products = await list(branch, limit: 100);
    for (final product in products) { if (product.id == rows.first[0].toString()) return product; }
    return null;
  }
}
