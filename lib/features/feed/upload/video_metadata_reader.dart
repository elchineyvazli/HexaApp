import 'dart:async';
import 'dart:io';

import 'package:video_player/video_player.dart';

import '../video_upload_limits.dart';

class VideoMetadata {
  const VideoMetadata({
    required this.durationMs,
    required this.width,
    required this.height,
  });

  final int durationMs;
  final int width;
  final int height;

  double get aspectRatio => width / height;
}

class VideoMetadataReadException implements Exception {
  const VideoMetadataReadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VideoMetadataReader {
  const VideoMetadataReader();

  Future<VideoMetadata> read(File videoFile) async {
    final controller = VideoPlayerController.file(videoFile);

    try {
      await controller
          .initialize()
          .timeout(VideoUploadLimits.metadataReadTimeout);

      final value = controller.value;

      if (!value.isInitialized) {
        throw const VideoMetadataReadException(
          'Video oynatıcısı hazırlanamadı.',
        );
      }

      if (value.hasError) {
        final description = value.errorDescription?.trim();

        throw VideoMetadataReadException(
          description == null || description.isEmpty
              ? 'Video dosyası çözümlenemedi.'
              : 'Video dosyası çözümlenemedi: $description',
        );
      }

      final duration = value.duration;
      final rawWidth = value.size.width;
      final rawHeight = value.size.height;

      _validateDuration(duration);
      _validateRawDimensions(rawWidth: rawWidth, rawHeight: rawHeight);

      final width = rawWidth.round();
      final height = rawHeight.round();

      _validateRoundedDimensions(width: width, height: height);

      return VideoMetadata(
        durationMs: duration.inMilliseconds,
        width: width,
        height: height,
      );
    } on TimeoutException {
      throw const VideoMetadataReadException(
        'Video bilgileri zamanında okunamadı. Başka bir video dene.',
      );
    } on VideoMetadataReadException {
      rethrow;
    } catch (error) {
      throw VideoMetadataReadException(
        'Video bilgileri okunamadı: ${_shortError(error)}',
      );
    } finally {
      try {
        await controller.dispose();
      } catch (_) {
        // Dispose hatası asıl hazırlama sonucunu değiştirmemeli.
      }
    }
  }

  void _validateDuration(Duration duration) {
    if (duration < VideoUploadLimits.minDuration) {
      throw const VideoMetadataReadException(
        'Video en az 1 saniye olmalı.',
      );
    }

    if (duration > VideoUploadLimits.maxDuration) {
      throw const VideoMetadataReadException(
        'Video en fazla 3 dakika olabilir.',
      );
    }
  }

  void _validateRawDimensions({
    required double rawWidth,
    required double rawHeight,
  }) {
    if (!rawWidth.isFinite ||
        !rawHeight.isFinite ||
        rawWidth <= 0 ||
        rawHeight <= 0) {
      throw const VideoMetadataReadException(
        'Videonun genişlik ve yükseklik bilgisi okunamadı.',
      );
    }
  }

  void _validateRoundedDimensions({
    required int width,
    required int height,
  }) {
    if (width <= 0 ||
        height <= 0 ||
        width > VideoUploadLimits.maxDimension ||
        height > VideoUploadLimits.maxDimension) {
      throw const VideoMetadataReadException(
        'Video çözünürlüğü desteklenen aralığın dışında.',
      );
    }

    final aspectRatio = width / height;

    if (!aspectRatio.isFinite ||
        aspectRatio < VideoUploadLimits.minAspectRatio ||
        aspectRatio > VideoUploadLimits.maxAspectRatio) {
      throw const VideoMetadataReadException(
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
