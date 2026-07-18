abstract final class VideoUploadLimits {
  static const int bytesPerKiB = 1024;
  static const int bytesPerMiB = bytesPerKiB * 1024;
  static const int bytesPerGiB = bytesPerMiB * 1024;

  /// Kullanıcının cihazından seçilebilecek kaynak video sınırı.
  ///
  /// Bu boyuttaki dosya doğrudan Firebase Storage'a gönderilmez.
  static const int maxSourceFileSizeBytes = bytesPerGiB;

  /// Firebase Storage'a gönderilebilecek nihai video boyutu.
  static const int maxUploadFileSizeBytes = 40 * bytesPerMiB;

  /// Encoder ve MP4 container sapmaları için 2 MiB boşluk bırakılır.
  static const int compressionTargetBytes = 38 * bytesPerMiB;

  static const int maxThumbnailSizeBytes = 8 * bytesPerMiB;

  static const Duration minDuration = Duration(seconds: 1);
  static const Duration maxDuration = Duration(minutes: 3);

  /// DCI 4K dahil olmak üzere kabul edilen en büyük kenar.
  static const int maxDimension = 4096;
  static const int minDimension = 2;

  static const double minAspectRatio = 0.2;
  static const double maxAspectRatio = 5;

  /// Native encoder bazı H.264 profillerinde tek sayılı boyutu bir piksel
  /// azaltabilir. Metadata okuyucuları da container bilgisini farklı
  /// yuvarlayabilir.
  static const int outputDimensionTolerancePixels = 2;

  /// Export edilen videonun süresinde kabul edilen zaman sapması.
  static const int minimumDurationDriftMs = 500;
  static const int maximumDurationDriftMs = 1500;
  static const double durationDriftFraction = 0.01;

  static const int thumbnailMaxWidth = 720;
  static const int thumbnailFallbackWidth = 540;
  static const int thumbnailQuality = 85;
  static const int thumbnailFallbackQuality = 75;

  static const int fileHeaderProbeBytes = 4096;

  static const Duration sourceInspectionTimeout = Duration(seconds: 10);

  static const Duration fileHeaderReadTimeout = Duration(seconds: 8);

  static const Duration metadataReadTimeout = Duration(seconds: 25);

  static const Duration thumbnailGenerationTimeout = Duration(seconds: 25);

  static bool isSupportedDuration(int durationMs) {
    return durationMs >= minDuration.inMilliseconds &&
        durationMs <= maxDuration.inMilliseconds;
  }

  static bool isSupportedDimension({required int width, required int height}) {
    return width >= minDimension &&
        height >= minDimension &&
        width <= maxDimension &&
        height <= maxDimension;
  }

  static bool isSupportedAspectRatio(double ratio) {
    return ratio.isFinite && ratio >= minAspectRatio && ratio <= maxAspectRatio;
  }

  static int allowedDurationDriftMs(int sourceDurationMs) {
    final proportionalDrift = (sourceDurationMs * durationDriftFraction)
        .round();

    return proportionalDrift
        .clamp(minimumDurationDriftMs, maximumDurationDriftMs)
        .toInt();
  }

  @Deprecated('maxUploadFileSizeBytes kullanın.')
  static const int maxFileSizeBytes = maxUploadFileSizeBytes;
}
