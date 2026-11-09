import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:core_contracts/core_contracts.dart';
import '../../application/catalog_use_cases.dart';
import '../../domain/catalog_permissions.dart';
import '../../domain/catalog_repository.dart';
import '../../shared/http_helpers.dart';

/// HTTP routes for branch-authorized catalog operations.
class CatalogRoutes {
  /// Creates catalog route handlers and permission checker.
  CatalogRoutes(this.upsert, this.list, this.lookup, this.permissions);
  /// Upsert use case.
  final UpsertProductUseCase upsert;
  /// List use case.
  final ListProductsCursorUseCase list;
  /// Lookup use case.
  final LookupBarcodeOrScaleUseCase lookup;
  /// Branch-scoped permission repository.
  final CatalogPermissionRepository permissions;
  /// Builds the router.
  Router get router {
    final r = Router();
    r.post('/products', _upsert);
    r.get('/products', _list);
    r.get('/lookup/<code>', _lookup);
    return r;
  }
  /// Checks whether a supplied branch identifier is a UUID.
  bool _validBranch(String? branch) => branch != null && RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$').hasMatch(branch);
  /// Checks the authenticated user's permission for a branch operation.
  Future<bool> _authorized(Request request, String branch, String permission) async {
    final uid = request.context['firebaseUid'] as String?;
    if (uid == null) return false;
    return permissions.hasPermission(uid, branch, permission);
  }

  /// Validates, authorizes and stores a product using its idempotency key.
  Future<Response> _upsert(Request request) async {
    try {
      final branch = request.headers['x-branch-id'];
      final key = request.headers['idempotency-key'];
      if (!_validBranch(branch) || key == null || key.length < 16 || key.length > 128) return failure(request, 400, 'INVALID_HEADERS', 'بيانات الفرع أو مفتاح منع التكرار غير صالحة.');
      if (!await _authorized(request, branch!, 'catalog.write')) return failure(request, 403, 'FORBIDDEN', 'ليس لديك صلاحية إضافة أو تعديل المنتجات في هذا الفرع.');
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final saved = await upsert.call(branch, ProductDto.fromJson(body), key);
      return success(request, saved.toJson(), status: 201);
    } on IdempotencyConflict { return failure(request, 409, 'IDEMPOTENCY_CONFLICT', 'مفتاح العملية مستخدم مع بيانات مختلفة.'); }
    on DuplicateBarcode { return failure(request, 409, 'DUPLICATE_BARCODE', 'هذا الباركود مرتبط بمنتج آخر.'); }
    on DuplicateScalePlu { return failure(request, 409, 'DUPLICATE_SCALE_PLU', 'رمز الميزان مستخدم لمنتج آخر في هذا الفرع.'); }
    on ArgumentError catch (e) { return failure(request, 400, 'VALIDATION_ERROR', e.message.toString()); }
    catch (_) { return failure(request, 500, 'INTERNAL_ERROR', 'تعذر حفظ المنتج.'); }
  }

  /// Lists a branch-scoped page for users with catalog.read permission.
  Future<Response> _list(Request request) async {
    final branch = request.headers['x-branch-id'];
    if (!_validBranch(branch)) return failure(request, 400, 'BRANCH_REQUIRED', 'معرّف الفرع غير صالح أو غير موجود.');
    if (!await _authorized(request, branch!, 'catalog.read')) return failure(request, 403, 'FORBIDDEN', 'ليس لديك صلاحية عرض المنتجات في هذا الفرع.');
    final limit = int.tryParse(request.url.queryParameters['limit'] ?? '30') ?? 30;
    try {
      final rows = await list.call(branch, cursor: request.url.queryParameters['cursor'], limit: limit, query: request.url.queryParameters['q']);
      final data = rows.map((p) => p.toJson()).toList();
      final etag = '"' + sha256.convert(utf8.encode(jsonEncode(data))).toString() + '"';
      if (request.headers['if-none-match'] == etag) return Response(304, headers: {'ETag': etag});
      return success(request, data, limit: limit, nextCursor: rows.length == limit ? rows.last.id : null, headers: {'ETag': etag});
    } catch (_) { return failure(request, 400, 'INVALID_QUERY', 'معلمات البحث غير صالحة.'); }
  }

  /// Looks up a barcode or scale PLU for users with catalog.read permission.
  Future<Response> _lookup(Request request, String code) async {
    final branch = request.headers['x-branch-id'];
    if (!_validBranch(branch)) return failure(request, 400, 'BRANCH_REQUIRED', 'معرّف الفرع غير صالح أو غير موجود.');
    if (!await _authorized(request, branch!, 'catalog.read')) return failure(request, 403, 'FORBIDDEN', 'ليس لديك صلاحية عرض المنتجات في هذا الفرع.');
    final product = await lookup.call(branch, code);
    return product == null ? failure(request, 404, 'NOT_FOUND', 'لم يتم العثور على المنتج.') : success(request, product.toJson());
  }
}
