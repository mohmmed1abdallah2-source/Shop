import 'dart:async';
import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import '../shared/auth_middleware.dart';

/// Verifies Firebase ID tokens using Google's rotating Secure Token certificates.
class GoogleFirebaseTokenVerifier implements FirebaseTokenVerifier {
  /// Creates a verifier for the configured Firebase project.
  GoogleFirebaseTokenVerifier({required this.projectId, http.Client? client}) : _client = client ?? http.Client();
  /// Firebase project identifier.
  final String projectId;
  final http.Client _client;
  Map<String, String> _certificates = {};
  DateTime _expiresAt = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void>? _refreshing;

  /// Verifies signature, issuer, audience, subject and time claims.
  @override
  Future<VerifiedIdentity?> verify(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3 || token.length > 16384) return null;
      final header = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[0])))) as Map<String, dynamic>;
      if (header['alg'] != 'RS256' || header['kid'] is! String) return null;
      await _ensureCertificates();
      final certificate = _certificates[header['kid'] as String];
      if (certificate == null) return null;
      final verified = JWT.verify(token, RSAPublicKey.cert(certificate));
      final claims = verified.payload as Map<String, dynamic>;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final uid = claims['sub'];
      if (claims['iss'] != 'https://securetoken.google.com/' + projectId || claims['aud'] != projectId) return null;
      if (uid is! String || uid.isEmpty || uid.length > 128) return null;
      if (claims['exp'] is! num || (claims['exp'] as num) <= now) return null;
      if (claims['iat'] is! num || (claims['iat'] as num) > now + 60) return null;
      if (claims['auth_time'] is! num || (claims['auth_time'] as num) > now + 60) return null;
      return VerifiedIdentity(uid);
    } on JWTException { return null; }
    on FormatException { return null; }
    on TypeError { return null; }
  }

  Future<void> _ensureCertificates() async {
    if (_certificates.isNotEmpty && DateTime.now().isBefore(_expiresAt)) return;
    _refreshing ??= _loadCertificates();
    try { await _refreshing; } finally { _refreshing = null; }
  }

  Future<void> _loadCertificates() async {
    final response = await _client.get(Uri.parse('https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com')).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) throw StateError('Firebase certificate endpoint returned ' + response.statusCode.toString());
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    _certificates = json.map((key, value) => MapEntry(key, value as String));
    final maxAge = RegExp(r'max-age=(\d+)').firstMatch(response.headers['cache-control'] ?? '');
    final seconds = maxAge == null ? 3600 : int.parse(maxAge.group(1)!);
    _expiresAt = DateTime.now().add(Duration(seconds: seconds > 60 ? seconds - 30 : seconds));
  }
}
