import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:video_thumbnail/video_thumbnail.dart';

import '../video_upload_limits.dart';

class VideoThumbnailGenerationException implements Exception {
  const VideoThumbnailGenerationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VideoThumbnailGenerator {
  const VideoThumbnailGenerator();

  Future<Uint8List> generate({
    required File videoFile,
    required int durationMs,
  }) async {
    final attempts = _buildAttempts(durationMs);
    Object? lastError;

    for (final attempt in attempts) {
      try {
        final bytes = await VideoThumbnail.thumbnailData(
          video: videoFile.path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: attempt.maxWidth,
          timeMs: attempt.timeMs,
          quality: attempt.quality,
        ).timeout(VideoUploadLimits.thumbnailGenerationTimeout);

        if (bytes == null || bytes.isEmpty) {
          continue;
        }

        if (!_isJpeg(bytes)) {
          lastError = const VideoThumbnailGenerationException(
            'Üretilen kapak görseli geçerli bir JPEG değil.',
          );
          continue;
        }

        if (bytes.lengthInBytes > VideoUploadLimits.maxThumbnailSizeBytes) {
          lastError = const VideoThumbnailGenerationException(
            'Üretilen kapak görseli 8 MB sınırını aşıyor.',
          );
          continue;
        }

        return bytes;
      } on TimeoutException {
        lastError = const VideoThumbnailGenerationException(
          'Kapak görseli zamanında oluşturulamadı.',
        );
      } catch (error) {
        lastError = error;
      }
    }

    if (lastError is VideoThumbnailGenerationException) {
      throw lastError;
    }

    throw const VideoThumbnailGenerationException(
      'Video kapak görseli oluşturulamadı.',
    );
  }

  List<_ThumbnailAttempt> _buildAttempts(int durationMs) {
    final lastSafeTimeMs = durationMs > 250 ? durationMs - 250 : 0;

    int safeTime(int value) {
      if (value <= 0) {
        return 0;
      }

      if (value > lastSafeTimeMs) {
        return lastSafeTimeMs;
      }

      return value;
    }

    final candidateTimes = <int>[
      safeTime(durationMs ~/ 4),
      safeTime(1000),
      safeTime(durationMs ~/ 2),
      safeTime((durationMs * 3) ~/ 4),
      0,
    ];

    final uniqueTimes = <int>[];

    for (final timeMs in candidateTimes) {
      if (!uniqueTimes.contains(timeMs)) {
        uniqueTimes.add(timeMs);
      }
    }

    final attempts = <_ThumbnailAttempt>[
      for (final timeMs in uniqueTimes)
        _ThumbnailAttempt(
          timeMs: timeMs,
          maxWidth: VideoUploadLimits.thumbnailMaxWidth,
          quality: VideoUploadLimits.thumbnailQuality,
        ),
    ];

    // Büyük veya problemli karelerde daha küçük ve düşük kaliteli son deneme.
    if (uniqueTimes.isNotEmpty) {
      attempts.add(
        _ThumbnailAttempt(
          timeMs: uniqueTimes.first,
          maxWidth: VideoUploadLimits.thumbnailFallbackWidth,
          quality: VideoUploadLimits.thumbnailFallbackQuality,
        ),
      );
    }

    return attempts;
  }

  bool _isJpeg(Uint8List bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[bytes.length - 2] == 0xFF &&
        bytes[bytes.length - 1] == 0xD9;
  }
}

class _ThumbnailAttempt {
  const _ThumbnailAttempt({
    required this.timeMs,
    required this.maxWidth,
    required this.quality,
  });

  final int timeMs;
  final int maxWidth;
  final int quality;
}
