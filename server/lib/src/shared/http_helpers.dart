import 'dart:convert';
import 'package:shelf/shelf.dart';

/// Adds request correlation identifiers to request context and response headers.
Middleware requestContext() => (inner) => (request) async {
  final supplied = request.headers['x-request-id'];
  final id = supplied == null || supplied.trim().isEmpty ? DateTime.now().microsecondsSinceEpoch.toString() : supplied;
  final response = await inner(request.change(context: {'requestId': id}));
  return response.change(headers: {'X-Request-Id': id, ...response.headers});
};

/// Creates standard JSON success envelope.
Response success(Request request, Object? data, {int status = 200, int? limit, String? nextCursor}) {
  final id = request.context['requestId'] as String? ?? 'unknown';
  return Response(status, body: jsonEncode({'data': data, 'meta': {'page': null, 'limit': limit, 'nextCursor': nextCursor, 'requestId': id}}), headers: {'content-type': 'application/json'});
}

/// Creates standard JSON error envelope.
Response failure(Request request, int status, String code, String message) {
  final id = request.context['requestId'] as String? ?? 'unknown';
  return Response(status, body: jsonEncode({'error': {'code': code, 'message': message, 'requestId': id}}), headers: {'content-type': 'application/json'});
}
