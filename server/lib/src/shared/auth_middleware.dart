import 'package:shelf/shelf.dart';
import 'http_helpers.dart';

/// Firebase identity with a cryptographically verified token.
class VerifiedIdentity {
  /// Creates a verified identity.
  const VerifiedIdentity(this.uid);
  /// Firebase UID.
  final String uid;
}

/// Port for Firebase ID token verification.
abstract interface class FirebaseTokenVerifier {
  /// Verifies token signature, issuer, audience and expiry.
  Future<VerifiedIdentity?> verify(String token);
}

/// Rejects requests without a verified Firebase bearer token.
Middleware firebaseAuth(FirebaseTokenVerifier verifier) => (inner) => (request) async {
  final header = request.headers['authorization'];
  if (header == null || !header.startsWith('Bearer ')) return failure(request, 401, 'UNAUTHENTICATED', 'يلزم تسجيل الدخول.');
  try {
    final identity = await verifier.verify(header.substring(7));
    if (identity == null) return failure(request, 401, 'INVALID_TOKEN', 'رمز الدخول غير صالح.');
    return inner(request.change(context: {...request.context, 'firebaseUid': identity.uid}));
  } catch (_) {
    return failure(request, 503, 'AUTH_VERIFICATION_UNAVAILABLE', 'تعذر التحقق من جلسة الدخول حالياً.');
  }
};

/// Fail-closed default until a production Firebase verifier is configured.
class RejectUnconfiguredFirebaseVerifier implements FirebaseTokenVerifier {
  /// Creates the rejecting verifier.
  const RejectUnconfiguredFirebaseVerifier();
  /// Rejects every token.
  @override
  Future<VerifiedIdentity?> verify(String token) async => null;
}
