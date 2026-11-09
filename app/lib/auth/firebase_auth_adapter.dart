import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Firebase Authentication REST adapter for Android, Windows and Web.
class FirebaseAuthAdapter {
  /// Creates the adapter with a Firebase Web API key.
  FirebaseAuthAdapter({required this.apiKey, FlutterSecureStorage? storage, http.Client? client}) : _storage = storage ?? const FlutterSecureStorage(), _client = client ?? http.Client();
  /// Firebase Web API key; it is an application identifier, not a server secret.
  final String apiKey;
  final FlutterSecureStorage _storage;
  final http.Client _client;
  String? _idToken;
  DateTime _expiresAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const _refreshKey = 'shop.firebase.refresh_token';

  /// Signs in with Firebase email/password and securely stores the refresh token.
  Future<void> signIn(String email, String password) async {
    if (apiKey.isEmpty) throw const FirebaseAuthException('CONFIGURATION_MISSING', 'لم يتم ضبط مفتاح Firebase في إعدادات البناء.');
    final response = await _client.post(Uri.https('identitytoolkit.googleapis.com', '/v1/accounts:signInWithPassword', {'key': apiKey}), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email.trim(), 'password': password, 'returnSecureToken': true})).timeout(const Duration(seconds: 20));
    final json = _decode(response);
    _acceptTokens(json, 'idToken', 'refreshToken', 'expiresIn');
  }

  /// Returns a valid ID token, refreshing it when it is near expiry.
  Future<String?> getIdToken() async {
    if (_idToken != null && DateTime.now().isBefore(_expiresAt.subtract(const Duration(minutes: 2)))) return _idToken;
    final refreshToken = await _storage.read(key: _refreshKey);
    if (refreshToken == null || refreshToken.isEmpty) return null;
    final response = await _client.post(Uri.https('securetoken.googleapis.com', '/v1/token', {'key': apiKey}), headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: {'grant_type': 'refresh_token', 'refresh_token': refreshToken}).timeout(const Duration(seconds: 20));
    final json = _decode(response);
    _acceptTokens(json, 'id_token', 'refresh_token', 'expires_in');
    return _idToken;
  }

  /// Signs out and removes the persisted refresh token.
  Future<void> signOut() async {
    _idToken = null;
    _expiresAt = DateTime.fromMillisecondsSinceEpoch(0);
    await _storage.delete(key: _refreshKey);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) throw const FormatException('Firebase returned an invalid response.');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded['error'];
      final code = error is Map<String, dynamic> ? (error['message'] as String? ?? 'AUTH_FAILED') : 'AUTH_FAILED';
      throw FirebaseAuthException(code, _arabicError(code));
    }
    return decoded;
  }

  Future<void> _acceptTokens(Map<String, dynamic> json, String idKey, String refreshKey, String expiryKey) async {
    final id = json[idKey];
    final refresh = json[refreshKey];
    final seconds = int.tryParse(json[expiryKey]?.toString() ?? '');
    if (id is! String || refresh is! String || seconds == null || seconds <= 0) throw const FormatException('Firebase token response is incomplete.');
    _idToken = id;
    _expiresAt = DateTime.now().add(Duration(seconds: seconds));
    await _storage.write(key: _refreshKey, value: refresh);
  }

  String _arabicError(String code) => switch (code) {
    'EMAIL_NOT_FOUND' || 'INVALID_LOGIN_CREDENTIALS' => 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
    'INVALID_PASSWORD' => 'كلمة المرور غير صحيحة.',
    'USER_DISABLED' => 'تم إيقاف هذا الحساب.',
    'TOO_MANY_ATTEMPTS_TRY_LATER' => 'محاولات كثيرة؛ حاول لاحقاً.',
    'OPERATION_NOT_ALLOWED' => 'تسجيل الدخول بالبريد وكلمة المرور غير مفعّل في Firebase.',
    _ => 'تعذر تسجيل الدخول إلى Firebase (' + code + ').',
  };

  /// Closes the underlying HTTP client.
  void close() => _client.close();
}

/// Safe Firebase authentication failure.
class FirebaseAuthException implements Exception {
  /// Creates an authentication exception.
  const FirebaseAuthException(this.code, this.message);
  /// Firebase error code.
  final String code;
  /// Safe Arabic message.
  final String message;
  @override
  String toString() => message;
}
