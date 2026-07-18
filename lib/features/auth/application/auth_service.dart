import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';

import '../data/user_repository.dart';
import 'auth_failure.dart';

/// Geçici fallback mevcut yapılandırmayı kırmamak için tutuluyor.
///
/// Platform yapılandırmaları doğrulandıktan sonra fallback kaldırılıp değer
/// yalnızca `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` üzerinden alınabilir.
const String _googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue:
      '1020537179555-djroq75r9hdbhlkvlgn39hvg903rtlph.apps.googleusercontent.com',
);

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn?>((ref) {
  if (kIsWeb || !_supportsNativeGoogleSignIn) {
    return null;
  }

  return GoogleSignIn(
    scopes: const <String>['email'],
    serverClientId: _googleServerClientId.isEmpty
        ? null
        : _googleServerClientId,
  );
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    auth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
    userRepository: ref.watch(userRepositoryProvider),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentAuthUserProvider = Provider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).currentUser;
});

bool get _supportsNativeGoogleSignIn {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return true;

    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return false;
  }
}

class AuthService {
  AuthService({
    required FirebaseAuth auth,
    required GoogleSignIn? googleSignIn,
    required UserRepository userRepository,
  }) : _auth = auth,
       _googleSignIn = googleSignIn,
       _userRepository = userRepository;

  final FirebaseAuth _auth;
  final GoogleSignIn? _googleSignIn;
  final UserRepository _userRepository;

  final Map<String, Future<void>> _userSyncOperations =
      <String, Future<void>>{};

  /// Auth durumu dışarı aktarılmadan önce Firestore kullanıcı belgesinin
  /// hazır olduğundan emin olunur.
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        return null;
      }

      await _ensureUserDocument(user);

      return user;
    });
  }

  User? get currentUser => _auth.currentUser;

  bool get isSignedIn => currentUser != null;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final UserCredential? credential;

      if (kIsWeb) {
        credential = await _signInWithGoogleOnWeb();
      } else {
        credential = await _signInWithGoogleNatively();
      }

      if (credential == null) {
        return null;
      }

      return await _finalizeCredential(credential);
    } catch (error, stackTrace) {
      final failure = AuthFailure.from(error);

      if (failure.isCancellation) {
        return null;
      }

      Error.throwWithStackTrace(failure, stackTrace);
    }
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final credential = await _auth.signInWithEmailAndPassword(
        email: _normalizeEmail(email),
        password: password,
      );

      return _finalizeCredential(credential);
    });
  }

  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    String displayName = '',
  }) {
    return _guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _normalizeEmail(email),
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw const AuthFailure(
          code: AuthFailureCode.invalidCredential,
          message: 'Yeni kullanıcı bilgisi oluşturulamadı.',
        );
      }

      final cleanDisplayName = displayName.trim();

      if (cleanDisplayName.isNotEmpty) {
        await user.updateDisplayName(cleanDisplayName);
        await user.reload();
      }

      final refreshedUser = _auth.currentUser ?? user;

      await _ensureUserDocument(refreshedUser);

      return credential;
    });
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _guard(() async {
      final normalizedEmail = _normalizeEmail(email);

      if (normalizedEmail.isEmpty) {
        throw const AuthFailure(
          code: AuthFailureCode.invalidEmail,
          message: 'E-posta adresini girmelisin.',
        );
      }

      await _auth.sendPasswordResetEmail(email: normalizedEmail);
    });
  }

  Future<User?> reloadCurrentUser() {
    return _guard(() async {
      final user = _auth.currentUser;

      if (user == null) {
        return null;
      }

      await user.reload();

      final refreshedUser = _auth.currentUser;

      if (refreshedUser != null) {
        await _ensureUserDocument(refreshedUser);
      }

      return refreshedUser;
    });
  }

  Future<void> signOut() {
    return _guard(() async {
      final googleSignIn = _googleSignIn;

      if (googleSignIn != null) {
        try {
          await googleSignIn.signOut();
        } catch (error, stackTrace) {
          debugPrint('Google oturumu kapatılamadı: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }

      await _auth.signOut();
    });
  }

  Future<UserCredential> _signInWithGoogleOnWeb() {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..setCustomParameters(const <String, String>{'prompt': 'select_account'});

    return _auth.signInWithPopup(provider);
  }

  Future<UserCredential?> _signInWithGoogleNatively() async {
    final googleSignIn = _googleSignIn;

    if (googleSignIn == null) {
      throw const AuthFailure.unsupportedPlatform();
    }

    final googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      return null;
    }

    final googleAuthentication = await googleUser.authentication;

    final idToken = googleAuthentication.idToken;
    final accessToken = googleAuthentication.accessToken;

    if (idToken == null && accessToken == null) {
      throw const AuthFailure.missingGoogleToken();
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> _finalizeCredential(UserCredential credential) async {
    final user = credential.user;

    if (user == null) {
      throw const AuthFailure(
        code: AuthFailureCode.invalidCredential,
        message: 'Oturum kullanıcı bilgisi döndürmedi.',
      );
    }

    await _ensureUserDocument(user);

    return credential;
  }

  Future<void> _ensureUserDocument(User user) {
    final existingOperation = _userSyncOperations[user.uid];

    if (existingOperation != null) {
      return existingOperation;
    }

    final operation = _performUserSync(user);

    _userSyncOperations[user.uid] = operation;

    return operation;
  }

  Future<void> _performUserSync(User user) async {
    try {
      await _userRepository.ensureUserDocument(user);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'Firestore profile sync failed | '
        'plugin=${error.plugin} | '
        'code=${error.code} | '
        'message=${error.message}',
      );

      debugPrintStack(stackTrace: stackTrace);

      Error.throwWithStackTrace(AuthFailure.profileSync(error), stackTrace);
    } catch (error, stackTrace) {
      debugPrint(
        'Profile sync failed | '
        'type=${error.runtimeType} | '
        'error=$error',
      );

      debugPrintStack(stackTrace: stackTrace);

      Error.throwWithStackTrace(AuthFailure.profileSync(error), stackTrace);
    } finally {
      _userSyncOperations.remove(user.uid);
    }
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on AuthFailure {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(AuthFailure.from(error), stackTrace);
    }
  }

  String _normalizeEmail(String value) {
    return value.trim().toLowerCase();
  }
}
