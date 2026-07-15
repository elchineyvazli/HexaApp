import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'video_upload_limits.dart';
import 'video_upload_preparer.dart';

final videoUploadValidatorProvider = Provider<VideoUploadValidator>((ref) {
  return const VideoUploadValidator();
});

enum VideoSourceFormat {
  mp4(extension: 'mp4', contentType: 'video/mp4'),
  mov(extension: 'mov', contentType: 'video/quicktime'),
  m4v(extension: 'm4v', contentType: 'video/x-m4v'),
  webm(extension: 'webm', contentType: 'video/webm');

  const VideoSourceFormat({required this.extension, required this.contentType});

  final String extension;
  final String contentType;
}

class ValidatedVideoUpload {
  const ValidatedVideoUpload({
    required this.preparedVideo,
    required this.format,
    required this.fileSizeBytes,
    required this.thumbnailSizeBytes,
  });

  final PreparedVideoUpload preparedVideo;
  final VideoSourceFormat format;
  final int fileSizeBytes;
  final int thumbnailSizeBytes;
}

class VideoUploadValidationException implements Exception {
  const VideoUploadValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VideoUploadValidator {
  const VideoUploadValidator();

  Future<ValidatedVideoUpload> validate(
    PreparedVideoUpload preparedVideo,
  ) async {
    final file = preparedVideo.videoFile;
    final stat = await file.stat();

    if (stat.type != FileSystemEntityType.file || stat.size <= 0) {
      throw const VideoUploadValidationException(
        'Hazırlanan video dosyası artık mevcut değil.',
      );
    }

    if (stat.size > VideoUploadLimits.maxUploadFileSizeBytes) {
      throw const VideoUploadValidationException(
        'Yüklenecek video en fazla 40 MB olabilir.',
      );
    }

    if (preparedVideo.fileSizeBytes != stat.size) {
      throw const VideoUploadValidationException(
        'Video dosyası hazırlandıktan sonra değişmiş. Yeniden seçmelisin.',
      );
    }

    _validateDimensionsAndDuration(preparedVideo);

    final header = await _readHeader(file);
    final format = _detectVideoFormat(header);

    if (format == null) {
      throw const VideoUploadValidationException(
        'Video biçimi doğrulanamadı. MP4, MOV, M4V veya WebM kullan.',
      );
    }

    final thumbnail = preparedVideo.thumbnailBytes;

    if (!_isValidJpeg(thumbnail)) {
      throw const VideoUploadValidationException(
        'Video kapak görseli geçerli bir JPEG değil.',
      );
    }

    if (thumbnail.lengthInBytes > VideoUploadLimits.maxThumbnailSizeBytes) {
      throw const VideoUploadValidationException(
        'Video kapak görseli 8 MB sınırını aşıyor.',
      );
    }

    return ValidatedVideoUpload(
      preparedVideo: preparedVideo,
      format: format,
      fileSizeBytes: stat.size,
      thumbnailSizeBytes: thumbnail.lengthInBytes,
    );
  }

  void _validateDimensionsAndDuration(PreparedVideoUpload preparedVideo) {
    final minimumDurationMs = VideoUploadLimits.minDuration.inMilliseconds;
    final maximumDurationMs = VideoUploadLimits.maxDuration.inMilliseconds;

    if (preparedVideo.durationMs < minimumDurationMs ||
        preparedVideo.durationMs > maximumDurationMs) {
      throw const VideoUploadValidationException(
        'Video en az 1 saniye ve en fazla 3 dakika olmalı.',
      );
    }

    if (preparedVideo.width <= 0 ||
        preparedVideo.height <= 0 ||
        preparedVideo.width > VideoUploadLimits.maxDimension ||
        preparedVideo.height > VideoUploadLimits.maxDimension) {
      throw const VideoUploadValidationException(
        'Video çözünürlüğü okunamadı veya desteklenen aralığın dışında.',
      );
    }

    final calculatedRatio = preparedVideo.width / preparedVideo.height;
    final suppliedRatio = preparedVideo.aspectRatio;

    if (!calculatedRatio.isFinite ||
        calculatedRatio < VideoUploadLimits.minAspectRatio ||
        calculatedRatio > VideoUploadLimits.maxAspectRatio) {
      throw const VideoUploadValidationException(
        'Video en-boy oranı desteklenmiyor.',
      );
    }

    if (!suppliedRatio.isFinite ||
        suppliedRatio < VideoUploadLimits.minAspectRatio ||
        suppliedRatio > VideoUploadLimits.maxAspectRatio) {
      throw const VideoUploadValidationException(
        'Hazırlanan video oranı geçerli değil.',
      );
    }

    if ((calculatedRatio - suppliedRatio).abs() > 0.000001) {
      throw const VideoUploadValidationException(
        'Video boyutları ile en-boy oranı birbiriyle uyuşmuyor.',
      );
    }
  }

  Future<Uint8List> _readHeader(File file) async {
    final handle = await file.open();

    try {
      return await handle.read(64);
    } finally {
      await handle.close();
    }
  }

  VideoSourceFormat? _detectVideoFormat(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x1A &&
        bytes[1] == 0x45 &&
        bytes[2] == 0xDF &&
        bytes[3] == 0xA3) {
      return VideoSourceFormat.webm;
    }

    if (bytes.length < 12 ||
        bytes[4] != 0x66 ||
        bytes[5] != 0x74 ||
        bytes[6] != 0x79 ||
        bytes[7] != 0x70) {
      return null;
    }

    final majorBrand = String.fromCharCodes(bytes.sublist(8, 12));

    if (majorBrand == 'qt  ') {
      return VideoSourceFormat.mov;
    }

    if (majorBrand == 'M4V ' || majorBrand == 'M4VH' || majorBrand == 'M4VP') {
      return VideoSourceFormat.m4v;
    }

    return VideoSourceFormat.mp4;
  }

  bool _isValidJpeg(Uint8List bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[bytes.length - 2] == 0xFF &&
        bytes[bytes.length - 1] == 0xD9;
  }
}
