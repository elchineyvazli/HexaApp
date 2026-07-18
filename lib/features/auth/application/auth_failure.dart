import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum AuthFailureCode {
  cancelled,
  invalidEmail,
  invalidCredential,
  userNotFound,
  wrongPassword,
  emailAlreadyInUse,
  weakPassword,
  userDisabled,
  tooManyRequests,
  network,
  popupBlocked,
  providerDisabled,
  credentialAlreadyInUse,
  requiresRecentLogin,
  unsupportedPlatform,
  profileSync,
  unknown,
}

@immutable
class AuthFailure implements Exception {
  const AuthFailure({required this.code, required this.message, this.cause});

  const AuthFailure.cancelled()
    : code = AuthFailureCode.cancelled,
      message = 'Giriş işlemi iptal edildi.',
      cause = null;

  const AuthFailure.unsupportedPlatform()
    : code = AuthFailureCode.unsupportedPlatform,
      message = 'Google ile giriş bu platformda desteklenmiyor.',
      cause = null;

  const AuthFailure.missingGoogleToken()
    : code = AuthFailureCode.invalidCredential,
      message = 'Google güvenlik bilgileri alınamadı.',
      cause = null;

  factory AuthFailure.profileSync(Object cause) {
    return AuthFailure(
      code: AuthFailureCode.profileSync,
      message:
          'Oturum açıldı ancak Hexa profili hazırlanamadı. '
          'Bağlantını kontrol edip tekrar dene.',
      cause: cause,
    );
  }

  factory AuthFailure.from(Object error) {
    if (error is AuthFailure) {
      return error;
    }

    if (error is FirebaseAuthException) {
      return _fromFirebase(error);
    }

    if (error is PlatformException) {
      return _fromPlatform(error);
    }

    return AuthFailure(
      code: AuthFailureCode.unknown,
      message: 'Beklenmeyen bir giriş sorunu oluştu.',
      cause: error,
    );
  }

  final AuthFailureCode code;
  final String message;
  final Object? cause;

  bool get isCancellation {
    return code == AuthFailureCode.cancelled;
  }

  static AuthFailure _fromFirebase(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return AuthFailure(
          code: AuthFailureCode.invalidEmail,
          message: 'E-posta adresi geçerli değil.',
          cause: error,
        );

      case 'invalid-credential':
      case 'invalid-login-credentials':
        return AuthFailure(
          code: AuthFailureCode.invalidCredential,
          message: 'E-posta veya şifre doğru değil.',
          cause: error,
        );

      case 'wrong-password':
        return AuthFailure(
          code: AuthFailureCode.wrongPassword,
          message: 'Şifre doğru değil.',
          cause: error,
        );

      case 'user-not-found':
        return AuthFailure(
          code: AuthFailureCode.userNotFound,
          message: 'Bu e-posta ile kayıtlı bir hesap bulunamadı.',
          cause: error,
        );

      case 'email-already-in-use':
        return AuthFailure(
          code: AuthFailureCode.emailAlreadyInUse,
          message: 'Bu e-posta başka bir hesap tarafından kullanılıyor.',
          cause: error,
        );

      case 'weak-password':
        return AuthFailure(
          code: AuthFailureCode.weakPassword,
          message: 'Daha güçlü bir şifre seçmelisin.',
          cause: error,
        );

      case 'user-disabled':
        return AuthFailure(
          code: AuthFailureCode.userDisabled,
          message: 'Bu hesap şu anda kullanılamıyor.',
          cause: error,
        );

      case 'too-many-requests':
        return AuthFailure(
          code: AuthFailureCode.tooManyRequests,
          message: 'Çok fazla deneme yapıldı. Bir süre sonra tekrar dene.',
          cause: error,
        );

      case 'network-request-failed':
        return AuthFailure(
          code: AuthFailureCode.network,
          message: 'İnternet bağlantısı kurulamadı.',
          cause: error,
        );

      case 'popup-blocked':
        return AuthFailure(
          code: AuthFailureCode.popupBlocked,
          message: 'Google giriş penceresi tarayıcı tarafından engellendi.',
          cause: error,
        );

      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'web-context-cancelled':
        return const AuthFailure.cancelled();

      case 'operation-not-allowed':
        return AuthFailure(
          code: AuthFailureCode.providerDisabled,
          message: 'Bu giriş yöntemi Firebase üzerinde etkin değil.',
          cause: error,
        );

      case 'account-exists-with-different-credential':
      case 'credential-already-in-use':
        return AuthFailure(
          code: AuthFailureCode.credentialAlreadyInUse,
          message: 'Bu e-posta farklı bir giriş yöntemiyle kullanılıyor.',
          cause: error,
        );

      case 'requires-recent-login':
        return AuthFailure(
          code: AuthFailureCode.requiresRecentLogin,
          message: 'Bu işlem için hesabına yeniden giriş yapmalısın.',
          cause: error,
        );

      default:
        return AuthFailure(
          code: AuthFailureCode.unknown,
          message: error.message?.trim().isNotEmpty == true
              ? error.message!.trim()
              : 'Kimlik doğrulama işlemi tamamlanamadı.',
          cause: error,
        );
    }
  }

  static AuthFailure _fromPlatform(PlatformException error) {
    switch (error.code) {
      case 'sign_in_canceled':
      case 'canceled':
      case 'cancelled':
        return const AuthFailure.cancelled();

      case 'network_error':
        return AuthFailure(
          code: AuthFailureCode.network,
          message: 'Google bağlantısı kurulamadı.',
          cause: error,
        );

      case 'sign_in_required':
      case 'sign_in_failed':
        return AuthFailure(
          code: AuthFailureCode.invalidCredential,
          message: 'Google ile giriş tamamlanamadı.',
          cause: error,
        );

      default:
        return AuthFailure(
          code: AuthFailureCode.unknown,
          message: 'Google giriş işlemi tamamlanamadı.',
          cause: error,
        );
    }
  }

  @override
  String toString() => message;
}
