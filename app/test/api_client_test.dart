import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:api_client/api_client.dart';

/// Tests the shared HTTP client's authentication and idempotency headers.
void main() {
  test('adds bearer token, request ID, branch and idempotency headers', () async {
    late http.Request captured;
    final transport = MockClient((request) async {
      captured = request;
      return http.Response('{"data":{"saved":true},"meta":{"requestId":"req-1"}}', 201, headers: {'content-type': 'application/json'});
    });
    final client = ApiClient(baseUri: Uri.parse('https://api.example.test'), tokenProvider: () async => 'firebase-id-token', client: transport);
    final result = await client.send('POST', '/v1/catalog/products', body: {'id': 'product'}, idempotencyKey: 'operation-identifier-0001', extraHeaders: {'X-Branch-Id': '00000000-0000-4000-8000-000000000001'});
    expect(result['data']['saved'], isTrue);
    expect(captured.headers['authorization'], 'Bearer firebase-id-token');
    expect(captured.headers['x-request-id'], isNotEmpty);
    expect(captured.headers['idempotency-key'], 'operation-identifier-0001');
    expect(captured.headers['x-branch-id'], '00000000-0000-4000-8000-000000000001');
    client.close();
  });

  test('returns ETag metadata for a not-modified response', () async {
    final transport = MockClient((request) async => http.Response('', 304, headers: {'etag': '"catalog-v1"'}));
    final client = ApiClient(baseUri: Uri.parse('https://api.example.test'), tokenProvider: () async => 'token', client: transport);
    final result = await client.send('GET', '/v1/catalog/products');
    expect(result['_notModified'], isTrue);
    expect(result['_etag'], '"catalog-v1"');
    client.close();
  });

  test('reuses idempotency key while retrying a server failure', () async {
    var calls = 0;
    final transport = MockClient((request) async {
      calls++;
      expect(request.headers['idempotency-key'], 'same-operation-key-0001');
      return calls == 1 ? http.Response('{"error":{"code":"TEMPORARY"}}', 503) : http.Response('{"data":{},"meta":{"requestId":"ok"}}', 200);
    });
    final client = ApiClient(baseUri: Uri.parse('https://api.example.test'), tokenProvider: () async => 'token', client: transport, maxRetries: 1);
    await client.send('POST', '/v1/catalog/products', body: {'x': 1}, idempotencyKey: 'same-operation-key-0001');
    expect(calls, 2);
    client.close();
  });
}
