import 'dart:io';

enum VideoCompressionFailureCode {
  unsupportedPlatform,
  invalidInput,
  invalidArguments,
  busy,
  cancelled,
  unsupportedResolution,
  outputTooLarge,
  videoTooLong,
  pluginUnavailable,
  pluginDisposed,
  outputUnavailable,
  startFailed,
  fileSystem,
  unknown,
}

class VideoCompressionResult {
  const VideoCompressionResult({
    required this.originalFile,
    required this.outputFile,
    required this.originalSizeBytes,
    required this.outputSizeBytes,
    required this.wasCompressed,
    required this.targetVideoBitrate,
    required this.outputWidth,
    required this.outputHeight,
    required this.attemptCount,
  });

  factory VideoCompressionResult.passthrough({
    required File sourceFile,
    required int sizeBytes,
    required int width,
    required int height,
  }) {
    return VideoCompressionResult(
      originalFile: sourceFile,
      outputFile: sourceFile,
      originalSizeBytes: sizeBytes,
      outputSizeBytes: sizeBytes,
      wasCompressed: false,
      targetVideoBitrate: 0,
      outputWidth: width,
      outputHeight: height,
      attemptCount: 0,
    );
  }

  final File originalFile;
  final File outputFile;

  final int originalSizeBytes;
  final int outputSizeBytes;

  final bool wasCompressed;

  /// Native encoder'a istenen video bitrate değeri.
  final int targetVideoBitrate;

  final int outputWidth;
  final int outputHeight;

  /// Native tarafta yapılan toplam export denemesi.
  final int attemptCount;

  bool get ownsTemporaryOutput {
    return wasCompressed && outputFile.path != originalFile.path;
  }

  int get savedBytes {
    final difference = originalSizeBytes - outputSizeBytes;

    return difference > 0 ? difference : 0;
  }

  double get compressionRatio {
    if (originalSizeBytes <= 0) {
      return 1;
    }

    return outputSizeBytes / originalSizeBytes;
  }

  double get savedFraction {
    if (originalSizeBytes <= 0) {
      return 0;
    }

    return (savedBytes / originalSizeBytes).clamp(0, 1).toDouble();
  }

  Future<void> deleteTemporaryOutput() async {
    if (!ownsTemporaryOutput) {
      return;
    }

    try {
      if (await outputFile.exists()) {
        await outputFile.delete();
      }
    } on FileSystemException {
      // Geçici dosya temizleme sorunu ana kullanıcı akışını bozmaz.
    }
  }
}

class VideoCompressionException implements Exception {
  const VideoCompressionException(
    this.message, {
    this.code = VideoCompressionFailureCode.unknown,
    this.cause,
  });

  final String message;
  final VideoCompressionFailureCode code;
  final Object? cause;

  bool get isCancelled {
    return code == VideoCompressionFailureCode.cancelled;
  }

  bool get canRetry {
    switch (code) {
      case VideoCompressionFailureCode.busy:
      case VideoCompressionFailureCode.fileSystem:
      case VideoCompressionFailureCode.startFailed:
      case VideoCompressionFailureCode.unknown:
        return true;

      case VideoCompressionFailureCode.unsupportedPlatform:
      case VideoCompressionFailureCode.invalidInput:
      case VideoCompressionFailureCode.invalidArguments:
      case VideoCompressionFailureCode.cancelled:
      case VideoCompressionFailureCode.unsupportedResolution:
      case VideoCompressionFailureCode.outputTooLarge:
      case VideoCompressionFailureCode.videoTooLong:
      case VideoCompressionFailureCode.pluginUnavailable:
      case VideoCompressionFailureCode.pluginDisposed:
      case VideoCompressionFailureCode.outputUnavailable:
        return false;
    }
  }

  @override
  String toString() => message;
}
