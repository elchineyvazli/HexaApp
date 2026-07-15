import 'dart:io';
import 'dart:typed_data';

import 'upload/video_compression_models.dart';
import 'upload/video_compression_service.dart';
import 'upload/video_metadata_reader.dart';
import 'upload/video_thumbnail_generator.dart';
import 'video_upload_limits.dart';

class VideoPreparationProgress {
  const VideoPreparationProgress({
    required this.value,
    required this.message,
  });

  final double value;
  final String message;
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

  double get aspectRatio => width / height;

  Future<void> deleteTemporaryFile() async {
    if (!wasCompressed || originalVideoFile.path == videoFile.path) {
      return;
    }

    try {
      if (await videoFile.exists()) {
        await videoFile.delete();
      }
    } catch (_) {
      // Geçici dosya temizleme hatası kullanıcı akışını bozmamalı.
    }
  }
}

class VideoPreparationException implements Exception {
  const VideoPreparationException(this.message);

  final String message;

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
    final initialStat = await _validateSourceFile(sourceFile);
    VideoCompressionResult? compression;

    try {
      onProgress?.call(
        const VideoPreparationProgress(
          value: 0.02,
          message: 'Video bilgileri okunuyor',
        ),
      );

      final sourceMetadata = await metadataReader.read(sourceFile);

      onProgress?.call(
        const VideoPreparationProgress(
          value: 0.08,
          message: 'Video hazırlanıyor',
        ),
      );

      compression = await compressionService.compressIfNeeded(
        sourceFile: sourceFile,
        durationMs: sourceMetadata.durationMs,
        width: sourceMetadata.width,
        height: sourceMetadata.height,
        onProgress: (progress) {
          onProgress?.call(
            VideoPreparationProgress(
              value: 0.08 + (progress * 0.78),
              message: 'Video sıkıştırılıyor',
            ),
          );
        },
      );

      final preparedFile = compression.outputFile;
      final preparedMetadata = await metadataReader.read(preparedFile);

      _validatePreservedVideo(
        sourceDurationMs: sourceMetadata.durationMs,
        sourceWidth: sourceMetadata.width,
        sourceHeight: sourceMetadata.height,
        outputDurationMs: preparedMetadata.durationMs,
        outputWidth: preparedMetadata.width,
        outputHeight: preparedMetadata.height,
      );

      onProgress?.call(
        const VideoPreparationProgress(
          value: 0.90,
          message: 'Kapak görseli hazırlanıyor',
        ),
      );

      final thumbnailBytes = await thumbnailGenerator.generate(
        videoFile: preparedFile,
        durationMs: preparedMetadata.durationMs,
      );

      final finalSourceStat = await sourceFile.stat();

      if (finalSourceStat.type != FileSystemEntityType.file ||
          finalSourceStat.size != initialStat.size ||
          finalSourceStat.modified != initialStat.modified) {
        throw const VideoPreparationException(
          'Video hazırlanırken kaynak dosya değişti. Videoyu yeniden seçmelisin.',
        );
      }

      final finalOutputStat = await preparedFile.stat();

      if (finalOutputStat.type != FileSystemEntityType.file ||
          finalOutputStat.size <= 0 ||
          finalOutputStat.size > VideoUploadLimits.maxUploadFileSizeBytes) {
        throw const VideoPreparationException(
          'Hazırlanan video 40 MB upload sınırına uymuyor.',
        );
      }

      onProgress?.call(
        const VideoPreparationProgress(
          value: 1,
          message: 'Video hazır',
        ),
      );

      return PreparedVideoUpload(
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
      );
    } on VideoPreparationException {
      await compression?.deleteTemporaryOutput();
      rethrow;
    } on VideoMetadataReadException catch (error) {
      await compression?.deleteTemporaryOutput();
      throw VideoPreparationException(error.message);
    } on VideoThumbnailGenerationException catch (error) {
      await compression?.deleteTemporaryOutput();
      throw VideoPreparationException(error.message);
    } on VideoCompressionException catch (error) {
      await compression?.deleteTemporaryOutput();
      throw VideoPreparationException(error.message);
    } catch (error) {
      await compression?.deleteTemporaryOutput();

      throw VideoPreparationException(
        'Video hazırlanamadı: ${_shortError(error)}',
      );
    }
  }

  Future<void> cancelCompression() => compressionService.cancel();

  Future<FileStat> _validateSourceFile(File videoFile) async {
    final path = videoFile.path.trim();

    if (path.isEmpty) {
      throw const VideoPreparationException(
        'Geçerli bir video dosyası seçilmedi.',
      );
    }

    final stat = await videoFile.stat();

    if (stat.type != FileSystemEntityType.file) {
      throw const VideoPreparationException(
        'Seçilen video dosyası bulunamadı.',
      );
    }

    if (stat.size <= 0) {
      throw const VideoPreparationException('Seçilen video dosyası boş.');
    }

    if (stat.size > VideoUploadLimits.maxSourceFileSizeBytes) {
      throw const VideoPreparationException(
        'Kaynak video en fazla 1 GB olabilir.',
      );
    }

    return stat;
  }

  void _validatePreservedVideo({
    required int sourceDurationMs,
    required int sourceWidth,
    required int sourceHeight,
    required int outputDurationMs,
    required int outputWidth,
    required int outputHeight,
  }) {
    if (sourceWidth != outputWidth || sourceHeight != outputHeight) {
      throw const VideoPreparationException(
        'Cihaz video çözünürlüğünü koruyamadı. Video yüklenmedi.',
      );
    }

    final durationDifference = (sourceDurationMs - outputDurationMs).abs();

    if (durationDifference > 1500) {
      throw const VideoPreparationException(
        'Sıkıştırılan videonun süresi kaynak videoyla uyuşmuyor.',
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
