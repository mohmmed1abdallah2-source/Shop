import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:shop_server/server.dart';
import 'package:shop_server/src/shared/auth_middleware.dart';

/// Test verifier that accepts one deterministic token only.
class _TestTokenVerifier implements FirebaseTokenVerifier {
  @override
  Future<VerifiedIdentity?> verify(String token) async => token == 'trusted-test-token' ? const VerifiedIdentity('firebase-user-1') : null;
}

/// HTTP API contract and authentication tests.
void main() {
  late Handler handler;
  setUp(() async { handler = await buildHandler(verifier: _TestTokenVerifier()); });

  test('health is public and uses the standard success envelope', () async {
    final response = await handler(Request('GET', Uri.parse('http://localhost/health')));
    expect(response.statusCode, 200);
    final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
    expect(body['data']['status'], 'ok');
    expect(body['meta']['requestId'], isNotEmpty);
  });

  test('catalog rejects requests without a verified bearer token', () async {
    final response = await handler(Request('GET', Uri.parse('http://localhost/v1/catalog/products'), headers: {'X-Branch-Id': '00000000-0000-4000-8000-000000000001'}));
    expect(response.statusCode, 401);
    final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
    expect(body['error']['code'], 'UNAUTHENTICATED');
  });

  test('catalog returns a branch-scoped page for a verified token', () async {
    final response = await handler(Request('GET', Uri.parse('http://localhost/v1/catalog/products'), headers: {'Authorization': 'Bearer trusted-test-token', 'X-Branch-Id': '00000000-0000-4000-8000-000000000001'}));
    expect(response.statusCode, 200);
    final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
    expect(body['data'], isEmpty);
    expect(body['meta']['requestId'], isNotEmpty);
  });
}
