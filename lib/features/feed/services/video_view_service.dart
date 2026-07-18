import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/application/auth_service.dart';
import '../feed_repository.dart';

final videoViewServiceProvider = Provider<VideoViewService>((ref) {
  return VideoViewService(
    firestore: ref.watch(feedFirestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
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

  final Set<String> _recordedSessionKeys = <String>{};

  final Map<String, Future<bool>> _inFlightOperations =
      <String, Future<bool>>{};

  static int qualifiedWatchThresholdMs({required int durationMs}) {
    if (durationMs <= 0) {
      return 0;
    }

    final proportional = (durationMs * 0.20).round();

    final bounded = proportional.clamp(2000, 5000);

    return math.min(durationMs, bounded);
  }

  static bool isQualified({required int watchedMs, required int durationMs}) {
    if (watchedMs <= 0 || durationMs <= 0) {
      return false;
    }

    return watchedMs >= qualifiedWatchThresholdMs(durationMs: durationMs);
  }

  Future<bool> ensureQualifiedViewRecorded({
    required String videoId,
    required String uploaderId,
    required int watchedMs,
    required int durationMs,
    String sessionId = '',
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

    final operationKey = '${user.uid}:$cleanVideoId';

    if (_recordedSessionKeys.contains(operationKey)) {
      return true;
    }

    final existingOperation = _inFlightOperations[operationKey];

    if (existingOperation != null) {
      return existingOperation;
    }

    final operation = _recordView(
      userId: user.uid,
      videoId: cleanVideoId,
      suppliedUploaderId: uploaderId.trim(),
      watchedMs: watchedMs,
      suppliedDurationMs: durationMs,
      sessionId: sessionId.trim(),
    );

    _inFlightOperations[operationKey] = operation;

    try {
      final recorded = await operation;

      if (recorded) {
        _recordedSessionKeys.add(operationKey);
      }

      return recorded;
    } finally {
      if (identical(_inFlightOperations[operationKey], operation)) {
        _inFlightOperations.remove(operationKey);
      }
    }
  }

  Future<bool> _recordView({
    required String userId,
    required String videoId,
    required String suppliedUploaderId,
    required int watchedMs,
    required int suppliedDurationMs,
    required String sessionId,
  }) async {
    if (_auth.currentUser?.uid != userId) {
      return true;
    }

    final videoReference = _firestore.collection('videos').doc(videoId);

    final viewReference = videoReference.collection('views').doc(userId);

    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        final videoSnapshot = await transaction.get(videoReference);

        final viewSnapshot = await transaction.get(viewReference);

        if (!videoSnapshot.exists) {
          return true;
        }

        if (viewSnapshot.exists) {
          return true;
        }

        final videoData = videoSnapshot.data() ?? const <String, dynamic>{};

        final storedUploaderId =
            videoData['uploaderId']?.toString().trim() ?? suppliedUploaderId;

        if (storedUploaderId == userId) {
          return true;
        }

        final status =
            (videoData['status'] ?? videoData['processingStatus'])
                ?.toString()
                .trim()
                .toLowerCase() ??
            'ready';

        final visibility =
            videoData['visibility']?.toString().trim().toLowerCase() ??
            'public';

        if (status != 'ready' || visibility != 'public') {
          return true;
        }

        final storedDurationMs = _readPositiveInt(
          videoData['durationMs'],
          fallback: suppliedDurationMs,
        );

        if (!isQualified(watchedMs: watchedMs, durationMs: storedDurationMs)) {
          return false;
        }

        final safeWatchedMs = watchedMs.clamp(0, storedDurationMs).toInt();

        final watchedFraction = storedDurationMs <= 0
            ? 0.0
            : (safeWatchedMs / storedDurationMs).clamp(0, 1).toDouble();

        final serverTime = FieldValue.serverTimestamp();

        transaction.set(viewReference, <String, dynamic>{
          'schemaVersion': 2,
          'videoId': videoId,
          'userId': userId,
          'qualifiedWatchMs': safeWatchedMs,
          'durationMs': storedDurationMs,
          'watchedFraction': watchedFraction,
          'sessionId': sessionId,
          'createdAt': serverTime,
        });

        transaction.update(videoReference, <String, dynamic>{
          'viewsCount': FieldValue.increment(1),
          'updatedAt': serverTime,
        });

        return true;
      });
    } on FirebaseException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'Video görüntülenmesi kaydedilemedi: '
          '${error.code}',
        );

        debugPrintStack(stackTrace: stackTrace);
      }

      switch (error.code) {
        case 'permission-denied':
        case 'unauthenticated':
          return true;

        case 'unavailable':
        case 'deadline-exceeded':
        case 'aborted':
        case 'network-request-failed':
          return false;

        default:
          return false;
      }
    }
  }

  int _readPositiveInt(Object? value, {required int fallback}) {
    final parsed = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;

    if (parsed > 0) {
      return parsed;
    }

    return fallback > 0 ? fallback : 1;
  }
}
