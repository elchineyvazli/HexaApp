import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'upload/video_compression_models.dart';
import 'upload/video_compression_service.dart';
import 'upload/video_metadata_reader.dart';
import 'upload/video_thumbnail_generator.dart';
import 'video_upload_limits.dart';

enum VideoPreparationStage {
  inspecting,
  readingMetadata,
  compressing,
  verifying,
  generatingThumbnail,
  finalizing,
  ready,
}

extension VideoPreparationStageLabel on VideoPreparationStage {
  String get label {
    switch (this) {
      case VideoPreparationStage.inspecting:
        return 'Video inceleniyor';

      case VideoPreparationStage.readingMetadata:
        return 'Video bilgileri okunuyor';

      case VideoPreparationStage.compressing:
        return 'Video hazırlanıyor';

      case VideoPreparationStage.verifying:
        return 'Video doğrulanıyor';

      case VideoPreparationStage.generatingThumbnail:
        return 'Kapak hazırlanıyor';

      case VideoPreparationStage.finalizing:
        return 'Son dokunuşlar';

      case VideoPreparationStage.ready:
        return 'Video hazır';
    }
  }
}

class VideoPreparationProgress {
  const VideoPreparationProgress({required this.stage, required this.value});

  final VideoPreparationStage stage;
  final double value;

  String get message => stage.label;
}

enum VideoPreparationFailureCode {
  invalidSource,
  sourceTooLarge,
  sourceChanged,
  metadata,
  unsupportedDuration,
  unsupportedDimensions,
  compression,
  cancelled,
  outputInvalid,
  thumbnail,
  fileSystem,
  timeout,
  unknown,
}

class PreparedVideoUpload {
  const PreparedVideoUpload({
    required this.originalVideoFile,
    required this.videoFile,
    required this.thumbnailBytes,
    required this.originalFileSizeBytes,
    required this.fileSizeBytes,
    required this.durationMs,
    required this.width,
    required this.height,
    required this.wasCompressed,
    required this.targetVideoBitrate,
    this.compressionAttemptCount = 0,
  });

  final File originalVideoFile;
  final File videoFile;
  final Uint8List thumbnailBytes;

  final int originalFileSizeBytes;
  final int fileSizeBytes;

  final int durationMs;
  final int width;
  final int height;

  final bool wasCompressed;
  final int targetVideoBitrate;
  final int compressionAttemptCount;

  double get aspectRatio {
    if (height <= 0) {
      return 0;
    }

    return width / height;
  }

  bool get ownsTemporaryVideo {
    return wasCompressed && originalVideoFile.path != videoFile.path;
  }

  int get savedBytes {
    final difference = originalFileSizeBytes - fileSizeBytes;

    return difference > 0 ? difference : 0;
  }

  double get savedFraction {
    if (originalFileSizeBytes <= 0) {
      return 0;
    }

    return (savedBytes / originalFileSizeBytes).clamp(0, 1).toDouble();
  }

  Future<void> deleteTemporaryFile() async {
    if (!ownsTemporaryVideo) {
      return;
    }

    try {
      if (await videoFile.exists()) {
        await videoFile.delete();
      }
    } on FileSystemException {
      // Geçici dosya temizliği kullanıcı akışını bozmaz.
    }
  }
}

class VideoPreparationException implements Exception {
  const VideoPreparationException(
    this.message, {
    required this.code,
    this.cause,
  });

  final String message;
  final VideoPreparationFailureCode code;
  final Object? cause;

  bool get isCancelled {
    return code == VideoPreparationFailureCode.cancelled;
  }

  @override
  String toString() => message;
}

class VideoUploadPreparer {
  const VideoUploadPreparer({
    this.metadataReader = const VideoMetadataReader(),
    this.thumbnailGenerator = const VideoThumbnailGenerator(),
    this.compressionService = const VideoCompressionService(),
  });

  final VideoMetadataReader metadataReader;
  final VideoThumbnailGenerator thumbnailGenerator;
  final VideoCompressionService compressionService;

  Future<PreparedVideoUpload> prepare(
    File sourceFile, {
    void Function(VideoPreparationProgress progress)? onProgress,
  }) async {
    final progress = _PreparationProgressEmitter(onProgress);

    VideoCompressionResult? compression;

    try {
      progress.emit(VideoPreparationStage.inspecting, 0.02);

      final initialStat = await _validateSourceFile(sourceFile);

      progress.emit(VideoPreparationStage.readingMetadata, 0.06);

      final sourceMetadata = await metadataReader.read(sourceFile);

      _validateMetadata(
        durationMs: sourceMetadata.durationMs,
        width: sourceMetadata.width,
        height: sourceMetadata.height,
      );

      progress.emit(VideoPreparationStage.compressing, 0.12);

      compression = await compressionService.compressIfNeeded(
        sourceFile: sourceFile,
        durationMs: sourceMetadata.durationMs,
        width: sourceMetadata.width,
        height: sourceMetadata.height,
        onProgress: (value) {
          progress.emit(VideoPreparationStage.compressing, 0.12 + value * 0.68);
        },
      );

      await _ensureSourceUnchanged(
        sourceFile: sourceFile,
        initialStat: initialStat,
      );

      progress.emit(VideoPreparationStage.verifying, 0.84);

      final preparedFile = compression.outputFile;

      final preparedMetadata = compression.wasCompressed
          ? await metadataReader.read(preparedFile)
          : sourceMetadata;

      _validatePreparedVideo(
        sourceDurationMs: sourceMetadata.durationMs,
        outputDurationMs: preparedMetadata.durationMs,
        outputWidth: preparedMetadata.width,
        outputHeight: preparedMetadata.height,
        expectedWidth: compression.outputWidth,
        expectedHeight: compression.outputHeight,
      );

      final outputStat = await _validateOutputFile(preparedFile);

      progress.emit(VideoPreparationStage.generatingThumbnail, 0.9);

      final thumbnailBytes = await thumbnailGenerator.generate(
        videoFile: preparedFile,
        durationMs: preparedMetadata.durationMs,
      );

      if (thumbnailBytes.isEmpty) {
        throw const VideoPreparationException(
          'Video kapak görseli oluşturulamadı.',
          code: VideoPreparationFailureCode.thumbnail,
        );
      }

      await _ensureSourceUnchanged(
        sourceFile: sourceFile,
        initialStat: initialStat,
      );

      final finalOutputStat = await _validateOutputFile(preparedFile);

      if (finalOutputStat.size != outputStat.size ||
          finalOutputStat.modified != outputStat.modified) {
        throw const VideoPreparationException(
          'Hazırlanan video dosyası işlem sırasında değişti.',
          code: VideoPreparationFailureCode.outputInvalid,
        );
      }

      progress.emit(VideoPreparationStage.finalizing, 0.98);

      final result = PreparedVideoUpload(
        originalVideoFile: sourceFile,
        videoFile: preparedFile,
        thumbnailBytes: thumbnailBytes,
        originalFileSizeBytes: initialStat.size,
        fileSizeBytes: finalOutputStat.size,
        durationMs: preparedMetadata.durationMs,
        width: preparedMetadata.width,
        height: preparedMetadata.height,
        wasCompressed: compression.wasCompressed,
        targetVideoBitrate: compression.targetVideoBitrate,
        compressionAttemptCount: compression.attemptCount,
      );

      progress.emit(VideoPreparationStage.ready, 1);

      return result;
    } catch (error, stackTrace) {
      await compression?.deleteTemporaryOutput();

      Error.throwWithStackTrace(_mapPreparationError(error), stackTrace);
    }
  }

  Future<void> cancelCompression() {
    return compressionService.cancel();
  }

  Future<FileStat> _validateSourceFile(File sourceFile) async {
    if (sourceFile.path.trim().isEmpty) {
      throw const VideoPreparationException(
        'Geçerli bir video dosyası seçilmedi.',
        code: VideoPreparationFailureCode.invalidSource,
      );
    }

    late final FileStat stat;

    try {
      stat = await sourceFile.stat().timeout(
        VideoUploadLimits.sourceInspectionTimeout,
      );
    } on TimeoutException catch (error) {
      throw VideoPreparationException(
        'Video dosyasının okunması zaman aşımına uğradı.',
        code: VideoPreparationFailureCode.timeout,
        cause: error,
      );
    } on FileSystemException catch (error) {
      throw VideoPreparationException(
        'Seçilen video dosyasına erişilemedi.',
        code: VideoPreparationFailureCode.fileSystem,
        cause: error,
      );
    }

    if (stat.type != FileSystemEntityType.file || stat.size <= 0) {
      throw const VideoPreparationException(
        'Seçilen video dosyası bulunamadı veya boş.',
        code: VideoPreparationFailureCode.invalidSource,
      );
    }

    if (stat.size > VideoUploadLimits.maxSourceFileSizeBytes) {
      throw const VideoPreparationException(
        'Kaynak video en fazla 1 GB olabilir.',
        code: VideoPreparationFailureCode.sourceTooLarge,
      );
    }

    return stat;
  }

  Future<FileStat> _validateOutputFile(File outputFile) async {
    final stat = await outputFile.stat().timeout(
      VideoUploadLimits.sourceInspectionTimeout,
    );

    if (stat.type != FileSystemEntityType.file || stat.size <= 0) {
      throw const VideoPreparationException(
        'Hazırlanan video dosyası oluşturulamadı.',
        code: VideoPreparationFailureCode.outputInvalid,
      );
    }

    if (stat.size > VideoUploadLimits.maxUploadFileSizeBytes) {
      throw const VideoPreparationException(
        'Hazırlanan video 40 MB sınırını aşıyor.',
        code: VideoPreparationFailureCode.outputInvalid,
      );
    }

    return stat;
  }

  Future<void> _ensureSourceUnchanged({
    required File sourceFile,
    required FileStat initialStat,
  }) async {
    final currentStat = await sourceFile.stat().timeout(
      VideoUploadLimits.sourceInspectionTimeout,
    );

    if (currentStat.type != FileSystemEntityType.file ||
        currentStat.size != initialStat.size ||
        currentStat.modified != initialStat.modified) {
      throw const VideoPreparationException(
        'Video hazırlanırken kaynak dosya değişti. '
        'Videoyu yeniden seçmelisin.',
        code: VideoPreparationFailureCode.sourceChanged,
      );
    }
  }

  void _validateMetadata({
    required int durationMs,
    required int width,
    required int height,
  }) {
    if (!VideoUploadLimits.isSupportedDuration(durationMs)) {
      throw const VideoPreparationException(
        'Video en az 1 saniye ve en fazla '
        '3 dakika olmalı.',
        code: VideoPreparationFailureCode.unsupportedDuration,
      );
    }

    if (!VideoUploadLimits.isSupportedDimension(width: width, height: height)) {
      throw const VideoPreparationException(
        'Video çözünürlüğü okunamadı veya desteklenmiyor.',
        code: VideoPreparationFailureCode.unsupportedDimensions,
      );
    }

    final ratio = width / height;

    if (!VideoUploadLimits.isSupportedAspectRatio(ratio)) {
      throw const VideoPreparationException(
        'Video en-boy oranı desteklenmiyor.',
        code: VideoPreparationFailureCode.unsupportedDimensions,
      );
    }
  }

  void _validatePreparedVideo({
    required int sourceDurationMs,
    required int outputDurationMs,
    required int outputWidth,
    required int outputHeight,
    required int expectedWidth,
    required int expectedHeight,
  }) {
    _validateMetadata(
      durationMs: outputDurationMs,
      width: outputWidth,
      height: outputHeight,
    );

    final widthDifference = (expectedWidth - outputWidth).abs();

    final heightDifference = (expectedHeight - outputHeight).abs();

    if (widthDifference > VideoUploadLimits.outputDimensionTolerancePixels ||
        heightDifference > VideoUploadLimits.outputDimensionTolerancePixels) {
      throw const VideoPreparationException(
        'Cihaz video çözünürlüğünü koruyamadı.',
        code: VideoPreparationFailureCode.unsupportedDimensions,
      );
    }

    final durationDifference = (sourceDurationMs - outputDurationMs).abs();

    final allowedDifference = VideoUploadLimits.allowedDurationDriftMs(
      sourceDurationMs,
    );

    if (durationDifference > allowedDifference) {
      throw const VideoPreparationException(
        'Hazırlanan videonun süresi kaynak videoyla '
        'uyuşmuyor.',
        code: VideoPreparationFailureCode.outputInvalid,
      );
    }
  }

  VideoPreparationException _mapPreparationError(Object error) {
    if (error is VideoPreparationException) {
      return error;
    }

    if (error is VideoMetadataReadException) {
      return VideoPreparationException(
        error.message,
        code: VideoPreparationFailureCode.metadata,
        cause: error,
      );
    }

    if (error is VideoThumbnailGenerationException) {
      return VideoPreparationException(
        error.message,
        code: VideoPreparationFailureCode.thumbnail,
        cause: error,
      );
    }

    if (error is VideoCompressionException) {
      return VideoPreparationException(
        error.message,
        code: error.isCancelled
            ? VideoPreparationFailureCode.cancelled
            : VideoPreparationFailureCode.compression,
        cause: error,
      );
    }

    if (error is TimeoutException) {
      return VideoPreparationException(
        'Video hazırlama işlemi zaman aşımına uğradı.',
        code: VideoPreparationFailureCode.timeout,
        cause: error,
      );
    }

    if (error is FileSystemException) {
      return VideoPreparationException(
        'Video dosyasına erişilemedi.',
        code: VideoPreparationFailureCode.fileSystem,
        cause: error,
      );
    }

    return VideoPreparationException(
      'Video hazırlanamadı: ${_shortError(error)}',
      code: VideoPreparationFailureCode.unknown,
      cause: error,
    );
  }

  String _shortError(Object error) {
    final text = error.toString().trim();

    if (text.length <= 120) {
      return text;
    }

    return '${text.substring(0, 120)}…';
  }
}

class _PreparationProgressEmitter {
  _PreparationProgressEmitter(this.callback);

  final void Function(VideoPreparationProgress progress)? callback;

  double _lastValue = -1;

  void emit(VideoPreparationStage stage, double value) {
    final safeValue = value.clamp(0, 1).toDouble();

    if (safeValue < _lastValue) {
      return;
    }

    _lastValue = safeValue;

    try {
      callback?.call(VideoPreparationProgress(stage: stage, value: safeValue));
    } catch (_) {
      // UI progress callback'i hazırlama işlemini bozmamalıdır.
    }
  }
}
