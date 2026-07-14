import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoUploadLimits {
  const VideoUploadLimits._();

  static const int maxFileSizeBytes = 200 * 1024 * 1024;
  static const Duration maxDuration = Duration(minutes: 3);
}

class PreparedVideoUpload {
  const PreparedVideoUpload({
    required this.videoFile,
    required this.thumbnailBytes,
    required this.fileSizeBytes,
    required this.durationMs,
    required this.width,
    required this.height,
  });

  final File videoFile;
  final Uint8List thumbnailBytes;
  final int fileSizeBytes;
  final int durationMs;
  final int width;
  final int height;

  double get aspectRatio {
    if (width <= 0 || height <= 0) {
      return 9 / 16;
    }

    return width / height;
  }
}

class VideoPreparationException implements Exception {
  const VideoPreparationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VideoUploadPreparer {
  const VideoUploadPreparer();

  Future<PreparedVideoUpload> prepare(File videoFile) async {
    await _validateFile(videoFile);

    final fileSizeBytes = await videoFile.length();
    final metadata = await _readVideoMetadata(videoFile);
    final thumbnailBytes = await _createThumbnail(
      videoFile: videoFile,
      durationMs: metadata.durationMs,
    );

    return PreparedVideoUpload(
      videoFile: videoFile,
      thumbnailBytes: thumbnailBytes,
      fileSizeBytes: fileSizeBytes,
      durationMs: metadata.durationMs,
      width: metadata.width,
      height: metadata.height,
    );
  }

  Future<void> _validateFile(File videoFile) async {
    if (!await videoFile.exists()) {
      throw const VideoPreparationException(
        'Seçilen video dosyası bulunamadı.',
      );
    }

    final fileSizeBytes = await videoFile.length();

    if (fileSizeBytes <= 0) {
      throw const VideoPreparationException('Seçilen video dosyası boş.');
    }

    if (fileSizeBytes > VideoUploadLimits.maxFileSizeBytes) {
      throw const VideoPreparationException('Video en fazla 200 MB olabilir.');
    }
  }

  Future<_VideoMetadata> _readVideoMetadata(File videoFile) async {
    final controller = VideoPlayerController.file(videoFile);

    try {
      await controller.initialize();

      final duration = controller.value.duration;
      final size = controller.value.size;

      _validateDuration(duration);
      _validateDimensions(size);

      return _VideoMetadata(
        durationMs: duration.inMilliseconds,
        width: size.width.round(),
        height: size.height.round(),
      );
    } on VideoPreparationException {
      rethrow;
    } catch (error) {
      throw VideoPreparationException(
        'Video bilgileri okunamadı: ${_shortError(error)}',
      );
    } finally {
      await controller.dispose();
    }
  }

  Future<Uint8List> _createThumbnail({
    required File videoFile,
    required int durationMs,
  }) async {
    final preferredTimeMs = math.min(1000, math.max(0, durationMs ~/ 4));

    final attempts = <int>[preferredTimeMs, 0];

    for (final timeMs in attempts) {
      try {
        final bytes = await VideoThumbnail.thumbnailData(
          video: videoFile.path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 720,
          timeMs: timeMs,
          quality: 85,
        );

        if (bytes != null && bytes.isNotEmpty) {
          return bytes;
        }
      } catch (_) {
        // Bir sonraki zaman noktasını dene.
      }
    }

    throw const VideoPreparationException(
      'Video kapak görseli oluşturulamadı.',
    );
  }

  void _validateDuration(Duration duration) {
    if (duration <= Duration.zero) {
      throw const VideoPreparationException('Videonun süresi okunamadı.');
    }

    if (duration > VideoUploadLimits.maxDuration) {
      throw const VideoPreparationException(
        'Video en fazla 3 dakika olabilir.',
      );
    }
  }

  void _validateDimensions(Size size) {
    if (size.width <= 0 || size.height <= 0) {
      throw const VideoPreparationException(
        'Videonun genişlik ve yükseklik bilgisi okunamadı.',
      );
    }

    final aspectRatio = size.width / size.height;

    if (!aspectRatio.isFinite || aspectRatio < 0.2 || aspectRatio > 5) {
      throw const VideoPreparationException(
        'Video görüntü oranı desteklenmiyor.',
      );
    }
  }

  String _shortError(Object error) {
    final text = error.toString().trim();

    if (text.length <= 120) {
      return text;
    }

    return '${text.substring(0, 120)}...';
  }
}

class _VideoMetadata {
  const _VideoMetadata({
    required this.durationMs,
    required this.width,
    required this.height,
  });

  final int durationMs;
  final int width;
  final int height;
}
