import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:core_contracts/core_contracts.dart';
import '../../application/catalog_use_cases.dart';
import '../../infrastructure/postgres_catalog_repository.dart';
import '../../shared/http_helpers.dart';

/// HTTP routes for catalog operations.
class CatalogRoutes {
  /// Creates catalog route handlers.
  CatalogRoutes(this.upsert, this.list, this.lookup);
  /// Upsert use case.
  final UpsertProductUseCase upsert;
  /// List use case.
  final ListProductsCursorUseCase list;
  /// Lookup use case.
  final LookupBarcodeOrScaleUseCase lookup;
  /// Builds the router.
  Router get router {
    final r = Router();
    r.post('/products', _upsert);
    r.get('/products', _list);
    r.get('/lookup/<code>', _lookup);
    return r;
  }
  Future<Response> _upsert(Request request) async {
    try {
      final branch = request.headers['x-branch-id'];
      final key = request.headers['idempotency-key'];
      if (branch == null || key == null || key.length < 16) return failure(request, 400, 'INVALID_HEADERS', 'بيانات الفرع أو مفتاح منع التكرار غير صالحة.');
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final saved = await upsert.call(branch, ProductDto.fromJson(body), key);
      return success(request, saved.toJson(), status: 201);
    } on IdempotencyConflict { return failure(request, 409, 'IDEMPOTENCY_CONFLICT', 'مفتاح العملية مستخدم مع بيانات مختلفة.'); }
    on ArgumentError catch (e) { return failure(request, 400, 'VALIDATION_ERROR', e.message.toString()); }
    catch (_) { return failure(request, 500, 'INTERNAL_ERROR', 'تعذر حفظ المنتج.'); }
  }
  Future<Response> _list(Request request) async {
    final branch = request.headers['x-branch-id'];
    if (branch == null) return failure(request, 400, 'BRANCH_REQUIRED', 'الفرع مطلوب.');
    final limit = int.tryParse(request.url.queryParameters['limit'] ?? '30') ?? 30;
    try {
      final rows = await list.call(branch, cursor: request.url.queryParameters['cursor'], limit: limit, query: request.url.queryParameters['q']);
      return success(request, rows.map((p) => p.toJson()).toList(), limit: limit, nextCursor: rows.length == limit ? rows.last.id : null);
    } catch (_) { return failure(request, 400, 'INVALID_QUERY', 'معلمات البحث غير صالحة.'); }
  }
  Future<Response> _lookup(Request request, String code) async {
    final branch = request.headers['x-branch-id'];
    if (branch == null) return failure(request, 400, 'BRANCH_REQUIRED', 'الفرع مطلوب.');
    final product = await lookup.call(branch, code);
    return product == null ? failure(request, 404, 'NOT_FOUND', 'لم يتم العثور على المنتج.') : success(request, product.toJson());
  }
}
