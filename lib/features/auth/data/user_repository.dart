import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(firestore: ref.watch(firestoreProvider));
});

class UserRepository {
  UserRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  static const String usersCollection = 'users';
  static const String usernamesCollection = 'usernames';
  static const int currentSchemaVersion = 3;

  static final RegExp _usernamePattern = RegExp(
    r'^[a-z0-9][a-z0-9._]{1,22}[a-z0-9]$',
  );

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users {
    return _firestore.collection(usersCollection);
  }

  CollectionReference<Map<String, dynamic>> get _usernames {
    return _firestore.collection(usernamesCollection);
  }

  Future<void> ensureUserDocument(User user) async {
    final userReference = _users.doc(user.uid);

    final providerIds = _providerIdsOf(user);
    final primaryProvider = _primaryProviderOf(providerIds);

    final email = user.email?.trim() ?? '';
    final displayName = user.displayName?.trim() ?? '';
    final profileImageUrl = user.photoURL?.trim() ?? '';

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userReference);
      final existingData = snapshot.data();

final createdAt = FieldValue.serverTimestamp();
      final lastSignInAt = FieldValue.serverTimestamp();

      if (!snapshot.exists) {
        transaction.set(userReference, <String, dynamic>{
          'uid': user.uid,
          'email': email,
          'emailVerified': user.emailVerified,
          'isAnonymous': user.isAnonymous,
          'username': '',
          'usernameKey': '',
          'displayName': _fallbackDisplayName(displayName),
          'photoUrl': profileImageUrl,
          'profileImageUrl': profileImageUrl,
          'bio': '',
          'followersCount': 0,
          'followingCount': 0,
          'isProfileCompleted': false,
          'authProvider': primaryProvider,
          'authProviders': providerIds,
          'schemaVersion': currentSchemaVersion,
          'createdAt': createdAt,
          'updatedAt': FieldValue.serverTimestamp(),
          'lastSignInAt': lastSignInAt,
        });

        return;
      }

      final update = <String, dynamic>{
        'uid': user.uid,
        'emailVerified': user.emailVerified,
        'isAnonymous': user.isAnonymous,
        'authProvider': primaryProvider,
        'authProviders': providerIds,
        'schemaVersion': currentSchemaVersion,
        'lastSignInAt': lastSignInAt,
      };

      if (email.isNotEmpty) {
        update['email'] = email;
      }

      if (!_hasText(existingData?['displayName']) && displayName.isNotEmpty) {
        update['displayName'] = displayName;
      }

      if (!_hasText(existingData?['profileImageUrl']) &&
          profileImageUrl.isNotEmpty) {
        update['profileImageUrl'] = profileImageUrl;
        update['photoUrl'] = profileImageUrl;
      }

      if (!existingData!.containsKey('isProfileCompleted')) {
        update['isProfileCompleted'] = false;
      }

      if (!existingData.containsKey('followersCount')) {
        update['followersCount'] = 0;
      }

      if (!existingData.containsKey('followingCount')) {
        update['followingCount'] = 0;
      }

      if (!existingData.containsKey('createdAt')) {
        update['createdAt'] = createdAt;
      }

      if (!existingData.containsKey('updatedAt')) {
        update['updatedAt'] = FieldValue.serverTimestamp();
      }

      transaction.set(userReference, update, SetOptions(merge: true));
    });
  }

  Stream<bool> watchIsProfileCompleted(String uid) {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return Stream<bool>.value(false);
    }

    return _users.doc(cleanUid).snapshots().map((snapshot) {
      return snapshot.data()?['isProfileCompleted'] == true;
    });
  }

  Future<bool> isProfileCompleted(String uid) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return false;
    }

    final snapshot = await _users.doc(cleanUid).get();

    return snapshot.data()?['isProfileCompleted'] == true;
  }

  Future<bool> isUsernameAvailable({
    required String username,
    String? reservedForUid,
  }) async {
    final usernameKey = validateAndNormalizeUsername(username);

    final snapshot = await _usernames.doc(usernameKey).get();

    if (!snapshot.exists) {
      return true;
    }

    final reservedByUid = (snapshot.data()?['uid'] as String? ?? '').trim();

    return reservedForUid != null &&
        reservedForUid.trim().isNotEmpty &&
        reservedByUid == reservedForUid.trim();
  }

  Future<void> completeUserProfile({
    required String uid,
    required String username,
    String? displayName,
    String bio = '',
  }) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      throw const ProfileValidationException('Kullanıcı kimliği bulunamadı.');
    }

    final usernameKey = validateAndNormalizeUsername(username);
    final requestedDisplayName = displayName?.trim() ?? '';
    final cleanBio = bio.trim();

    if (requestedDisplayName.isNotEmpty) {
      _validateDisplayName(requestedDisplayName);
    }

    if (cleanBio.length > 160) {
      throw const ProfileValidationException(
        'Biyografi en fazla 160 karakter olabilir.',
      );
    }

    final userReference = _users.doc(cleanUid);
    final usernameReference = _usernames.doc(usernameKey);

    await _firestore.runTransaction((transaction) async {
      // Transaction okumalarının tamamı yazmalardan önce yapılır.
      final userSnapshot = await transaction.get(userReference);
      final usernameSnapshot = await transaction.get(usernameReference);

      if (!userSnapshot.exists) {
        throw const UserDocumentNotFoundException();
      }

      final userData = userSnapshot.data()!;

      final currentUsernameKey = normalizeUsername(
        userData['usernameKey'] as String? ??
            userData['username'] as String? ??
            '',
      );

      DocumentSnapshot<Map<String, dynamic>>? previousReservation;

      if (currentUsernameKey.isNotEmpty && currentUsernameKey != usernameKey) {
        previousReservation = await transaction.get(
          _usernames.doc(currentUsernameKey),
        );
      }

      final reservedByUid = (usernameSnapshot.data()?['uid'] as String? ?? '')
          .trim();

      if (usernameSnapshot.exists && reservedByUid != cleanUid) {
        throw const UsernameTakenException();
      }

      final existingDisplayName = (userData['displayName'] as String? ?? '')
          .trim();

      final resolvedDisplayName = requestedDisplayName.isNotEmpty
          ? requestedDisplayName
          : _fallbackDisplayName(existingDisplayName);

      _validateDisplayName(resolvedDisplayName);

      final wasProfileCompleted = userData['isProfileCompleted'] == true;

      // Bütün okumalar tamamlandıktan sonra yazma işlemleri başlar.
      if (previousReservation != null &&
          previousReservation.data()?['uid'] == cleanUid) {
        transaction.delete(previousReservation.reference);
      }

      final reservationData = <String, dynamic>{
        'uid': cleanUid,
        'username': '@$usernameKey',
        'usernameKey': usernameKey,
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

      final profileUpdate = <String, dynamic>{
        'uid': cleanUid,
        'username': '@$usernameKey',
        'usernameKey': usernameKey,
        'displayName': resolvedDisplayName,
        'bio': cleanBio,
        'isProfileCompleted': true,
        'schemaVersion': currentSchemaVersion,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!wasProfileCompleted) {
        profileUpdate['profileCompletedAt'] = FieldValue.serverTimestamp();
      }

      transaction.set(userReference, profileUpdate, SetOptions(merge: true));
    });
  }

  static String normalizeUsername(String value) {
    return value.trim().replaceFirst(RegExp(r'^@+'), '').toLowerCase();
  }

  static String validateAndNormalizeUsername(String value) {
    final usernameKey = normalizeUsername(value);

    if (!_usernamePattern.hasMatch(usernameKey)) {
      throw const ProfileValidationException(
        'Kullanıcı adı 3–24 karakter olmalı; '
        'harf veya rakamla başlayıp bitmeli ve yalnızca '
        'küçük harf, rakam, nokta veya alt çizgi içermelidir.',
      );
    }

    if (usernameKey.contains('..') ||
        usernameKey.contains('__') ||
        usernameKey.contains('._') ||
        usernameKey.contains('_.')) {
      throw const ProfileValidationException(
        'Kullanıcı adında ayraçlar art arda kullanılamaz.',
      );
    }

    return usernameKey;
  }

  static void _validateDisplayName(String value) {
    if (value.length < 2 || value.length > 40) {
      throw const ProfileValidationException(
        'Görünen ad 2–40 karakter arasında olmalıdır.',
      );
    }
  }

  static List<String> _providerIdsOf(User user) {
    final providers =
        user.providerData
            .map((provider) => provider.providerId.trim())
            .where((providerId) => providerId.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    if (providers.isEmpty) {
      providers.add(user.isAnonymous ? 'anonymous' : 'unknown');
    }

    return providers;
  }

  static String _primaryProviderOf(List<String> providerIds) {
    if (providerIds.contains('google.com')) {
      return 'google';
    }

    if (providerIds.contains('password')) {
      return 'password';
    }

    if (providerIds.contains('apple.com')) {
      return 'apple';
    }

    return providerIds.first;
  }

  static String _fallbackDisplayName(String value) {
    final cleanValue = value.trim();

    return cleanValue.isEmpty ? 'Hexa kullanıcısı' : cleanValue;
  }

  static bool _hasText(Object? value) {
    return value is String && value.trim().isNotEmpty;
  }
}

class UsernameTakenException implements Exception {
  const UsernameTakenException();

  @override
  String toString() {
    return 'Bu kullanıcı adı daha önce alınmış.';
  }
}

class ProfileValidationException implements Exception {
  const ProfileValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UserDocumentNotFoundException implements Exception {
  const UserDocumentNotFoundException();

  @override
  String toString() {
    return 'Hexa kullanıcı belgesi bulunamadı.';
  }
}
