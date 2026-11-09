import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/// Provides a current Firebase ID token.
typedef TokenProvider = Future<String?> Function();

/// Shared HTTP client with bearer auth, request IDs, idempotency and retries.
class ApiClient {
  /// Creates an API client.
  ApiClient({required this.baseUri, required this.tokenProvider, http.Client? client, this.maxRetries = 2}) : _client = client ?? http.Client();
  /// API base URI.
  final Uri baseUri;
  /// Firebase ID token provider.
  final TokenProvider tokenProvider;
  /// Maximum retry attempts after the first request.
  final int maxRetries;
  final http.Client _client;
  final Random _random = Random.secure();

  /// Sends a JSON request and returns the decoded success envelope.
  Future<Map<String, dynamic>> send(String method, String path, {Object? body, String? idempotencyKey, Map<String, String> extraHeaders = const {}}) async {
    final token = await tokenProvider();
    final requestId = DateTime.now().microsecondsSinceEpoch.toString() + '-' + _random.nextInt(1 << 32).toString();
    for (var attempt = 0; ; attempt++) {
      final headers = <String, String>{'Accept': 'application/json', 'Content-Type': 'application/json', 'X-Request-Id': requestId, ...extraHeaders};
      if (token != null) headers['Authorization'] = 'Bearer ' + token;
      if (idempotencyKey != null) headers['Idempotency-Key'] = idempotencyKey;
      try {
        final request = http.Request(method, baseUri.resolve(path))..headers.addAll(headers);
        if (body != null) request.body = jsonEncode(body);
        final stream = await _client.send(request).timeout(const Duration(seconds: 25));
        final response = await http.Response.fromStream(stream);
        if (response.statusCode >= 500 && attempt < maxRetries) { await Future<void>.delayed(Duration(milliseconds: 250 * (1 << attempt))); continue; }
        if (response.statusCode == 304) return {'_notModified': true, '_etag': response.headers['etag']};
        final decoded = jsonDecode(response.body);
        if (response.statusCode < 200 || response.statusCode >= 300) throw ApiClientException(response.statusCode, decoded is Map<String, dynamic> ? decoded : {'body': response.body});
        if (decoded is! Map<String, dynamic>) throw const FormatException('Expected JSON object.');
        return decoded;
      } on TimeoutException { if (attempt >= maxRetries) rethrow; await Future<void>.delayed(Duration(milliseconds: 250 * (1 << attempt))); }
      on http.ClientException { if (attempt >= maxRetries) rethrow; await Future<void>.delayed(Duration(milliseconds: 250 * (1 << attempt))); }
    }
  }
  /// Closes the underlying HTTP transport.
  void close() => _client.close();
}

/// Non-success HTTP response.
class ApiClientException implements Exception {
  /// Creates an API exception.
  const ApiClientException(this.statusCode, this.payload);
  /// HTTP status code.
  final int statusCode;
  /// Decoded server payload.
  final Map<String, dynamic> payload;
  @override
  String toString() => 'ApiClientException(' + statusCode.toString() + '): ' + payload.toString();
}
