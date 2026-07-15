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

  Future<VideoCompressionResult> compressIfNeeded({
    required File sourceFile,
    required int durationMs,
    required int width,
    required int height,
    void Function(double progress)? onProgress,
  }) async {
    final sourceStat = await sourceFile.stat();

    if (sourceStat.type != FileSystemEntityType.file || sourceStat.size <= 0) {
      throw const VideoCompressionException(
        'Sıkıştırılacak video dosyası bulunamadı.',
      );
    }

    if (sourceStat.size <= VideoUploadLimits.maxUploadFileSizeBytes) {
      onProgress?.call(1);

      return VideoCompressionResult(
        originalFile: sourceFile,
        outputFile: sourceFile,
        originalSizeBytes: sourceStat.size,
        outputSizeBytes: sourceStat.size,
        wasCompressed: false,
        targetVideoBitrate: 0,
      );
    }

    if (!Platform.isAndroid) {
      throw const VideoCompressionException(
        '40 MB üzerindeki videoların sıkıştırılması şu anda yalnızca Android cihazlarda destekleniyor.',
      );
    }

    StreamSubscription<dynamic>? progressSubscription;

    try {
      progressSubscription = _progressChannel.receiveBroadcastStream().listen(
        (event) {
          if (event is! Map) {
            return;
          }

          final rawProgress = event['progress'];

          if (rawProgress is num) {
            onProgress?.call((rawProgress / 100).clamp(0, 1).toDouble());
          }
        },
      );

      final response = await _methodChannel.invokeMapMethod<String, dynamic>(
        'compressVideo',
        <String, dynamic>{
          'inputPath': sourceFile.path,
          'durationMs': durationMs,
          'width': width,
          'height': height,
          'targetBytes': VideoUploadLimits.compressionTargetBytes,
          'maxBytes': VideoUploadLimits.maxUploadFileSizeBytes,
        },
      );

      if (response == null) {
        throw const VideoCompressionException(
          'Video sıkıştırma sonucu alınamadı.',
        );
      }

      final outputPath = response['outputPath']?.toString().trim() ?? '';
      final outputFile = File(outputPath);
      final outputSizeBytes = _readInt(response['outputSizeBytes']);
      final targetVideoBitrate = _readInt(response['targetVideoBitrate']);

      if (outputPath.isEmpty || !await outputFile.exists()) {
        throw const VideoCompressionException(
          'Sıkıştırılmış video dosyası oluşturulamadı.',
        );
      }

      final actualOutputSize = await outputFile.length();

      if (actualOutputSize <= 0 ||
          actualOutputSize > VideoUploadLimits.maxUploadFileSizeBytes) {
        await _safeDelete(outputFile);

        throw const VideoCompressionException(
          'Video çözünürlüğü korunarak 40 MB sınırına indirilemedi. Daha kısa veya daha düşük bitrateli bir video seç.',
        );
      }

      onProgress?.call(1);

      return VideoCompressionResult(
        originalFile: sourceFile,
        outputFile: outputFile,
        originalSizeBytes: sourceStat.size,
        outputSizeBytes: outputSizeBytes > 0
            ? outputSizeBytes
            : actualOutputSize,
        wasCompressed: true,
        targetVideoBitrate: targetVideoBitrate,
      );
    } on PlatformException catch (error) {
      throw VideoCompressionException(_platformErrorMessage(error));
    } on MissingPluginException {
      throw const VideoCompressionException(
        'Android video sıkıştırma modülü yüklenemedi. Uygulamayı tamamen kapatıp yeniden derle.',
      );
    } on VideoCompressionException {
      rethrow;
    } catch (error) {
      throw VideoCompressionException(
        'Video sıkıştırılamadı: ${_shortError(error)}',
      );
    } finally {
      await progressSubscription?.cancel();
    }
  }

  Future<void> cancel() async {
    try {
      await _methodChannel.invokeMethod<void>('cancelCompression');
    } catch (_) {
      // Aktif sıkıştırma yoksa veya platform kapanıyorsa hata gösterilmez.
    }
  }

  String _platformErrorMessage(PlatformException error) {
    switch (error.code) {
      case 'unsupported_android':
        return 'Video sıkıştırma Android 6 veya daha yeni bir cihaz gerektiriyor.';
      case 'unsupported_resolution':
        return 'Cihaz bu çözünürlüğü değiştirmeden sıkıştıramıyor.';
      case 'compression_cancelled':
        return 'Video sıkıştırma iptal edildi.';
      case 'output_too_large':
        return 'Video çözünürlüğü korunarak 40 MB sınırına indirilemedi.';
      case 'compression_busy':
        return 'Başka bir video hâlâ sıkıştırılıyor.';
      default:
        final message = error.message?.trim() ?? '';
        return message.isEmpty ? 'Video sıkıştırılamadı.' : message;
    }
  }

  Future<void> _safeDelete(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Temizleme hatası asıl hatayı gizlememeli.
    }
  }

  int _readInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _shortError(Object error) {
    final text = error.toString().trim();

    if (text.length <= 140) {
      return text;
    }

    return '${text.substring(0, 140)}...';
  }
}
