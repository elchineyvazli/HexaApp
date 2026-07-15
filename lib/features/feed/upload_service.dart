import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'video_upload_preparer.dart';
import 'video_upload_validation.dart';

final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
    validator: ref.watch(videoUploadValidatorProvider),
  );
});

class VideoUploadProgress {
  const VideoUploadProgress({required this.value, required this.message});

  final double value;
  final String message;
}

class VideoUploadException implements Exception {
  const VideoUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UploadService {
  UploadService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required VideoUploadValidator validator,
  }) : _auth = auth,
       _firestore = firestore,
       _storage = storage,
       _validator = validator;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final VideoUploadValidator _validator;

  Stream<VideoUploadProgress> uploadVideo({
    required PreparedVideoUpload preparedVideo,
    required String caption,
  }) async* {
    final initialUser = _auth.currentUser;

    if (initialUser == null) {
      throw const VideoUploadException('Video yüklemek için giriş yapmalısın.');
    }

    final cleanCaption = _validateCaption(caption);
    final validated = await _validatePreparedVideo(preparedVideo);

    _ensureSameUser(initialUser.uid);
    await _loadUploaderProfile(initialUser.uid);

    final videoDocument = _firestore.collection('videos').doc();
    final videoId = videoDocument.id;
    final format = validated.format;

    final videoReference = _storage
        .ref()
        .child('videos')
        .child(initialUser.uid)
        .child(videoId)
        .child('source.${format.extension}');

    final thumbnailReference = _storage
        .ref()
        .child('thumbnails')
        .child(initialUser.uid)
        .child(videoId)
        .child('cover.jpg');

    var videoUploaded = false;
    var thumbnailUploaded = false;
    var documentCreated = false;
    var authChanged = false;
    UploadTask? activeTask;

    final authSubscription = _auth.authStateChanges().listen((user) {
      if (user?.uid == initialUser.uid) {
        return;
      }

      authChanged = true;
      final task = activeTask;

      if (task != null) {
        unawaited(task.cancel());
      }
    });

    try {
      _ensureSameUser(initialUser.uid);

      activeTask = videoReference.putFile(
        validated.preparedVideo.videoFile,
        SettableMetadata(
          contentType: format.contentType,
          customMetadata: <String, String>{
            'ownerId': initialUser.uid,
            'videoId': videoId,
            'schemaVersion': '2',
            'assetKind': 'videoSource',
            'sourceFormat': format.extension,
            'durationMs': '${validated.preparedVideo.durationMs}',
            'width': '${validated.preparedVideo.width}',
            'height': '${validated.preparedVideo.height}',
            'aspectRatio': validated.preparedVideo.aspectRatio.toStringAsFixed(
              6,
            ),
            'compressionApplied': '${validated.preparedVideo.wasCompressed}',
            'originalSizeBytes':
                '${validated.preparedVideo.originalFileSizeBytes}',
          },
        ),
      );

      await for (final snapshot in activeTask!.snapshotEvents) {
        final totalBytes = snapshot.totalBytes;
        final ratio = totalBytes <= 0
            ? 0.0
            : snapshot.bytesTransferred / totalBytes;

        yield VideoUploadProgress(
          value: (ratio * 0.86).clamp(0.0, 0.86).toDouble(),
          message: 'Video yükleniyor',
        );
      }

      _throwIfAuthChanged(authChanged, initialUser.uid);
      videoUploaded = true;
      activeTask = null;

      final videoUrl = await videoReference.getDownloadURL();

      yield const VideoUploadProgress(
        value: 0.88,
        message: 'Kapak görseli yükleniyor',
      );

      _ensureSameUser(initialUser.uid);

      activeTask = thumbnailReference.putData(
        validated.preparedVideo.thumbnailBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: <String, String>{
            'ownerId': initialUser.uid,
            'videoId': videoId,
            'schemaVersion': '2',
            'assetKind': 'thumbnail',
          },
        ),
      );

      await for (final snapshot in activeTask!.snapshotEvents) {
        final totalBytes = snapshot.totalBytes;
        final ratio = totalBytes <= 0
            ? 0.0
            : snapshot.bytesTransferred / totalBytes;

        yield VideoUploadProgress(
          value: (0.88 + (ratio * 0.08)).clamp(0.88, 0.96).toDouble(),
          message: 'Kapak görseli yükleniyor',
        );
      }

      _throwIfAuthChanged(authChanged, initialUser.uid);
      thumbnailUploaded = true;
      activeTask = null;

      final thumbnailUrl = await thumbnailReference.getDownloadURL();

      yield const VideoUploadProgress(
        value: 0.97,
        message: 'Video yayınlanıyor',
      );

      _ensureSameUser(initialUser.uid);
      final profile = await _loadUploaderProfile(initialUser.uid);
      _ensureSameUser(initialUser.uid);

      final serverTime = FieldValue.serverTimestamp();

      await videoDocument.set(<String, dynamic>{
        'schemaVersion': 2,
        'uploadSchemaVersion': 2,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'videoStoragePath': videoReference.fullPath,
        'thumbnailStoragePath': thumbnailReference.fullPath,
        'sourceFormat': format.extension,
        'sourceContentType': format.contentType,
        'sourceSizeBytes': validated.fileSizeBytes,
        'thumbnailSizeBytes': validated.thumbnailSizeBytes,
        'hlsUrl': '',
        'renditionUrls': <String, String>{},
        'uploaderId': initialUser.uid,
        'username': profile.username,
        'uploaderDisplayName': profile.displayName,
        'uploaderAvatarUrl': profile.avatarUrl,
        'caption': cleanCaption,
        'description': cleanCaption,
        'width': validated.preparedVideo.width,
        'height': validated.preparedVideo.height,
        'aspectRatio': validated.preparedVideo.aspectRatio,
        'durationMs': validated.preparedVideo.durationMs,
        'viewsCount': 0,
        'signalCount': 0,
        'uniqueSignalersCount': 0,
        'signalDistribution': <String, int>{},
        'likesCount': 0,
        'commentsCount': 0,
        'sharesCount': 0,
        'artifactCount': 0,
        'uniqueArtifactSupportersCount': 0,
        'impactScore': 0,
        'processingStatus': 'ready',
        'status': 'ready',
        'visibility': 'public',
        'createdAt': serverTime,
        'updatedAt': serverTime,
      });

      documentCreated = true;

      yield const VideoUploadProgress(
        value: 1,
        message: 'Video yayınlandı',
      );
    } on FirebaseException catch (error) {
      if (!documentCreated) {
        await _cleanup(
          videoReference: videoReference,
          thumbnailReference: thumbnailReference,
          videoUploaded: videoUploaded,
          thumbnailUploaded: thumbnailUploaded,
        );
      }

      if (authChanged) {
        throw const VideoUploadException(
          'Oturum değiştiği için video yükleme durduruldu.',
        );
      }

      throw VideoUploadException(_firebaseMessage(error));
    } catch (error) {
      if (!documentCreated) {
        await _cleanup(
          videoReference: videoReference,
          thumbnailReference: thumbnailReference,
          videoUploaded: videoUploaded,
          thumbnailUploaded: thumbnailUploaded,
        );
      }

      if (error is VideoUploadException) {
        rethrow;
      }

      throw VideoUploadException('Video yüklenemedi: ${_shortError(error)}');
    } finally {
      activeTask = null;
      await authSubscription.cancel();
    }
  }

  Future<ValidatedVideoUpload> _validatePreparedVideo(
    PreparedVideoUpload preparedVideo,
  ) async {
    try {
      return await _validator.validate(preparedVideo);
    } on VideoUploadValidationException catch (error) {
      throw VideoUploadException(error.message);
    }
  }

  String _validateCaption(String caption) {
    final cleanCaption = caption.trim();

    if (cleanCaption.isEmpty) {
      throw const VideoUploadException('Video açıklaması boş bırakılamaz.');
    }

    if (cleanCaption.length > 300) {
      throw const VideoUploadException(
        'Video açıklaması en fazla 300 karakter olabilir.',
      );
    }

    return cleanCaption;
  }

  Future<_UploaderProfile> _loadUploaderProfile(String userId) async {
    final snapshot = await _firestore.collection('users').doc(userId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      throw const VideoUploadException(
        'Kullanıcı profilin bulunamadı. Yeniden giriş yapıp dene.',
      );
    }

    if (data['isProfileCompleted'] != true) {
      throw const VideoUploadException(
        'Video yüklemeden önce profilini tamamlamalısın.',
      );
    }

    final username = data['username']?.toString().trim() ?? '';
    final displayName = data['displayName']?.toString().trim() ?? '';
    final avatarUrl = _firstNonEmpty(<Object?>[
      data['profileImageUrl'],
      data['photoUrl'],
    ]);

    if (username.length < 2 || displayName.isEmpty) {
      throw const VideoUploadException(
        'Profil kullanıcı adı veya görünen ad bilgisi eksik.',
      );
    }

    return _UploaderProfile(
      username: username.startsWith('@') ? username : '@$username',
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }

  void _ensureSameUser(String expectedUserId) {
    if (_auth.currentUser?.uid != expectedUserId) {
      throw const VideoUploadException(
        'Oturum değiştiği için video yükleme durduruldu.',
      );
    }
  }

  void _throwIfAuthChanged(bool authChanged, String expectedUserId) {
    if (authChanged) {
      throw const VideoUploadException(
        'Oturum değiştiği için video yükleme durduruldu.',
      );
    }

    _ensureSameUser(expectedUserId);
  }

  Future<void> _cleanup({
    required Reference videoReference,
    required Reference thumbnailReference,
    required bool videoUploaded,
    required bool thumbnailUploaded,
  }) async {
    if (thumbnailUploaded) {
      await _safeDelete(thumbnailReference);
    }

    if (videoUploaded) {
      await _safeDelete(videoReference);
    }
  }

  Future<void> _safeDelete(Reference reference) async {
    try {
      await reference.delete();
    } catch (_) {
      // Temizleme hatası ana yükleme hatasını gizlememeli.
    }
  }

  String _firebaseMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
      case 'unauthorized':
      case 'unauthenticated':
        return 'Firebase güvenlik kuralları yüklemeye izin vermedi.';
      case 'canceled':
        return 'Video yükleme iptal edildi.';
      case 'retry-limit-exceeded':
      case 'unavailable':
      case 'network-request-failed':
        return 'Bağlantıyı kontrol edip tekrar dene.';
      case 'quota-exceeded':
        return 'Firebase depolama kotası dolmuş.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Firebase yüklemeyi tamamlayamadı.';
    }
  }

  String _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  String _shortError(Object error) {
    final text = error.toString().trim();

    if (text.length <= 140) {
      return text;
    }

    return '${text.substring(0, 140)}...';
  }
}

class _UploaderProfile {
  const _UploaderProfile({
    required this.username,
    required this.displayName,
    required this.avatarUrl,
  });

  final String username;
  final String displayName;
  final String avatarUrl;
}
