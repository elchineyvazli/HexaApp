abstract final class VideoUploadLimits {
  const VideoUploadLimits._();

  /// Galeriden seçilebilecek kaynak dosya için cihaz koruma sınırı.
  ///
  /// Firebase'e bu boyutta dosya gönderilmez. Büyük kaynaklar cihazda
  /// sıkıştırıldıktan sonra [maxUploadFileSizeBytes] sınırına indirilir.
  static const int maxSourceFileSizeBytes = 1024 * 1024 * 1024;

  /// Firebase Storage'a gönderilebilecek nihai video boyutu.
  static const int maxUploadFileSizeBytes = 40 * 1024 * 1024;

  /// MP4 container ve encoder sapmaları için 2 MB güvenlik payı bırakılır.
  static const int compressionTargetBytes = 38 * 1024 * 1024;

  static const int maxThumbnailSizeBytes = 8 * 1024 * 1024;

  static const Duration minDuration = Duration(seconds: 1);
  static const Duration maxDuration = Duration(minutes: 3);

  /// DCI 4K dahil olmak üzere çözünürlük korunur.
  ///
  /// Cihazın donanım encoder'ı çözünürlüğü desteklemiyorsa video gizlice
  /// küçültülmez; kullanıcıya hata gösterilir.
  static const int maxDimension = 4096;
  static const double minAspectRatio = 0.2;
  static const double maxAspectRatio = 5.0;

  static const int thumbnailMaxWidth = 720;
  static const int thumbnailFallbackWidth = 540;
  static const int thumbnailQuality = 85;
  static const int thumbnailFallbackQuality = 75;

  static const Duration metadataReadTimeout = Duration(seconds: 25);
  static const Duration thumbnailGenerationTimeout = Duration(seconds: 25);

  /// Eski kodların kırılmaması için nihai upload sınırına yönlendirilir.
  @Deprecated('maxUploadFileSizeBytes kullanın.')
  static const int maxFileSizeBytes = maxUploadFileSizeBytes;
}
