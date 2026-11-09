import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/// Supplies Firebase ID token.
typedef TokenProvider = Future<String?> Function();

/// HTTP client with auth, request IDs, retries and idempotency headers.
class ApiClient {
  /// Creates the client.
  ApiClient({required this.baseUri, required this.tokenProvider, http.Client? client, this.maxRetries = 2}) : _client = client ?? http.Client();
  /// API base URI.
  final Uri baseUri;
  /// Token provider.
  final TokenProvider tokenProvider;
  /// Retry count.
  final int maxRetries;
  final http.Client _client;
  final Random _random = Random.secure();
  /// Sends JSON request and returns JSON envelope.
  Future<Map<String, dynamic>> send(String method, String path, {Object? body, String? idempotencyKey}) async {
    final token = await tokenProvider();
    final requestId = DateTime.now().microsecondsSinceEpoch.toString() + '-' + _random.nextInt(1 << 32).toString();
    for (var attempt = 0; ; attempt++) {
      final headers = <String, String>{'Accept': 'application/json', 'Content-Type': 'application/json', 'X-Request-Id': requestId};
      if (token != null) headers['Authorization'] = 'Bearer ' + token;
      if (idempotencyKey != null) headers['Idempotency-Key'] = idempotencyKey;
      try {
        final request = http.Request(method, baseUri.resolve(path))..headers.addAll(headers);
        if (body != null) request.body = jsonEncode(body);
        final stream = await _client.send(request).timeout(const Duration(seconds: 25));
        final response = await http.Response.fromStream(stream);
        if (response.statusCode >= 500 && attempt < maxRetries) { await Future<void>.delayed(Duration(milliseconds: 200 * (1 << attempt))); continue; }
        final decoded = jsonDecode(response.body);
        if (response.statusCode < 200 || response.statusCode >= 300) throw ApiClientException(response.statusCode, decoded is Map<String, dynamic> ? decoded : {'body': response.body});
        if (decoded is! Map<String, dynamic>) throw const FormatException('Expected JSON object.');
        return decoded;
      } on TimeoutException { if (attempt >= maxRetries) rethrow; await Future<void>.delayed(Duration(milliseconds: 200 * (1 << attempt))); }
      on http.ClientException { if (attempt >= maxRetries) rethrow; await Future<void>.delayed(Duration(milliseconds: 200 * (1 << attempt))); }
    }
  }
  /// Closes HTTP transport.
  void close() => _client.close();
}

/// Non-success HTTP response.
class ApiClientException implements Exception {
  /// Creates exception.
  const ApiClientException(this.statusCode, this.payload);
  /// HTTP status.
  final int statusCode;
  /// Error payload.
  final Map<String, dynamic> payload;
}
