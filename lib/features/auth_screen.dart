import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
});

class UserRepository {
  UserRepository(this._firestore);

  static final RegExp _usernamePattern = RegExp(
    r'^[a-z0-9](?:[a-z0-9._]{1,22}[a-z0-9])$',
  );

  final FirebaseFirestore _firestore;

  Future<void> createUserInFirestore(User user) async {
    final userReference = _firestore.collection('users').doc(user.uid);
    final userSnapshot = await userReference.get();

    if (!userSnapshot.exists) {
      final displayName = _cleanDisplayName(user.displayName);
      final profileImageUrl = user.photoURL?.trim() ?? '';

      await userReference.set({
        'uid': user.uid,
        'email': user.email?.trim() ?? '',
        'username': '',
        'usernameKey': '',
        'displayName': displayName,
        'photoUrl': profileImageUrl,
        'profileImageUrl': profileImageUrl,
        'bio': '',
        'followersCount': 0,
        'followingCount': 0,
        'isProfileCompleted': false,
        'authProvider': 'google',
        'schemaVersion': 2,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastSignInAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    // Kullanıcı her giriş yaptığında yalnızca kimlik sağlayıcıdan gelen güvenli
    // oturum alanlarını güncelleriz; profil tercihlerini ezmeyiz.
    await userReference.set(
      {
        'email': user.email?.trim() ?? '',
        'authProvider': 'google',
        'schemaVersion': 2,
        'lastSignInAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> completeUserProfile({
    required String uid,
    required String username,
    required String displayName,
    required String bio,
  }) async {
    final usernameKey = normalizeUsername(username);
    final cleanDisplayName = displayName.trim();
    final cleanBio = bio.trim();

    if (!_usernamePattern.hasMatch(usernameKey)) {
      throw const ProfileValidationException(
        'Kullanıcı adı 3–24 karakter olmalı; yalnızca harf, rakam, nokta ve alt çizgi içermelidir.',
      );
    }

    if (cleanDisplayName.length < 2 || cleanDisplayName.length > 40) {
      throw const ProfileValidationException(
        'Görünen ad 2–40 karakter arasında olmalıdır.',
      );
    }

    if (cleanBio.length > 160) {
      throw const ProfileValidationException(
        'Biyografi en fazla 160 karakter olabilir.',
      );
    }

    final userReference = _firestore.collection('users').doc(uid);
    final usernameReference =
        _firestore.collection('usernames').doc(usernameKey);

    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userReference);
      final usernameSnapshot = await transaction.get(usernameReference);

      final userData = userSnapshot.data();
      final currentUsernameKey =
          (userData?['usernameKey'] as String? ?? '').trim().toLowerCase();

      DocumentSnapshot<Map<String, dynamic>>? previousReservation;
      if (currentUsernameKey.isNotEmpty &&
          currentUsernameKey != usernameKey) {
        previousReservation = await transaction.get(
          _firestore.collection('usernames').doc(currentUsernameKey),
        );
      }

      final reservedByUid =
          usernameSnapshot.data()?['uid'] as String?;
      if (usernameSnapshot.exists && reservedByUid != uid) {
        throw const UsernameTakenException();
      }

      if (previousReservation != null &&
          previousReservation.data()?['uid'] == uid) {
        transaction.delete(previousReservation.reference);
      }

      final reservationData = <String, dynamic>{
        'uid': uid,
        'username': '@$usernameKey',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!usernameSnapshot.exists) {
        reservationData['createdAt'] = FieldValue.serverTimestamp();
      }

      transaction.set(
        usernameReference,
        reservationData,
        SetOptions(merge: true),
      );

      transaction.set(
        userReference,
        {
          'uid': uid,
          'username': '@$usernameKey',
          'usernameKey': usernameKey,
          'displayName': cleanDisplayName,
          'bio': cleanBio,
          'isProfileCompleted': true,
          'schemaVersion': 2,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  static String normalizeUsername(String value) {
    return value
        .trim()
        .replaceFirst(RegExp(r'^@+'), '')
        .toLowerCase();
  }

  static String _cleanDisplayName(String? value) {
    final cleanValue = value?.trim() ?? '';
    return cleanValue.isEmpty ? 'Hexa kullanıcısı' : cleanValue;
  }
}

class UsernameTakenException implements Exception {
  const UsernameTakenException();

  @override
  String toString() => 'Bu kullanıcı adı daha önce alınmış.';
}

class ProfileValidationException implements Exception {
  const ProfileValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
