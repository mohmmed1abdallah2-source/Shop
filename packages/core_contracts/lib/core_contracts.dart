/// Shared dependency-free API contracts.
library core_contracts;

/// Response metadata.
class PageMeta {
  /// Creates metadata.
  const PageMeta({this.page, this.limit, this.nextCursor, required this.requestId});
  /// Page number.
  final int? page;
  /// Page size.
  final int? limit;
  /// Next page cursor.
  final String? nextCursor;
  /// Request correlation ID.
  final String requestId;
  /// Encodes metadata.
  Map<String, Object?> toJson() => {'page': page, 'limit': limit, 'nextCursor': nextCursor, 'requestId': requestId};
}

/// Standard API error.
class ApiError {
  /// Creates an error.
  const ApiError({required this.code, required this.message, required this.requestId});
  /// Error code.
  final String code;
  /// Safe message.
  final String message;
  /// Request ID.
  final String requestId;
  /// Encodes error.
  Map<String, Object?> toJson() => {'code': code, 'message': message, 'requestId': requestId};
}

/// Standard API success envelope.
class ApiResponse<T> {
  /// Creates a response.
  const ApiResponse({required this.data, required this.meta});
  /// Payload.
  final T data;
  /// Metadata.
  final PageMeta meta;
  /// Encodes payload with a caller encoder.
  Map<String, Object?> toJson(Object? Function(T) encode) => {'data': encode(data), 'meta': meta.toJson()};
}

/// Product sellable unit and barcode.
class ProductUnitBarcodeDto {
  /// Creates a unit DTO.
  const ProductUnitBarcodeDto({required this.unitName, required this.barcode, required this.retailPrice, this.wholesalePrice = 0});
  /// Unit label.
  final String unitName;
  /// Barcode.
  final String barcode;
  /// Retail price.
  final double retailPrice;
  /// Wholesale price.
  final double wholesalePrice;
  /// Encodes unit.
  Map<String, Object?> toJson() => {'unitName': unitName, 'barcode': barcode, 'retailPrice': retailPrice, 'wholesalePrice': wholesalePrice};
}

/// Catalog product DTO.
class ProductDto {
  /// Creates a product.
  const ProductDto({required this.id, required this.name, required this.sku, required this.kind, required this.units, this.scalePluCode, this.categoryId});
  /// Product UUID.
  final String id;
  /// Product name.
  final String name;
  /// SKU.
  final String sku;
  /// numeric or weighted.
  final String kind;
  /// Selling units.
  final List<ProductUnitBarcodeDto> units;
  /// Scale PLU.
  final String? scalePluCode;
  /// Category UUID.
  final String? categoryId;
  /// Encodes product.
  Map<String, Object?> toJson() => {'id': id, 'name': name, 'sku': sku, 'kind': kind, 'scalePluCode': scalePluCode, 'categoryId': categoryId, 'units': units.map((u) => u.toJson()).toList()};
  /// Decodes product.
  factory ProductDto.fromJson(Map<String, dynamic> j) => ProductDto(id: j['id'] as String, name: j['name'] as String, sku: j['sku'] as String, kind: j['kind'] as String, scalePluCode: j['scalePluCode'] as String?, categoryId: j['categoryId'] as String?, units: (j['units'] as List<dynamic>? ?? const []).map((e) { final m = e as Map<String, dynamic>; return ProductUnitBarcodeDto(unitName: m['unitName'] as String, barcode: m['barcode'] as String, retailPrice: (m['retailPrice'] as num).toDouble(), wholesalePrice: (m['wholesalePrice'] as num? ?? 0).toDouble()); }).toList());
}

/// Authenticated session DTO.
class UserSessionDto {
  /// Creates session.
  const UserSessionDto({required this.userId, required this.branchId, required this.permissions});
  /// User UUID.
  final String userId;
  /// Branch UUID.
  final String branchId;
  /// Permission codes.
  final List<String> permissions;
}

/// Public app configuration DTO.
class AppConfigDto {
  /// Creates configuration.
  const AppConfigDto({required this.apiVersion, required this.minimumClientVersion});
  /// API version.
  final String apiVersion;
  /// Minimum client version.
  final String minimumClientVersion;
}
