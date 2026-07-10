import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hexa/features/auth/data/user_repository.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    auth: FirebaseAuth.instance,
    googleSignIn: GoogleSignIn(
      serverClientId: kIsWeb
          ? null
          : '1020537179555-djroq75r9hdbhlkvlgn39hvg903rtlph.apps.googleusercontent.com',
    ),
    firestore: FirebaseFirestore.instance,
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
    required FirebaseFirestore firestore,
    required UserRepository userRepository,
  })  : _auth = auth,
        _googleSignIn = googleSignIn,
        _firestore = firestore,
        _userRepository = userRepository;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  // Firestore bağımlılığını şimdilik koruyoruz.
  // Sonraki repository temizliğinde kaldıracağız veya kullanacağız.
  final FirebaseFirestore _firestore;

  final UserRepository _userRepository;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    final UserCredential userCredential;

    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters(
          const {
            'prompt': 'select_account',
          },
        );

      userCredential = await _auth.signInWithPopup(
        googleProvider,
      );
    } else {
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final googleAuthentication = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuthentication.accessToken,
        idToken: googleAuthentication.idToken,
      );

      userCredential = await _auth.signInWithCredential(
        credential,
      );
    }

    final user = userCredential.user;

    if (user != null) {
      await _userRepository.createUserInFirestore(user);
    }

    return userCredential;
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }

    await _auth.signOut();
  }
}