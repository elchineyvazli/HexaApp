import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hexa/features/auth/data/user_repository.dart';

const String _googleServerClientId =
    '1020537179555-djroq75r9hdbhlkvlgn39hvg903rtlph.apps.googleusercontent.com';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    auth: FirebaseAuth.instance,
    googleSignIn: GoogleSignIn(
      serverClientId: kIsWeb ? null : _googleServerClientId,
    ),
    userRepository: ref.read(userRepositoryProvider),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthService {
  AuthService({
    required FirebaseAuth auth,
    required GoogleSignIn googleSignIn,
    required UserRepository userRepository,
  }) : _auth = auth,
       _googleSignIn = googleSignIn,
       _userRepository = userRepository;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final UserRepository _userRepository;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    final UserCredential userCredential;

    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters(const {'prompt': 'select_account'});

      userCredential = await _auth.signInWithPopup(googleProvider);
    } else {
      final googleUser = await _googleSignIn.signIn();

      // Kullanıcı hesap seçme penceresini kapattıysa bu bir hata değildir.
      if (googleUser == null) {
        return null;
      }

      final googleAuthentication = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuthentication.accessToken,
        idToken: googleAuthentication.idToken,
      );

      userCredential = await _auth.signInWithCredential(credential);
    }

    final user = userCredential.user;
    if (user == null) {
      throw StateError('Google oturumu kullanıcı bilgisi döndürmedi.');
    }

    try {
      await _userRepository.ensureUserDocument(user);
    } catch (_) {
      // Kullanıcı belgesi oluşturulamadığında yarım bir oturum bırakmayız.
      await _auth.signOut();
      if (!kIsWeb) {
        try {
          await _googleSignIn.signOut();
        } catch (error) {
          debugPrint('Google sign-out after setup failure: $error');
        }
      }
      rethrow;
    }

    return userCredential;
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (error) {
        // Firebase oturumunun kapanmasını Google SDK hatası engellememeli.
        debugPrint('Google sign-out failed: $error');
      }
    }

    await _auth.signOut();
  }
}
