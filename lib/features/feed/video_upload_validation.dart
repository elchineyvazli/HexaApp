import 'dart:async';
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

enum VideoUploadValidationFailureCode {
  videoMissing,
  videoChanged,
  videoTooLarge,
  unsupportedDuration,
  unsupportedDimensions,
  unsupportedAspectRatio,
  unsupportedFormat,
  invalidThumbnail,
  thumbnailTooLarge,
  fileSystem,
  timeout,
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

  String get fileExtension => format.extension;

  String get contentType => format.contentType;

  String get thumbnailContentType => 'image/jpeg';
}

class VideoUploadValidationException implements Exception {
  const VideoUploadValidationException(
    this.message, {
    required this.code,
    this.cause,
  });

  final String message;
  final VideoUploadValidationFailureCode code;
  final Object? cause;

  @override
  String toString() => message;
}

class VideoUploadValidator {
  const VideoUploadValidator();

  Future<ValidatedVideoUpload> validate(
    PreparedVideoUpload preparedVideo,
  ) async {
    try {
      final file = preparedVideo.videoFile;

      if (file.path.trim().isEmpty) {
        throw const VideoUploadValidationException(
          'Hazırlanan video dosyası bulunamadı.',
          code: VideoUploadValidationFailureCode.videoMissing,
        );
      }

      final stat = await file.stat().timeout(
        VideoUploadLimits.sourceInspectionTimeout,
      );

      if (stat.type != FileSystemEntityType.file || stat.size <= 0) {
        throw const VideoUploadValidationException(
          'Hazırlanan video dosyası artık mevcut değil.',
          code: VideoUploadValidationFailureCode.videoMissing,
        );
      }

      if (stat.size > VideoUploadLimits.maxUploadFileSizeBytes) {
        throw const VideoUploadValidationException(
          'Yüklenecek video en fazla 40 MB olabilir.',
          code: VideoUploadValidationFailureCode.videoTooLarge,
        );
      }

      if (preparedVideo.fileSizeBytes != stat.size) {
        throw const VideoUploadValidationException(
          'Video hazırlandıktan sonra değişmiş. '
          'Videoyu yeniden seçmelisin.',
          code: VideoUploadValidationFailureCode.videoChanged,
        );
      }

      _validateMediaProperties(preparedVideo);

      final header = await _readHeader(file);
      final format = _detectVideoFormat(header);

      if (format == null) {
        throw const VideoUploadValidationException(
          'Video biçimi doğrulanamadı. '
          'MP4, MOV, M4V veya WebM kullan.',
          code: VideoUploadValidationFailureCode.unsupportedFormat,
        );
      }

      final thumbnail = preparedVideo.thumbnailBytes;

      if (!_isValidJpeg(thumbnail)) {
        throw const VideoUploadValidationException(
          'Video kapak görseli geçerli bir JPEG değil.',
          code: VideoUploadValidationFailureCode.invalidThumbnail,
        );
      }

      if (thumbnail.lengthInBytes > VideoUploadLimits.maxThumbnailSizeBytes) {
        throw const VideoUploadValidationException(
          'Video kapak görseli 8 MB sınırını aşıyor.',
          code: VideoUploadValidationFailureCode.thumbnailTooLarge,
        );
      }

      return ValidatedVideoUpload(
        preparedVideo: preparedVideo,
        format: format,
        fileSizeBytes: stat.size,
        thumbnailSizeBytes: thumbnail.lengthInBytes,
      );
    } on VideoUploadValidationException {
      rethrow;
    } on TimeoutException catch (error) {
      throw VideoUploadValidationException(
        'Video dosyasının okunması zaman aşımına uğradı.',
        code: VideoUploadValidationFailureCode.timeout,
        cause: error,
      );
    } on FileSystemException catch (error) {
      throw VideoUploadValidationException(
        'Video dosyasına erişilemedi.',
        code: VideoUploadValidationFailureCode.fileSystem,
        cause: error,
      );
    }
  }

  void _validateMediaProperties(PreparedVideoUpload preparedVideo) {
    if (!VideoUploadLimits.isSupportedDuration(preparedVideo.durationMs)) {
      throw const VideoUploadValidationException(
        'Video en az 1 saniye ve en fazla '
        '3 dakika olmalı.',
        code: VideoUploadValidationFailureCode.unsupportedDuration,
      );
    }

    if (!VideoUploadLimits.isSupportedDimension(
      width: preparedVideo.width,
      height: preparedVideo.height,
    )) {
      throw const VideoUploadValidationException(
        'Video çözünürlüğü okunamadı veya '
        'desteklenen aralığın dışında.',
        code: VideoUploadValidationFailureCode.unsupportedDimensions,
      );
    }

    if (!VideoUploadLimits.isSupportedAspectRatio(preparedVideo.aspectRatio)) {
      throw const VideoUploadValidationException(
        'Video en-boy oranı desteklenmiyor.',
        code: VideoUploadValidationFailureCode.unsupportedAspectRatio,
      );
    }
  }

  Future<Uint8List> _readHeader(File file) async {
    final handle = await file.open();

    try {
      return await handle
          .read(VideoUploadLimits.fileHeaderProbeBytes)
          .timeout(VideoUploadLimits.fileHeaderReadTimeout);
    } finally {
      await handle.close();
    }
  }

  VideoSourceFormat? _detectVideoFormat(Uint8List bytes) {
    if (_hasEbmlHeader(bytes)) {
      return _containsAscii(bytes, 'webm') ? VideoSourceFormat.webm : null;
    }

    final ftypOffset = _findAscii(bytes, 'ftyp');

    if (ftypOffset < 4 || ftypOffset + 8 > bytes.length) {
      return null;
    }

    final boxStart = ftypOffset - 4;
    final boxSize = _readUint32(bytes, boxStart);

    final availableBoxEnd = boxSize >= 16
        ? (boxStart + boxSize).clamp(ftypOffset + 8, bytes.length)
        : bytes.length;

    final majorBrand = String.fromCharCodes(
      bytes.sublist(ftypOffset + 4, ftypOffset + 8),
    );

    if (majorBrand == 'qt  ') {
      return VideoSourceFormat.mov;
    }

    final brands = <String>[majorBrand];

    for (
      var offset = ftypOffset + 12;
      offset + 4 <= availableBoxEnd;
      offset += 4
    ) {
      brands.add(String.fromCharCodes(bytes.sublist(offset, offset + 4)));
    }

    if (brands.any((brand) => brand.startsWith('M4V'))) {
      return VideoSourceFormat.m4v;
    }

    return VideoSourceFormat.mp4;
  }

  bool _hasEbmlHeader(Uint8List bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x1A &&
        bytes[1] == 0x45 &&
        bytes[2] == 0xDF &&
        bytes[3] == 0xA3;
  }

  int _findAscii(Uint8List bytes, String value) {
    final pattern = value.codeUnits;

    for (var index = 0; index <= bytes.length - pattern.length; index++) {
      var matches = true;

      for (
        var patternIndex = 0;
        patternIndex < pattern.length;
        patternIndex++
      ) {
        if (bytes[index + patternIndex] != pattern[patternIndex]) {
          matches = false;
          break;
        }
      }

      if (matches) {
        return index;
      }
    }

    return -1;
  }

  bool _containsAscii(Uint8List bytes, String value) {
    return _findAscii(bytes, value) >= 0;
  }

  int _readUint32(Uint8List bytes, int offset) {
    if (offset < 0 || offset + 4 > bytes.length) {
      return 0;
    }

    return ByteData.sublistView(bytes, offset, offset + 4).getUint32(0);
  }

  bool _isValidJpeg(Uint8List bytes) {
    if (bytes.length < 16 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
      return false;
    }

    final searchStart = (bytes.length - 32).clamp(2, bytes.length - 2);

    for (var index = bytes.length - 2; index >= searchStart; index--) {
      if (bytes[index] == 0xFF && bytes[index + 1] == 0xD9) {
        return true;
      }
    }

    return false;
  }
}
