import 'dart:io';

class VideoCompressionResult {
  const VideoCompressionResult({
    required this.originalFile,
    required this.outputFile,
    required this.originalSizeBytes,
    required this.outputSizeBytes,
    required this.wasCompressed,
    required this.targetVideoBitrate,
  });

  final File originalFile;
  final File outputFile;
  final int originalSizeBytes;
  final int outputSizeBytes;
  final bool wasCompressed;
  final int targetVideoBitrate;

  Future<void> deleteTemporaryOutput() async {
    if (!wasCompressed || outputFile.path == originalFile.path) {
      return;
    }

    try {
      if (await outputFile.exists()) {
        await outputFile.delete();
      }
    } catch (_) {
      // Geçici dosya temizleme hatası ana kullanıcı akışını bozmamalı.
    }
  }
}

class VideoCompressionException implements Exception {
  const VideoCompressionException(this.message);

  final String message;

  @override
  String toString() => message;
}
