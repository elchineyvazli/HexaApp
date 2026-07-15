import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile_model.dart';

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

enum FollowListType { followers, following }

extension FollowListTypeCollection on FollowListType {
  String get collectionName {
    switch (this) {
      case FollowListType.followers:
        return 'followers';
      case FollowListType.following:
        return 'following';
    }
  }
}

class FollowListUser {
  const FollowListUser({required this.profile, required this.followedAt});

  final UserProfileModel profile;
  final DateTime? followedAt;
}

class FollowListPage {
  const FollowListPage({
    required this.users,
    required this.cursor,
    required this.hasMore,
  });

  final List<FollowListUser> users;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}

class FollowRepository {
  FollowRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  static const int defaultPageSize = 20;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Stream<bool> watchIsFollowing(String targetUserId) {
    final currentUser = _auth.currentUser;
    final cleanTargetUserId = targetUserId.trim();

    if (currentUser == null ||
        cleanTargetUserId.isEmpty ||
        currentUser.uid == cleanTargetUserId) {
      return Stream<bool>.value(false);
    }

    return _followingReference(
      followerUserId: currentUser.uid,
      followingUserId: cleanTargetUserId,
    ).snapshots().map((snapshot) => snapshot.exists).distinct();
  }

  Future<FollowListPage> fetchFollowPage({
    required String ownerUserId,
    required FollowListType type,
    DocumentSnapshot<Map<String, dynamic>>? after,
    int limit = defaultPageSize,
  }) async {
    final cleanOwnerUserId = ownerUserId.trim();

    if (cleanOwnerUserId.isEmpty) {
      return const FollowListPage(
        users: <FollowListUser>[],
        cursor: null,
        hasMore: false,
      );
    }

    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .doc(cleanOwnerUserId)
        .collection(type.collectionName)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (after != null) {
      query = query.startAfterDocument(after);
    }

    final relationshipSnapshot = await query.get();
    final relationshipDocuments = relationshipSnapshot.docs;

    if (relationshipDocuments.isEmpty) {
      return FollowListPage(
        users: const <FollowListUser>[],
        cursor: after,
        hasMore: false,
      );
    }

    final userSnapshots = await Future.wait(
      relationshipDocuments.map((document) {
        return _firestore.collection('users').doc(document.id).get();
      }),
    );

    final profilesById = <String, UserProfileModel>{};

    for (final userSnapshot in userSnapshots) {
      final data = userSnapshot.data();

      if (userSnapshot.exists && data != null) {
        profilesById[userSnapshot.id] = UserProfileModel.fromMap(
          data,
          userSnapshot.id,
        );
      }
    }

    final users = <FollowListUser>[];

    for (final relationshipDocument in relationshipDocuments) {
      final profile = profilesById[relationshipDocument.id];

      if (profile == null) {
        continue;
      }

      users.add(
        FollowListUser(
          profile: profile,
          followedAt: _readDate(relationshipDocument.data()['createdAt']),
        ),
      );
    }

    return FollowListPage(
      users: List<FollowListUser>.unmodifiable(users),
      cursor: relationshipDocuments.last,
      hasMore: relationshipDocuments.length == limit,
    );
  }

  Future<void> follow(String targetUserId) async {
    final currentUser = _requireCurrentUser();
    final cleanTargetUserId = _validateTargetUserId(
      currentUserId: currentUser.uid,
      targetUserId: targetUserId,
    );

    final currentUserReference = _firestore
        .collection('users')
        .doc(currentUser.uid);
    final targetUserReference = _firestore
        .collection('users')
        .doc(cleanTargetUserId);
    final followingReference = _followingReference(
      followerUserId: currentUser.uid,
      followingUserId: cleanTargetUserId,
    );
    final followerReference = _followerReference(
      followingUserId: cleanTargetUserId,
      followerUserId: currentUser.uid,
    );

    await _firestore.runTransaction<void>((transaction) async {
      final currentUserSnapshot = await transaction.get(currentUserReference);
      final targetUserSnapshot = await transaction.get(targetUserReference);
      final followingSnapshot = await transaction.get(followingReference);
      final followerSnapshot = await transaction.get(followerReference);

      if (!currentUserSnapshot.exists) {
        throw const FollowException(
          'Kendi kullanıcı profilin bulunamadı. Yeniden giriş yapıp dene.',
        );
      }

      if (!targetUserSnapshot.exists) {
        throw const FollowException(
          'Takip etmek istediğin kullanıcı artık mevcut değil.',
        );
      }

      if (followingSnapshot.exists && followerSnapshot.exists) {
        return;
      }

      if (followingSnapshot.exists != followerSnapshot.exists) {
        throw const FollowException(
          'Takip kaydı tutarsız. İşlemi yeniden denemeden önce kayıtları onar.',
        );
      }

      final mutationId = _newMutationId(
        followerId: currentUser.uid,
        followingId: cleanTargetUserId,
      );
      final mutation = _followMutation(
        id: mutationId,
        followerId: currentUser.uid,
        followingId: cleanTargetUserId,
        operation: 'follow',
      );
      final serverTime = FieldValue.serverTimestamp();
      final currentUserData =
          currentUserSnapshot.data() ?? const <String, dynamic>{};
      final targetUserData =
          targetUserSnapshot.data() ?? const <String, dynamic>{};

      transaction.update(currentUserReference, <String, dynamic>{
        'followingCount':
            _readNonNegativeInt(currentUserData['followingCount']) + 1,
        'followMutation': mutation,
        'updatedAt': serverTime,
      });

      transaction.update(targetUserReference, <String, dynamic>{
        'followersCount':
            _readNonNegativeInt(targetUserData['followersCount']) + 1,
        'followMutation': mutation,
        'updatedAt': serverTime,
      });

      final relationshipData = <String, dynamic>{
        'schemaVersion': 2,
        'followerId': currentUser.uid,
        'followingId': cleanTargetUserId,
        'mutationId': mutationId,
        'createdAt': serverTime,
      };

      transaction.set(followingReference, relationshipData);
      transaction.set(followerReference, relationshipData);
    });
  }

  Future<void> unfollow(String targetUserId) async {
    final currentUser = _requireCurrentUser();
    final cleanTargetUserId = _validateTargetUserId(
      currentUserId: currentUser.uid,
      targetUserId: targetUserId,
    );

    final currentUserReference = _firestore
        .collection('users')
        .doc(currentUser.uid);
    final targetUserReference = _firestore
        .collection('users')
        .doc(cleanTargetUserId);
    final followingReference = _followingReference(
      followerUserId: currentUser.uid,
      followingUserId: cleanTargetUserId,
    );
    final followerReference = _followerReference(
      followingUserId: cleanTargetUserId,
      followerUserId: currentUser.uid,
    );

    await _firestore.runTransaction<void>((transaction) async {
      final currentUserSnapshot = await transaction.get(currentUserReference);
      final targetUserSnapshot = await transaction.get(targetUserReference);
      final followingSnapshot = await transaction.get(followingReference);
      final followerSnapshot = await transaction.get(followerReference);

      if (!followingSnapshot.exists && !followerSnapshot.exists) {
        return;
      }

      if (!currentUserSnapshot.exists || !targetUserSnapshot.exists) {
        throw const FollowException(
          'Takip ilişkisine ait kullanıcı profili bulunamadı.',
        );
      }

      if (followingSnapshot.exists != followerSnapshot.exists) {
        throw const FollowException(
          'Takip kaydı tutarsız. Kayıtların onarılması gerekiyor.',
        );
      }

      final followingMutationId =
          followingSnapshot.data()?['mutationId']?.toString().trim() ?? '';
      final followerMutationId =
          followerSnapshot.data()?['mutationId']?.toString().trim() ?? '';

      if (followingMutationId.isEmpty && followerMutationId.isEmpty) {
        transaction.delete(followingReference);
        transaction.delete(followerReference);
        return;
      }

      if (followingMutationId.isEmpty ||
          followerMutationId.isEmpty ||
          followingMutationId != followerMutationId) {
        throw const FollowException(
          'Takip kaydı güvenli sayaç sistemiyle eşleşmiyor.',
        );
      }

      final currentUserData =
          currentUserSnapshot.data() ?? const <String, dynamic>{};
      final targetUserData =
          targetUserSnapshot.data() ?? const <String, dynamic>{};
      final followingCount = _readNonNegativeInt(
        currentUserData['followingCount'],
      );
      final followersCount = _readNonNegativeInt(
        targetUserData['followersCount'],
      );

      if (followingCount == 0 || followersCount == 0) {
        throw const FollowException(
          'Takip sayaçları kayıtlarla eşleşmiyor. Sayaç onarımı gerekiyor.',
        );
      }

      final mutationId = _newMutationId(
        followerId: currentUser.uid,
        followingId: cleanTargetUserId,
      );
      final mutation = _followMutation(
        id: mutationId,
        followerId: currentUser.uid,
        followingId: cleanTargetUserId,
        operation: 'unfollow',
      );
      final serverTime = FieldValue.serverTimestamp();

      transaction.update(currentUserReference, <String, dynamic>{
        'followingCount': followingCount - 1,
        'followMutation': mutation,
        'updatedAt': serverTime,
      });

      transaction.update(targetUserReference, <String, dynamic>{
        'followersCount': followersCount - 1,
        'followMutation': mutation,
        'updatedAt': serverTime,
      });

      transaction.delete(followingReference);
      transaction.delete(followerReference);
    });
  }

  User _requireCurrentUser() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw const FollowException(
        'Takip işlemi için yeniden giriş yapmalısın.',
      );
    }

    return currentUser;
  }

  String _validateTargetUserId({
    required String currentUserId,
    required String targetUserId,
  }) {
    final cleanTargetUserId = targetUserId.trim();

    if (cleanTargetUserId.isEmpty) {
      throw const FollowException('Geçerli bir kullanıcı seçilmedi.');
    }

    if (cleanTargetUserId == currentUserId) {
      throw const FollowException('Kendi hesabını takip edemezsin.');
    }

    return cleanTargetUserId;
  }

  DocumentReference<Map<String, dynamic>> _followingReference({
    required String followerUserId,
    required String followingUserId,
  }) {
    return _firestore
        .collection('users')
        .doc(followerUserId)
        .collection('following')
        .doc(followingUserId);
  }

  DocumentReference<Map<String, dynamic>> _followerReference({
    required String followingUserId,
    required String followerUserId,
  }) {
    return _firestore
        .collection('users')
        .doc(followingUserId)
        .collection('followers')
        .doc(followerUserId);
  }

  Map<String, dynamic> _followMutation({
    required String id,
    required String followerId,
    required String followingId,
    required String operation,
  }) {
    return <String, dynamic>{
      'id': id,
      'actorId': followerId,
      'targetId': followingId,
      'operation': operation,
    };
  }

  String _newMutationId({
    required String followerId,
    required String followingId,
  }) {
    return '${followerId}_${followingId}_${DateTime.now().microsecondsSinceEpoch}';
  }

  int _readNonNegativeInt(Object? value) {
    final parsed = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;

    return parsed < 0 ? 0 : parsed;
  }

  DateTime? _readDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}

class FollowException implements Exception {
  const FollowException(this.message);

  final String message;

  @override
  String toString() => message;
}
