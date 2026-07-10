// lib/features/feed/feed_models.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Kullanıcının bir videoya neden Signal gönderdiğini belirtir.
enum SignalReason {
  learnedSomething('learned_something'),
  inspired('inspired'),
  thoughtProvoking('thought_provoking'),
  helpful('helpful'),
  encouraging('encouraging'),
  entertaining('entertaining'),
  artistic('artistic'),
  other('other');

  const SignalReason(this.value);

  final String value;

  static SignalReason? fromValue(Object? value) {
    final normalizedValue = value?.toString().trim();

    for (final reason in SignalReason.values) {
      if (reason.value == normalizedValue ||
          reason.name == normalizedValue) {
        return reason;
      }
    }

    return null;
  }
}

/// Bir videonun yükleme ve işleme durumunu belirtir.
enum VideoProcessingStatus {
  draft('draft'),
  uploading('uploading'),
  uploaded('uploaded'),
  validating('validating'),
  processing('processing'),
  moderating('moderating'),
  ready('ready'),
  failed('failed'),
  rejected('rejected'),
  archived('archived');

  const VideoProcessingStatus(this.value);

  final String value;

  static VideoProcessingStatus fromValue(
    Object? value, {
    VideoProcessingStatus fallback = VideoProcessingStatus.ready,
  }) {
    final normalizedValue = value?.toString().trim();

    for (final status in VideoProcessingStatus.values) {
      if (status.value == normalizedValue ||
          status.name == normalizedValue) {
        return status;
      }
    }

    return fallback;
  }
}

/// Videonun kimler tarafından görüntülenebileceğini belirtir.
enum VideoVisibility {
  publicFeed('public'),
  followersOnly('followers_only'),
  ownerOnly('private');

  const VideoVisibility(this.value);

  final String value;

  static VideoVisibility fromValue(
    Object? value, {
    VideoVisibility fallback = VideoVisibility.publicFeed,
  }) {
    final normalizedValue = value?.toString().trim();

    for (final visibility in VideoVisibility.values) {
      if (visibility.value == normalizedValue ||
          visibility.name == normalizedValue) {
        return visibility;
      }
    }

    return fallback;
  }
}

/// Ücretli Artefaktın nadirlik sınıfı.
enum ArtifactRarity {
  common('common'),
  rare('rare'),
  epic('epic'),
  legendary('legendary');

  const ArtifactRarity(this.value);

  final String value;

  static ArtifactRarity fromValue(
    Object? value, {
    ArtifactRarity fallback = ArtifactRarity.common,
  }) {
    final normalizedValue = value?.toString().trim();

    for (final rarity in ArtifactRarity.values) {
      if (rarity.value == normalizedValue ||
          rarity.name == normalizedValue) {
        return rarity;
      }
    }

    return fallback;
  }
}

class VideoModel {
  final String id;

  /// Orijinal video veya eski kayıtlar için doğrudan oynatma bağlantısı.
  final String videoUrl;

  /// Adaptive streaming için HLS master playlist bağlantısı.
  final String hlsUrl;

  /// Video yüklenirken ve feed açılırken gösterilecek kapak görseli.
  final String thumbnailUrl;

  /// HLS henüz bulunmadığında kullanılabilecek kalite bağlantıları.
  ///
  /// Örnek:
  /// {
  ///   '360p': 'https://...',
  ///   '720p': 'https://...',
  ///   '1080p': 'https://...',
  /// }
  final Map<String, String> renditionUrls;

  final String username;
  final String caption;
  final String uploaderId;

  /// Beğeni yerine kullanılan gerçek Hexa etkileşim sayacı.
  final int signalCount;

  /// Birden fazla sahte etkileşimi ayırmak için benzersiz kullanıcı sayısı.
  final int uniqueSignalersCount;

  /// Signal nedenlerinin dağılımı.
  ///
  /// Örnek:
  /// {
  ///   'helpful': 12,
  ///   'inspired': 5,
  /// }
  final Map<String, int> signalDistribution;

  final int viewsCount;
  final int sharesCount;
  final int commentsCount;

  /// Videoya gönderilen toplam Artefakt sayısı.
  final int artifactCount;

  /// Artefakt gönderen benzersiz kullanıcı sayısı.
  final int uniqueArtifactSupportersCount;

  /// Sunucu tarafından hesaplanan keşfet ve etki puanı.
  ///
  /// Mobil uygulama bu değeri doğrudan değiştirmemelidir.
  final double impactScore;

  final int durationMs;
  final int width;
  final int height;

  final VideoProcessingStatus processingStatus;
  final VideoVisibility visibility;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VideoModel({
    required this.id,
    required this.videoUrl,
    required this.username,
    required this.caption,
    required this.uploaderId,
    this.hlsUrl = '',
    this.thumbnailUrl = '',
    this.renditionUrls = const <String, String>{},
    int? signalCount,

    /// Geçiş sürecinde eski VideoModel çağrılarının bozulmaması içindir.
    int? likes,
    this.uniqueSignalersCount = 0,
    this.signalDistribution = const <String, int>{},
    this.viewsCount = 0,
    this.sharesCount = 0,
    this.commentsCount = 0,
    this.artifactCount = 0,
    this.uniqueArtifactSupportersCount = 0,
    this.impactScore = 0,
    this.durationMs = 0,
    this.width = 0,
    this.height = 0,
    this.processingStatus = VideoProcessingStatus.ready,
    this.visibility = VideoVisibility.publicFeed,
    this.createdAt,
    this.updatedAt,
  }) : assert(
         signalCount == null || likes == null || signalCount == likes,
         'signalCount ve eski likes değeri aynı anda farklı olamaz.',
       ),
       assert((signalCount ?? likes ?? 0) >= 0),
       assert(uniqueSignalersCount >= 0),
       assert(viewsCount >= 0),
       assert(sharesCount >= 0),
       assert(commentsCount >= 0),
       assert(artifactCount >= 0),
       assert(uniqueArtifactSupportersCount >= 0),
       assert(durationMs >= 0),
       assert(width >= 0),
       assert(height >= 0),
       signalCount = signalCount ?? likes ?? 0;

  /// Diğer dosyalar değiştirilene kadar eski kullanımları bozmaz.
  @Deprecated('likes yerine signalCount kullanın.')
  int get likes => signalCount;

  /// Oynatıcı için kullanılabilecek en uygun bağlantı.
  String get playbackUrl {
    if (hlsUrl.trim().isNotEmpty) {
      return hlsUrl;
    }

    for (final quality in const <String>[
      '1080p',
      '720p',
      '540p',
      '360p',
    ]) {
      final url = renditionUrls[quality];

      if (url != null && url.trim().isNotEmpty) {
        return url;
      }
    }

    return videoUrl;
  }

  bool get hasAdaptiveStreaming => hlsUrl.trim().isNotEmpty;

  bool get isReady =>
      processingStatus == VideoProcessingStatus.ready &&
      playbackUrl.trim().isNotEmpty;

  double? get aspectRatio {
    if (width <= 0 || height <= 0) {
      return null;
    }

    return width / height;
  }

  factory VideoModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    final playbackMap = _readDynamicMap(map['playback']);

    final uploaderId = _firstNonEmpty(
      <Object?>[
        map['uploaderId'],
        map['userId'],
        map['ownerId'],
      ],
      fallback: 'unknown_user',
    );

    final rawUsername = _firstNonEmpty(
      <Object?>[
        map['username'],
        map['handle'],
        map['userName'],
      ],
    );

    final signalCount = _firstAvailableInt(
      <Object?>[
        map['signalCount'],
        map['signalsCount'],

        // Eski Firestore verileri için geçici geri uyumluluk.
        map['likesCount'],
        map['likes'],
      ],
    );

    final renditionUrls = _readStringMap(
      map['renditionUrls'] ??
          map['renditions'] ??
          playbackMap['renditionUrls'] ??
          playbackMap['renditions'],
    );

    return VideoModel(
      id: docId,
      videoUrl: _firstNonEmpty(
        <Object?>[
          map['videoUrl'],
          map['originalVideoUrl'],
          playbackMap['videoUrl'],
          playbackMap['originalVideoUrl'],
        ],
      ),
      hlsUrl: _firstNonEmpty(
        <Object?>[
          map['hlsUrl'],
          map['masterPlaylistUrl'],
          playbackMap['hlsUrl'],
          playbackMap['masterPlaylistUrl'],
        ],
      ),
      thumbnailUrl: _firstNonEmpty(
        <Object?>[
          map['thumbnailUrl'],
          map['posterUrl'],
          playbackMap['thumbnailUrl'],
          playbackMap['posterUrl'],
        ],
      ),
      renditionUrls: renditionUrls,
      username: _normalizeUsername(rawUsername),
      caption: _firstNonEmpty(
        <Object?>[
          map['caption'],
          map['description'],
        ],
      ),
      uploaderId: uploaderId,
      signalCount: signalCount,
      uniqueSignalersCount: _firstAvailableInt(
        <Object?>[
          map['uniqueSignalersCount'],
          map['uniqueSignalsCount'],
          signalCount,
        ],
      ),
      signalDistribution: _readIntMap(map['signalDistribution']),
      viewsCount: _firstAvailableInt(
        <Object?>[
          map['viewsCount'],
          map['viewCount'],
        ],
      ),
      sharesCount: _firstAvailableInt(
        <Object?>[
          map['sharesCount'],
          map['shareCount'],
        ],
      ),
      commentsCount: _firstAvailableInt(
        <Object?>[
          map['commentsCount'],
          map['commentCount'],
        ],
      ),
      artifactCount: _firstAvailableInt(
        <Object?>[
          map['artifactCount'],
          map['artifactsCount'],
          map['stickerCount'],
        ],
      ),
      uniqueArtifactSupportersCount: _firstAvailableInt(
        <Object?>[
          map['uniqueArtifactSupportersCount'],
          map['artifactSupportersCount'],
        ],
      ),
      impactScore: _readDouble(map['impactScore']),
      durationMs: _firstAvailableInt(
        <Object?>[
          map['durationMs'],
          playbackMap['durationMs'],
        ],
      ),
      width: _firstAvailableInt(
        <Object?>[
          map['width'],
          playbackMap['width'],
        ],
      ),
      height: _firstAvailableInt(
        <Object?>[
          map['height'],
          playbackMap['height'],
        ],
      ),
      processingStatus: VideoProcessingStatus.fromValue(
        map['processingStatus'] ?? map['status'],
      ),
      visibility: VideoVisibility.fromValue(map['visibility']),
      createdAt: _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(map['updatedAt']),
    );
  }

  /// Varsayılan olarak yalnızca istemcinin güvenle yazabileceği alanları döndürür.
  ///
  /// Sayaçlar ve impactScore gibi sunucu tarafından yönetilecek alanlar ancak
  /// [includeServerManagedFields] true verilirse eklenir.
  Map<String, dynamic> toMap({
    bool includeServerManagedFields = false,
  }) {
    final data = <String, dynamic>{
      'schemaVersion': 2,
      'videoUrl': videoUrl,
      'username': username,
      'description': caption,
      'uploaderId': uploaderId,
      'processingStatus': processingStatus.value,
      'visibility': visibility.value,
      'durationMs': durationMs,
      'width': width,
      'height': height,
      if (hlsUrl.isNotEmpty) 'hlsUrl': hlsUrl,
      if (thumbnailUrl.isNotEmpty) 'thumbnailUrl': thumbnailUrl,
      if (renditionUrls.isNotEmpty) 'renditionUrls': renditionUrls,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };

    if (includeServerManagedFields) {
      data.addAll(<String, dynamic>{
        'signalCount': signalCount,
        'uniqueSignalersCount': uniqueSignalersCount,
        'signalDistribution': signalDistribution,
        'viewsCount': viewsCount,
        'sharesCount': sharesCount,
        'commentsCount': commentsCount,
        'artifactCount': artifactCount,
        'uniqueArtifactSupportersCount': uniqueArtifactSupportersCount,
        'impactScore': impactScore,
      });
    }

    return data;
  }

  VideoModel copyWith({
    String? id,
    String? videoUrl,
    String? hlsUrl,
    String? thumbnailUrl,
    Map<String, String>? renditionUrls,
    String? username,
    String? caption,
    String? uploaderId,
    int? signalCount,
    int? uniqueSignalersCount,
    Map<String, int>? signalDistribution,
    int? viewsCount,
    int? sharesCount,
    int? commentsCount,
    int? artifactCount,
    int? uniqueArtifactSupportersCount,
    double? impactScore,
    int? durationMs,
    int? width,
    int? height,
    VideoProcessingStatus? processingStatus,
    VideoVisibility? visibility,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VideoModel(
      id: id ?? this.id,
      videoUrl: videoUrl ?? this.videoUrl,
      hlsUrl: hlsUrl ?? this.hlsUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      renditionUrls: renditionUrls ?? this.renditionUrls,
      username: username ?? this.username,
      caption: caption ?? this.caption,
      uploaderId: uploaderId ?? this.uploaderId,
      signalCount: signalCount ?? this.signalCount,
      uniqueSignalersCount:
          uniqueSignalersCount ?? this.uniqueSignalersCount,
      signalDistribution:
          signalDistribution ?? this.signalDistribution,
      viewsCount: viewsCount ?? this.viewsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      artifactCount: artifactCount ?? this.artifactCount,
      uniqueArtifactSupportersCount:
          uniqueArtifactSupportersCount ??
          this.uniqueArtifactSupportersCount,
      impactScore: impactScore ?? this.impactScore,
      durationMs: durationMs ?? this.durationMs,
      width: width ?? this.width,
      height: height ?? this.height,
      processingStatus: processingStatus ?? this.processingStatus,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Bir kullanıcının belirli bir videoya gönderdiği tek aktif Signal kaydı.
///
/// Firestore önerilen yol:
/// videos/{videoId}/signals/{userId}
class SignalModel {
  final String videoId;
  final String userId;
  final SignalReason reason;
  final int qualifiedWatchMs;
  final String sessionId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SignalModel({
    required this.videoId,
    required this.userId,
    required this.reason,
    this.qualifiedWatchMs = 0,
    this.sessionId = '',
    this.createdAt,
    this.updatedAt,
  }) : assert(qualifiedWatchMs >= 0);

  factory SignalModel.fromMap({
    required Map<String, dynamic> map,
    required String videoId,
    required String userId,
  }) {
    return SignalModel(
      videoId: videoId,
      userId: userId,
      reason:
          SignalReason.fromValue(map['reason']) ??
          SignalReason.other,
      qualifiedWatchMs: _readInt(map['qualifiedWatchMs']),
      sessionId: _readString(map['sessionId']),
      createdAt: _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'videoId': videoId,
      'userId': userId,
      'reason': reason.value,
      'qualifiedWatchMs': qualifiedWatchMs,
      'sessionId': sessionId,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}

/// Videolara ücretli olarak gönderilebilen Hexa Artefaktı.
class ArtifactModel {
  final String id;
  final String name;

  /// İlk prototipte kullanılabilecek emoji karşılığı.
  final String emoji;

  /// Statik görsel Artefakt bağlantısı.
  final String assetUrl;

  /// Animasyonlu Artefakt bağlantısı.
  final String animationUrl;

  final int coinCost;
  final ArtifactRarity rarity;
  final bool isActive;

  /// Videoya kontrollü ek keşif testi sağlayacak miktar.
  ///
  /// Bu değer doğrudan kalıcı sıralama puanı değildir.
  final int discoveryPulseUnits;

  const ArtifactModel({
    required this.id,
    required this.name,
    this.emoji = '',
    this.assetUrl = '',
    this.animationUrl = '',
    this.coinCost = 0,
    this.rarity = ArtifactRarity.common,
    this.isActive = true,
    this.discoveryPulseUnits = 0,
  }) : assert(coinCost >= 0),
       assert(discoveryPulseUnits >= 0);

  /// Eski StickerModel ekranları değiştirilene kadar uyumluluk sağlar.
  @Deprecated('cost yerine coinCost kullanın.')
  int get cost => coinCost;

  bool get isAnimated => animationUrl.trim().isNotEmpty;

  factory ArtifactModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    return ArtifactModel(
      id: docId,
      name: _readString(map['name'], 'Hexa Artifact'),
      emoji: _readString(map['emoji']),
      assetUrl: _firstNonEmpty(
        <Object?>[
          map['assetUrl'],
          map['imageUrl'],
        ],
      ),
      animationUrl: _firstNonEmpty(
        <Object?>[
          map['animationUrl'],
          map['lottieUrl'],
        ],
      ),
      coinCost: _firstAvailableInt(
        <Object?>[
          map['coinCost'],
          map['cost'],
        ],
      ),
      rarity: ArtifactRarity.fromValue(map['rarity']),
      isActive: _readBool(map['isActive'], fallback: true),
      discoveryPulseUnits: _readInt(map['discoveryPulseUnits']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'emoji': emoji,
      'assetUrl': assetUrl,
      'animationUrl': animationUrl,
      'coinCost': coinCost,
      'rarity': rarity.value,
      'isActive': isActive,
      'discoveryPulseUnits': discoveryPulseUnits,
    };
  }
}

/// Eski ekranlar dönüştürülene kadar projeyi çalışır tutan geçici sınıf.
///
/// Yeni kodlarda ArtifactModel kullanılacaktır.
@Deprecated('StickerModel yerine ArtifactModel kullanın.')
class StickerModel extends ArtifactModel {
  const StickerModel({
    required String id,
    required String emoji,
    required String name,
    required int cost,
    String assetUrl = '',
    String animationUrl = '',
    ArtifactRarity rarity = ArtifactRarity.common,
    bool isActive = true,
    int discoveryPulseUnits = 0,
  }) : super(
         id: id,
         emoji: emoji,
         name: name,
         coinCost: cost,
         assetUrl: assetUrl,
         animationUrl: animationUrl,
         rarity: rarity,
         isActive: isActive,
         discoveryPulseUnits: discoveryPulseUnits,
       );

  factory StickerModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    final artifact = ArtifactModel.fromMap(map, docId);

    return StickerModel(
      id: artifact.id,
      emoji: artifact.emoji,
      name: artifact.name,
      cost: artifact.coinCost,
      assetUrl: artifact.assetUrl,
      animationUrl: artifact.animationUrl,
      rarity: artifact.rarity,
      isActive: artifact.isActive,
      discoveryPulseUnits: artifact.discoveryPulseUnits,
    );
  }
}

String _normalizeUsername(String value) {
  final username = value.trim();

  if (username.isEmpty) {
    return '@hexa_user';
  }

  return username.startsWith('@') ? username : '@$username';
}

String _firstNonEmpty(
  List<Object?> values, {
  String fallback = '',
}) {
  for (final value in values) {
    final parsedValue = _readString(value);

    if (parsedValue.isNotEmpty) {
      return parsedValue;
    }
  }

  return fallback;
}

int _firstAvailableInt(List<Object?> values) {
  for (final value in values) {
    if (value == null) {
      continue;
    }

    if (value is num) {
      return value.toInt();
    }

    final parsedValue = int.tryParse(value.toString());

    if (parsedValue != null) {
      return parsedValue;
    }
  }

  return 0;
}

String _readString(
  Object? value, [
  String fallback = '',
]) {
  final parsedValue = value?.toString().trim();

  if (parsedValue == null || parsedValue.isEmpty) {
    return fallback;
  }

  return parsedValue;
}

int _readInt(
  Object? value, [
  int fallback = 0,
]) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _readDouble(
  Object? value, [
  double fallback = 0,
]) {
  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _readBool(
  Object? value, {
  bool fallback = false,
}) {
  if (value is bool) {
    return value;
  }

  final normalizedValue = value?.toString().trim().toLowerCase();

  if (normalizedValue == 'true' || normalizedValue == '1') {
    return true;
  }

  if (normalizedValue == 'false' || normalizedValue == '0') {
    return false;
  }

  return fallback;
}

DateTime? _readDateTime(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  if (value is num) {
    final rawTimestamp = value.toInt();

    final milliseconds = rawTimestamp.abs() < 100000000000
        ? rawTimestamp * 1000
        : rawTimestamp;

    return DateTime.fromMillisecondsSinceEpoch(
      milliseconds,
      isUtc: true,
    );
  }

  if (value is String) {
    return DateTime.tryParse(value);
  }

  return null;
}

Map<String, dynamic> _readDynamicMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map<Object?, Object?>) {
    return value.map<String, dynamic>(
      (key, mapValue) => MapEntry<String, dynamic>(
        key.toString(),
        mapValue,
      ),
    );
  }

  return const <String, dynamic>{};
}

Map<String, String> _readStringMap(Object? value) {
  final source = _readDynamicMap(value);

  if (source.isEmpty) {
    return const <String, String>{};
  }

  final result = <String, String>{};

  for (final entry in source.entries) {
    final parsedValue = _readString(entry.value);

    if (entry.key.trim().isNotEmpty && parsedValue.isNotEmpty) {
      result[entry.key] = parsedValue;
    }
  }

  return result;
}

Map<String, int> _readIntMap(Object? value) {
  final source = _readDynamicMap(value);

  if (source.isEmpty) {
    return const <String, int>{};
  }

  final result = <String, int>{};

  for (final entry in source.entries) {
    final parsedValue = _readInt(entry.value);

    if (entry.key.trim().isNotEmpty && parsedValue >= 0) {
      result[entry.key] = parsedValue;
    }
  }

  return result;
}