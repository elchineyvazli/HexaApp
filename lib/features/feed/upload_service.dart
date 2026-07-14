import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'video_upload_preparer.dart';

final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
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
  }) : _auth = auth,
       _firestore = firestore,
       _storage = storage;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Stream<VideoUploadProgress> uploadVideo({
    required PreparedVideoUpload preparedVideo,
    required String caption,
  }) async* {
    final user = _auth.currentUser;

    if (user == null) {
      throw const VideoUploadException('Video yüklemek için giriş yapmalısın.');
    }

    final cleanCaption = caption.trim();

    if (cleanCaption.isEmpty) {
      throw const VideoUploadException('Video açıklaması boş bırakılamaz.');
    }

    if (cleanCaption.length > 300) {
      throw const VideoUploadException(
        'Video açıklaması en fazla 300 karakter olabilir.',
      );
    }

    final videoDocument = _firestore.collection('videos').doc();
    final videoId = videoDocument.id;

    final extension = _readVideoExtension(preparedVideo.videoFile.path);

    final videoReference = _storage
        .ref()
        .child('videos')
        .child(user.uid)
        .child('$videoId.$extension');

    final thumbnailReference = _storage
        .ref()
        .child('thumbnails')
        .child(user.uid)
        .child('$videoId.jpg');

    var videoUploaded = false;
    var thumbnailUploaded = false;
    var documentCreated = false;

    try {
      final videoTask = videoReference.putFile(
        preparedVideo.videoFile,
        SettableMetadata(
          contentType: _videoContentType(extension),
          customMetadata: <String, String>{
            'ownerId': user.uid,
            'videoId': videoId,
          },
        ),
      );

      await for (final snapshot in videoTask.snapshotEvents) {
        final totalBytes = snapshot.totalBytes;

        final ratio = totalBytes <= 0
            ? 0.0
            : snapshot.bytesTransferred / totalBytes;

        yield VideoUploadProgress(
          value: (ratio * 0.88).clamp(0.0, 0.88).toDouble(),
          message: 'Video yükleniyor',
        );
      }

      videoUploaded = true;

      final videoUrl = await videoReference.getDownloadURL();

      yield const VideoUploadProgress(
        value: 0.90,
        message: 'Kapak görseli yükleniyor',
      );

      await thumbnailReference.putData(
        preparedVideo.thumbnailBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: <String, String>{
            'ownerId': user.uid,
            'videoId': videoId,
          },
        ),
      );

      thumbnailUploaded = true;

      final thumbnailUrl = await thumbnailReference.getDownloadURL();

      yield const VideoUploadProgress(
        value: 0.97,
        message: 'Video yayınlanıyor',
      );

      final profile = await _loadUploaderProfile(user);

      final serverTime = FieldValue.serverTimestamp();

      await videoDocument.set(<String, dynamic>{
        'schemaVersion': 2,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'uploaderId': user.uid,
        'username': profile.username,
        'uploaderDisplayName': profile.displayName,
        'uploaderAvatarUrl': profile.avatarUrl,
        'caption': cleanCaption,
        'description': cleanCaption,
        'width': preparedVideo.width,
        'height': preparedVideo.height,
        'aspectRatio': preparedVideo.aspectRatio,
        'durationMs': preparedVideo.durationMs,
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

      yield const VideoUploadProgress(value: 1, message: 'Video yayınlandı');
    } on FirebaseException catch (error) {
      if (!documentCreated) {
        await _cleanup(
          videoReference: videoReference,
          thumbnailReference: thumbnailReference,
          videoUploaded: videoUploaded,
          thumbnailUploaded: thumbnailUploaded,
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
    }
  }

  Future<_UploaderProfile> _loadUploaderProfile(User user) async {
    try {
      final snapshot = await _firestore.collection('users').doc(user.uid).get();

      final data = snapshot.data() ?? const <String, dynamic>{};

      final username = _normalizeUsername(
        _firstNonEmpty(<Object?>[
          data['username'],
          data['usernameKey'],
          user.email?.split('@').first,
          'hexa_user',
        ]),
      );

      return _UploaderProfile(
        username: username,
        displayName: _firstNonEmpty(<Object?>[
          data['displayName'],
          user.displayName,
          username.replaceFirst('@', ''),
        ]),
        avatarUrl: _firstNonEmpty(<Object?>[
          data['profileImageUrl'],
          data['photoUrl'],
          user.photoURL,
        ]),
      );
    } catch (_) {
      final username = _normalizeUsername(
        user.email?.split('@').first ?? 'hexa_user',
      );

      return _UploaderProfile(
        username: username,
        displayName: user.displayName ?? username.replaceFirst('@', ''),
        avatarUrl: user.photoURL ?? '',
      );
    }
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
      // Temizleme hatası ana hatayı gizlememeli.
    }
  }

  String _readVideoExtension(String path) {
    final cleanPath = path.split('?').first.replaceAll('\\', '/');

    final filename = cleanPath.split('/').last;
    final dotIndex = filename.lastIndexOf('.');

    if (dotIndex < 0 || dotIndex == filename.length - 1) {
      return 'mp4';
    }

    final extension = filename.substring(dotIndex + 1).toLowerCase();

    const supported = <String>{'mp4', 'mov', 'm4v', 'webm'};

    return supported.contains(extension) ? extension : 'mp4';
  }

  String _videoContentType(String extension) {
    switch (extension) {
      case 'mov':
        return 'video/quicktime';
      case 'm4v':
        return 'video/x-m4v';
      case 'webm':
        return 'video/webm';
      default:
        return 'video/mp4';
    }
  }

  String _firebaseMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
      case 'unauthorized':
      case 'unauthenticated':
        return 'Firebase izinleri video yüklemeye izin vermiyor.';

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

  String _normalizeUsername(String value) {
    final cleanValue = value.trim();

    if (cleanValue.isEmpty) {
      return '@hexa_user';
    }

    return cleanValue.startsWith('@') ? cleanValue : '@$cleanValue';
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
