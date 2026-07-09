// lib/features/auth/data/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
});

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  Future<void> createUserInFirestore(User user) async {
    final userDocRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      await userDocRef.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'username': '@${user.email?.split('@')[0] ?? 'cyber_nomad'}',
        'displayName': user.displayName ?? 'Cyber Nomad',
        'photoUrl': user.photoURL ?? '',
        'bio': 'Siber dünyada yeni bir yolcu...',
        'coins': 995,
        'followersCount': 0,
        'followingCount': 0,
        'isProfileCompleted': false, // ⚡ YENİ: Zorunlu kalkan işareti!
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ⚡ YENİ: Kullanıcı profilini tamamladığında kalkanı açan motor
  Future<void> completeUserProfile({
    required String uid,
    required String username,
    required String bio,
  }) async {
    final formattedUsername = username.startsWith('@') ? username : '@$username';
    await _firestore.collection('users').doc(uid).update({
      'username': formattedUsername,
      'bio': bio.isNotEmpty ? bio : 'Siber dünyada yeni bir yolcu...',
      'isProfileCompleted': true, // ⚡ Kalkanı aç ve özgürlüğü ver!
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}