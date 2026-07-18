import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../video_upload_limits.dart';
import 'video_compression_models.dart';

class VideoCompressionService {
  const VideoCompressionService();

  static const MethodChannel _methodChannel = MethodChannel(
    'hexa/video_compression',
  );

  static const EventChannel _progressChannel = EventChannel(
    'hexa/video_compression_progress',
  );

  static final Stream<dynamic> _progressEvents = _progressChannel
      .receiveBroadcastStream();

  Future<VideoCompressionResult> compressIfNeeded({
    required File sourceFile,
    required int durationMs,
    required int width,
    required int height,
    void Function(double progress)? onProgress,
  }) async {
    _validateMetadata(durationMs: durationMs, width: width, height: height);

    late final FileStat sourceStat;

    try {
      sourceStat = await sourceFile.stat();
    } on FileSystemException catch (error) {
      throw VideoCompressionException(
        'Video dosyasına erişilemedi.',
        code: VideoCompressionFailureCode.fileSystem,
        cause: error,
      );
    }

    if (sourceStat.type != FileSystemEntityType.file || sourceStat.size <= 0) {
      throw const VideoCompressionException(
        'Sıkıştırılacak video dosyası bulunamadı.',
        code: VideoCompressionFailureCode.invalidInput,
      );
    }

    void reportProgress(double value) {
      final safeValue = value.clamp(0, 1).toDouble();

      try {
        onProgress?.call(safeValue);
      } catch (_) {
        // UI callback hatası sıkıştırma işlemini bozmamalıdır.
      }
    }

    if (sourceStat.size <= VideoUploadLimits.maxUploadFileSizeBytes) {
      reportProgress(1);

      return VideoCompressionResult.passthrough(
        sourceFile: sourceFile,
        sizeBytes: sourceStat.size,
        width: width,
        height: height,
      );
    }

    if (!Platform.isAndroid) {
      throw const VideoCompressionException(
        'Yükleme sınırını aşan videoların sıkıştırılması '
        'şu anda yalnızca Android cihazlarda destekleniyor.',
        code: VideoCompressionFailureCode.unsupportedPlatform,
      );
    }

    StreamSubscription<dynamic>? progressSubscription;
    var lastProgress = -1.0;

    try {
      reportProgress(0);

      progressSubscription = _progressEvents.listen(
        (event) {
          if (event is! Map) {
            return;
          }

          final rawProgress = event['progress'];

          if (rawProgress is! num) {
            return;
          }

          final progress = (rawProgress.toDouble() / 100)
              .clamp(0, 1)
              .toDouble();

          if (progress <= lastProgress) {
            return;
          }

          lastProgress = progress;
          reportProgress(progress);
        },
        onError: (Object error, StackTrace stackTrace) {
          // EventChannel hatası ana MethodChannel sonucunu bozmaz.
          // Nihai başarı veya hata compressVideo çağrısından alınır.
        },
        cancelOnError: false,
      );

      final response = await _methodChannel
          .invokeMapMethod<String, dynamic>('compressVideo', <String, dynamic>{
            'inputPath': sourceFile.path,
            'durationMs': durationMs,
            'width': width,
            'height': height,
            'targetBytes': VideoUploadLimits.compressionTargetBytes,
            'maxBytes': VideoUploadLimits.maxUploadFileSizeBytes,
          });

      if (response == null) {
        throw const VideoCompressionException(
          'Video sıkıştırma sonucu alınamadı.',
          code: VideoCompressionFailureCode.outputUnavailable,
        );
      }

      final outputPath = response['outputPath']?.toString().trim() ?? '';

      if (outputPath.isEmpty) {
        throw const VideoCompressionException(
          'Sıkıştırılmış video yolu alınamadı.',
          code: VideoCompressionFailureCode.outputUnavailable,
        );
      }

      final outputFile = File(outputPath);

      if (!await outputFile.exists()) {
        throw const VideoCompressionException(
          'Sıkıştırılmış video dosyası oluşturulamadı.',
          code: VideoCompressionFailureCode.outputUnavailable,
        );
      }

      final actualOutputSize = await outputFile.length();

      if (actualOutputSize <= 0) {
        await _safeDelete(outputFile);

        throw const VideoCompressionException(
          'Sıkıştırılmış video dosyası boş.',
          code: VideoCompressionFailureCode.outputUnavailable,
        );
      }

      if (actualOutputSize > VideoUploadLimits.maxUploadFileSizeBytes) {
        await _safeDelete(outputFile);

        throw const VideoCompressionException(
          'Video çözünürlüğü korunarak yükleme '
          'sınırına indirilemedi.',
          code: VideoCompressionFailureCode.outputTooLarge,
        );
      }

      final wasCompressed = response['wasCompressed'] != false;

      if (wasCompressed && outputFile.path == sourceFile.path) {
        throw const VideoCompressionException(
          'Sıkıştırma çıktısı kaynak videonun üzerine yazıldı.',
          code: VideoCompressionFailureCode.outputUnavailable,
        );
      }

      reportProgress(1);

      return VideoCompressionResult(
        originalFile: sourceFile,
        outputFile: outputFile,
        originalSizeBytes: sourceStat.size,

        // Platform yanıtından ziyade gerçek dosya boyutu esas alınır.
        outputSizeBytes: actualOutputSize,

        wasCompressed: wasCompressed,
        targetVideoBitrate: _readInt(response['targetVideoBitrate']),
        outputWidth: _readInt(
          response['outputWidth'],
          fallback: _encoderSafeDimension(width),
        ),
        outputHeight: _readInt(
          response['outputHeight'],
          fallback: _encoderSafeDimension(height),
        ),
        attemptCount: _readInt(
          response['attemptCount'],
          fallback: wasCompressed ? 1 : 0,
        ),
      );
    } on PlatformException catch (error) {
      throw _mapPlatformException(error);
    } on MissingPluginException catch (error) {
      throw VideoCompressionException(
        'Android video sıkıştırma modülü yüklenemedi. '
        'Uygulamayı tamamen kapatıp yeniden derle.',
        code: VideoCompressionFailureCode.pluginUnavailable,
        cause: error,
      );
    } on FileSystemException catch (error) {
      throw VideoCompressionException(
        'Sıkıştırılmış video dosyasına erişilemedi.',
        code: VideoCompressionFailureCode.fileSystem,
        cause: error,
      );
    } on VideoCompressionException {
      rethrow;
    } catch (error) {
      throw VideoCompressionException(
        'Video sıkıştırılamadı: ${_shortError(error)}',
        code: VideoCompressionFailureCode.unknown,
        cause: error,
      );
    } finally {
      await progressSubscription?.cancel();
    }
  }

  Future<void> cancel() async {
    try {
      await _methodChannel.invokeMethod<void>('cancelCompression');
    } on MissingPluginException {
      // Uygulama kapanırken native kanal bulunmayabilir.
    } on PlatformException {
      // Aktif işlem yoksa veya plugin kapanıyorsa kullanıcıya hata gösterilmez.
    }
  }

  void _validateMetadata({
    required int durationMs,
    required int width,
    required int height,
  }) {
    if (durationMs <= 0 || width <= 1 || height <= 1) {
      throw const VideoCompressionException(
        'Video süresi veya çözünürlük bilgisi geçersiz.',
        code: VideoCompressionFailureCode.invalidArguments,
      );
    }
  }

  VideoCompressionException _mapPlatformException(PlatformException error) {
    final platformMessage = error.message?.trim() ?? '';

    switch (error.code) {
      case 'unsupported_android':
        return VideoCompressionException(
          'Video sıkıştırma bu Android sürümünde '
          'desteklenmiyor.',
          code: VideoCompressionFailureCode.unsupportedPlatform,
          cause: error,
        );

      case 'invalid_input':
      case 'input_not_found':
        return VideoCompressionException(
          'Sıkıştırılacak video dosyası bulunamadı.',
          code: VideoCompressionFailureCode.invalidInput,
          cause: error,
        );

      case 'invalid_arguments':
        return VideoCompressionException(
          'Video sıkıştırma bilgileri geçersiz.',
          code: VideoCompressionFailureCode.invalidArguments,
          cause: error,
        );

      case 'unsupported_resolution':
        return VideoCompressionException(
          'Bu cihaz videonun mevcut çözünürlüğünü '
          'koruyarak sıkıştıramıyor.',
          code: VideoCompressionFailureCode.unsupportedResolution,
          cause: error,
        );

      case 'video_too_long':
        return VideoCompressionException(
          'Bu video, çözünürlüğü korunarak yükleme '
          'sınırına indirilemeyecek kadar uzun.',
          code: VideoCompressionFailureCode.videoTooLong,
          cause: error,
        );

      case 'compression_cancelled':
        return VideoCompressionException(
          'Video sıkıştırma iptal edildi.',
          code: VideoCompressionFailureCode.cancelled,
          cause: error,
        );

      case 'output_too_large':
        return VideoCompressionException(
          'Video çözünürlüğü korunarak yükleme '
          'sınırına indirilemedi.',
          code: VideoCompressionFailureCode.outputTooLarge,
          cause: error,
        );

      case 'compression_busy':
        return VideoCompressionException(
          'Başka bir video hâlâ hazırlanıyor.',
          code: VideoCompressionFailureCode.busy,
          cause: error,
        );

      case 'output_directory_failed':
        return VideoCompressionException(
          'Geçici video klasörü oluşturulamadı.',
          code: VideoCompressionFailureCode.outputUnavailable,
          cause: error,
        );

      case 'plugin_disposed':
        return VideoCompressionException(
          'Video sıkıştırma servisi kapatıldı.',
          code: VideoCompressionFailureCode.pluginDisposed,
          cause: error,
        );

      case 'compression_start_failed':
        return VideoCompressionException(
          'Video sıkıştırma işlemi başlatılamadı.',
          code: VideoCompressionFailureCode.startFailed,
          cause: error,
        );

      default:
        return VideoCompressionException(
          platformMessage.isEmpty ? 'Video sıkıştırılamadı.' : platformMessage,
          code: VideoCompressionFailureCode.unknown,
          cause: error,
        );
    }
  }

  Future<void> _safeDelete(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      // Temizleme hatası asıl sıkıştırma hatasını gizlemez.
    }
  }

  int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  int _encoderSafeDimension(int value) {
    if (value <= 0) {
      return 0;
    }

    return value.isEven ? value : value - 1;
  }

  String _shortError(Object error) {
    final text = error.toString().trim();

    if (text.length <= 140) {
      return text;
    }

    return '${text.substring(0, 140)}…';
  }
}
