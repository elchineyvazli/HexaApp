import 'package:cloud_firestore/cloud_firestore.dart';

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
    final normalized = value?.toString().trim().toLowerCase();

    for (final status in values) {
      if (status.value == normalized ||
          status.name.toLowerCase() == normalized) {
        return status;
      }
    }

    return fallback;
  }
}

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
    final normalized = value?.toString().trim().toLowerCase();

    for (final visibility in values) {
      if (visibility.value == normalized ||
          visibility.name.toLowerCase() == normalized) {
        return visibility;
      }
    }

    return fallback;
  }
}

class VideoModel {
  const VideoModel({
    required this.id,
    required this.videoUrl,
    required this.username,
    required this.caption,
    required this.uploaderId,
    this.schemaVersion = 1,
    this.hlsUrl = '',
    this.thumbnailUrl = '',
    this.renditionUrls = const <String, String>{},
    this.uploaderDisplayName = '',
    this.uploaderAvatarUrl = '',
    int? signalCount,
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
    this.storedAspectRatio = 0,
    this.processingStatus = VideoProcessingStatus.ready,
    this.visibility = VideoVisibility.publicFeed,
    this.createdAt,
    this.publishedAt,
    this.updatedAt,
  }) : assert(signalCount == null || likes == null || signalCount == likes),
       signalCount = signalCount ?? likes ?? 0;

  final String id;
  final int schemaVersion;

  final String videoUrl;
  final String hlsUrl;
  final String thumbnailUrl;
  final Map<String, String> renditionUrls;

  final String username;
  final String caption;

  final String uploaderId;
  final String uploaderDisplayName;
  final String uploaderAvatarUrl;

  final int signalCount;
  final int uniqueSignalersCount;
  final Map<String, int> signalDistribution;

  final int viewsCount;
  final int sharesCount;
  final int commentsCount;

  final int artifactCount;
  final int uniqueArtifactSupportersCount;

  final double impactScore;

  final int durationMs;
  final int width;
  final int height;
  final double storedAspectRatio;

  final VideoProcessingStatus processingStatus;
  final VideoVisibility visibility;

  final DateTime? createdAt;
  final DateTime? publishedAt;
  final DateTime? updatedAt;

  @Deprecated('likes yerine signalCount kullanın.')
  int get likes => signalCount;

  String get creatorName {
    final displayName = uploaderDisplayName.trim();

    return displayName.isNotEmpty ? displayName : username;
  }

  bool get hasCaption => caption.trim().isNotEmpty;

  bool get hasUploaderProfile {
    final id = uploaderId.trim();

    return id.isNotEmpty && id != 'unknown_user' && id != 'system_admin';
  }

  bool get isReady {
    return processingStatus == VideoProcessingStatus.ready &&
        playbackUrl.trim().isNotEmpty;
  }

  bool get isPubliclyVisible {
    return visibility == VideoVisibility.publicFeed &&
        processingStatus != VideoProcessingStatus.rejected &&
        processingStatus != VideoProcessingStatus.archived;
  }

  bool get isFeedEligible {
    return isReady && isPubliclyVisible;
  }

  bool get hasAdaptiveStreaming {
    return hlsUrl.trim().isNotEmpty;
  }

  bool get hasDimensions => width > 0 && height > 0;

  String get searchableText {
    return <String>[
      caption,
      username,
      uploaderDisplayName,
    ].join(' ').toLowerCase();
  }

  String get playbackUrl {
    final adaptiveUrl = hlsUrl.trim();

    if (adaptiveUrl.isNotEmpty) {
      return adaptiveUrl;
    }

    // Mobil trafikte 720p, 1080p'den önce tercih edilir.
    for (final quality in const <String>['720p', '540p', '360p', '1080p']) {
      final url = renditionUrls[quality]?.trim() ?? '';

      if (url.isNotEmpty) {
        return url;
      }
    }

    return videoUrl.trim();
  }

  DateTime get sortDate {
    return publishedAt ??
        createdAt ??
        updatedAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  double? get aspectRatio {
    if (width > 0 && height > 0) {
      final calculated = width / height;

      if (_isUsableAspectRatio(calculated)) {
        return calculated;
      }
    }

    if (_isUsableAspectRatio(storedAspectRatio)) {
      return storedAspectRatio;
    }

    return null;
  }

  bool matchesVideoQuery(String query) {
    final normalized = query.trim().toLowerCase();

    if (normalized.isEmpty) {
      return true;
    }

    return caption.toLowerCase().contains(normalized);
  }

  bool matchesUserQuery(String query) {
    final normalized = query.trim().toLowerCase().replaceFirst(
      RegExp(r'^@+'),
      '',
    );

    if (normalized.isEmpty) {
      return true;
    }

    final cleanUsername = username.toLowerCase().replaceFirst(
      RegExp(r'^@+'),
      '',
    );

    return cleanUsername.contains(normalized) ||
        uploaderDisplayName.toLowerCase().contains(normalized);
  }

  bool matchesHashtagQuery(String query) {
    final normalized = query.trim().toLowerCase().replaceFirst(
      RegExp(r'^#+'),
      '',
    );

    if (normalized.isEmpty) {
      return true;
    }

    return caption.toLowerCase().contains('#$normalized');
  }

  factory VideoModel.fromMap(Map<String, dynamic> map, String documentId) {
    final playback = _readDynamicMap(map['playback']);

    final rawUsername = _firstNonEmpty(<Object?>[
      map['username'],
      map['handle'],
      map['userName'],
    ]);

    final uploaderId = _firstNonEmpty(<Object?>[
      map['uploaderId'],
      map['userId'],
      map['ownerId'],
    ], fallback: 'unknown_user');

    final signalCount = _firstAvailableInt(<Object?>[
      map['signalCount'],
      map['signalsCount'],
      map['likesCount'],
      map['likes'],
    ]);

    return VideoModel(
      id: documentId,
      schemaVersion: _readInt(map['schemaVersion'], 1),
      videoUrl: _firstNonEmpty(<Object?>[
        map['videoUrl'],
        map['originalVideoUrl'],
        playback['videoUrl'],
        playback['originalVideoUrl'],
      ]),
      hlsUrl: _firstNonEmpty(<Object?>[
        map['hlsUrl'],
        map['masterPlaylistUrl'],
        playback['hlsUrl'],
        playback['masterPlaylistUrl'],
      ]),
      thumbnailUrl: _firstNonEmpty(<Object?>[
        map['thumbnailUrl'],
        map['posterUrl'],
        playback['thumbnailUrl'],
        playback['posterUrl'],
      ]),
      renditionUrls: _readStringMap(
        map['renditionUrls'] ??
            map['renditions'] ??
            playback['renditionUrls'] ??
            playback['renditions'],
      ),
      username: _normalizeUsername(rawUsername),
      caption: _firstNonEmpty(<Object?>[map['caption'], map['description']]),
      uploaderId: uploaderId,
      uploaderDisplayName: _firstNonEmpty(<Object?>[
        map['uploaderDisplayName'],
        map['displayName'],
        rawUsername,
      ]),
      uploaderAvatarUrl: _firstNonEmpty(<Object?>[
        map['uploaderAvatarUrl'],
        map['profileImageUrl'],
        map['photoUrl'],
        map['avatarUrl'],
      ]),
      signalCount: signalCount,
      uniqueSignalersCount: _firstAvailableInt(<Object?>[
        map['uniqueSignalersCount'],
        map['uniqueSignalsCount'],
        signalCount,
      ]),
      signalDistribution: _readIntMap(map['signalDistribution']),
      viewsCount: _firstAvailableInt(<Object?>[
        map['viewsCount'],
        map['viewCount'],
      ]),
      sharesCount: _firstAvailableInt(<Object?>[
        map['sharesCount'],
        map['shareCount'],
      ]),
      commentsCount: _firstAvailableInt(<Object?>[
        map['commentsCount'],
        map['commentCount'],
      ]),
      artifactCount: _firstAvailableInt(<Object?>[
        map['artifactCount'],
        map['artifactsCount'],
        map['stickerCount'],
      ]),
      uniqueArtifactSupportersCount: _firstAvailableInt(<Object?>[
        map['uniqueArtifactSupportersCount'],
        map['artifactSupportersCount'],
      ]),
      impactScore: _readDouble(map['impactScore']),
      durationMs: _firstAvailableInt(<Object?>[
        map['durationMs'],
        playback['durationMs'],
      ]),
      width: _firstAvailableInt(<Object?>[
        map['width'],
        map['videoWidth'],
        playback['width'],
        playback['videoWidth'],
      ]),
      height: _firstAvailableInt(<Object?>[
        map['height'],
        map['videoHeight'],
        playback['height'],
        playback['videoHeight'],
      ]),
      storedAspectRatio: _firstAvailableDouble(<Object?>[
        map['aspectRatio'],
        map['videoAspectRatio'],
        playback['aspectRatio'],
        playback['videoAspectRatio'],
      ]),
      processingStatus: VideoProcessingStatus.fromValue(
        map['processingStatus'] ?? map['status'],
      ),
      visibility: VideoVisibility.fromValue(map['visibility']),
      createdAt: _readDateTime(map['createdAt']),
      publishedAt: _readDateTime(map['publishedAt']),
      updatedAt: _readDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap({bool includeServerManagedFields = false}) {
    final data = <String, dynamic>{
      'schemaVersion': 3,
      'videoUrl': videoUrl,
      'caption': caption,
      'description': caption,
      'username': username,
      'uploaderId': uploaderId,
      'uploaderDisplayName': uploaderDisplayName,
      'uploaderAvatarUrl': uploaderAvatarUrl,
      'processingStatus': processingStatus.value,
      'status': processingStatus.value,
      'visibility': visibility.value,
      'durationMs': durationMs,
      'width': width,
      'height': height,
      if (aspectRatio != null) 'aspectRatio': aspectRatio,
      if (hlsUrl.isNotEmpty) 'hlsUrl': hlsUrl,
      if (thumbnailUrl.isNotEmpty) 'thumbnailUrl': thumbnailUrl,
      if (renditionUrls.isNotEmpty) 'renditionUrls': renditionUrls,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (publishedAt != null) 'publishedAt': Timestamp.fromDate(publishedAt!),
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
    int? schemaVersion,
    String? videoUrl,
    String? hlsUrl,
    String? thumbnailUrl,
    Map<String, String>? renditionUrls,
    String? username,
    String? caption,
    String? uploaderId,
    String? uploaderDisplayName,
    String? uploaderAvatarUrl,
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
    double? storedAspectRatio,
    VideoProcessingStatus? processingStatus,
    VideoVisibility? visibility,
    DateTime? createdAt,
    DateTime? publishedAt,
    DateTime? updatedAt,
  }) {
    return VideoModel(
      id: id ?? this.id,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      videoUrl: videoUrl ?? this.videoUrl,
      hlsUrl: hlsUrl ?? this.hlsUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      renditionUrls: renditionUrls ?? this.renditionUrls,
      username: username ?? this.username,
      caption: caption ?? this.caption,
      uploaderId: uploaderId ?? this.uploaderId,
      uploaderDisplayName: uploaderDisplayName ?? this.uploaderDisplayName,
      uploaderAvatarUrl: uploaderAvatarUrl ?? this.uploaderAvatarUrl,
      signalCount: signalCount ?? this.signalCount,
      uniqueSignalersCount: uniqueSignalersCount ?? this.uniqueSignalersCount,
      signalDistribution: signalDistribution ?? this.signalDistribution,
      viewsCount: viewsCount ?? this.viewsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      artifactCount: artifactCount ?? this.artifactCount,
      uniqueArtifactSupportersCount:
          uniqueArtifactSupportersCount ?? this.uniqueArtifactSupportersCount,
      impactScore: impactScore ?? this.impactScore,
      durationMs: durationMs ?? this.durationMs,
      width: width ?? this.width,
      height: height ?? this.height,
      storedAspectRatio: storedAspectRatio ?? this.storedAspectRatio,
      processingStatus: processingStatus ?? this.processingStatus,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
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

bool _isUsableAspectRatio(double value) {
  return value.isFinite && value >= 0.2 && value <= 5;
}

String _firstNonEmpty(List<Object?> values, {String fallback = ''}) {
  for (final value in values) {
    final parsed = value?.toString().trim() ?? '';

    if (parsed.isNotEmpty) {
      return parsed;
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
      return value.toInt().clamp(0, 1 << 62);
    }

    final parsed = int.tryParse(value.toString());

    if (parsed != null) {
      return parsed < 0 ? 0 : parsed;
    }
  }

  return 0;
}

double _firstAvailableDouble(List<Object?> values) {
  for (final value in values) {
    final parsed = _readDouble(value);

    if (_isUsableAspectRatio(parsed)) {
      return parsed;
    }
  }

  return 0;
}

int _readInt(Object? value, [int fallback = 0]) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _readDouble(Object? value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _readDateTime(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  if (value is num) {
    final timestamp = value.toInt();

    final milliseconds = timestamp.abs() < 100000000000
        ? timestamp * 1000
        : timestamp;

    return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
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
      (key, mapValue) => MapEntry(key.toString(), mapValue),
    );
  }

  return const <String, dynamic>{};
}

Map<String, String> _readStringMap(Object? value) {
  final source = _readDynamicMap(value);
  final result = <String, String>{};

  for (final entry in source.entries) {
    final key = entry.key.trim();
    final url = entry.value?.toString().trim() ?? '';

    if (key.isNotEmpty && url.isNotEmpty) {
      result[key] = url;
    }
  }

  return Map<String, String>.unmodifiable(result);
}

Map<String, int> _readIntMap(Object? value) {
  final source = _readDynamicMap(value);
  final result = <String, int>{};

  for (final entry in source.entries) {
    final key = entry.key.trim();
    final count = _readInt(entry.value);

    if (key.isNotEmpty && count >= 0) {
      result[key] = count;
    }
  }

  return Map<String, int>.unmodifiable(result);
}
