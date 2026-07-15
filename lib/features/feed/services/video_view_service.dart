import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final videoViewServiceProvider = Provider<VideoViewService>((ref) {
  return VideoViewService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class VideoViewService {
  VideoViewService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static bool isQualified({required int watchedMs, required int durationMs}) {
    if (watchedMs <= 0 || durationMs <= 0) {
      return false;
    }

    final watchedAtLeastTwoSeconds = watchedMs >= 2000;
    final watchedAtLeastTwentyPercent = watchedMs * 5 >= durationMs;

    return watchedAtLeastTwoSeconds || watchedAtLeastTwentyPercent;
  }

  /// true:
  /// - görüntülenme kaydedildi,
  /// - önceden kaydedilmişti,
  /// - kendi videosu olduğu için sayılmayacak.
  ///
  /// false:
  /// - henüz yeterli izlenme oluşmadı.
  Future<bool> ensureQualifiedViewRecorded({
    required String videoId,
    required String uploaderId,
    required int watchedMs,
    required int durationMs,
  }) async {
    final user = _auth.currentUser;
    final cleanVideoId = videoId.trim();

    if (user == null || cleanVideoId.isEmpty) {
      return true;
    }

    if (uploaderId.trim() == user.uid) {
      return true;
    }

    if (!isQualified(watchedMs: watchedMs, durationMs: durationMs)) {
      return false;
    }

    final videoReference = _firestore.collection('videos').doc(cleanVideoId);

    final viewReference = videoReference.collection('views').doc(user.uid);

    return _firestore.runTransaction<bool>((transaction) async {
      final videoSnapshot = await transaction.get(videoReference);
      final viewSnapshot = await transaction.get(viewReference);

      if (!videoSnapshot.exists) {
        return true;
      }

      if (viewSnapshot.exists) {
        return true;
      }

      final videoData = videoSnapshot.data() ?? const <String, dynamic>{};

      final storedUploaderId = videoData['uploaderId']?.toString().trim() ?? '';

      if (storedUploaderId == user.uid) {
        return true;
      }

      final storedDurationMs = _readPositiveInt(
        videoData['durationMs'],
        fallback: durationMs,
      );

      if (!isQualified(watchedMs: watchedMs, durationMs: storedDurationMs)) {
        return false;
      }

      final currentViewsCount = _readNonNegativeInt(videoData['viewsCount']);

      final safeWatchedMs = watchedMs.clamp(0, 24 * 60 * 60 * 1000).toInt();

      final serverTime = FieldValue.serverTimestamp();

      transaction.set(viewReference, <String, dynamic>{
        'videoId': cleanVideoId,
        'userId': user.uid,
        'qualifiedWatchMs': safeWatchedMs,
        'durationMs': storedDurationMs,
        'createdAt': serverTime,
      });

      transaction.update(videoReference, <String, dynamic>{
        'viewsCount': currentViewsCount + 1,
        'updatedAt': serverTime,
      });

      return true;
    });
  }

  int _readPositiveInt(Object? value, {required int fallback}) {
    final parsed = _readInt(value);

    if (parsed > 0) {
      return parsed;
    }

    return fallback > 0 ? fallback : 1;
  }

  int _readNonNegativeInt(Object? value) {
    final parsed = _readInt(value);
    return parsed < 0 ? 0 : parsed;
  }

  int _readInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
