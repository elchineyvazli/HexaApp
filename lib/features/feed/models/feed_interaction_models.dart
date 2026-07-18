import 'package:cloud_firestore/cloud_firestore.dart';

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

  static const List<SignalReason> primaryReasons = <SignalReason>[
    helpful,
    learnedSomething,
    inspired,
    thoughtProvoking,
    encouraging,
  ];

  static SignalReason? fromValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();

    for (final reason in values) {
      if (reason.value == normalized ||
          reason.name.toLowerCase() == normalized) {
        return reason;
      }
    }

    return null;
  }
}

extension SignalReasonPresentation on SignalReason {
  String get label {
    switch (this) {
      case SignalReason.helpful:
        return 'Faydalı';
      case SignalReason.learnedSomething:
        return 'Öğretici';
      case SignalReason.inspired:
        return 'İlham verdi';
      case SignalReason.thoughtProvoking:
        return 'Düşündürdü';
      case SignalReason.encouraging:
        return 'Cesaret verdi';
      case SignalReason.entertaining:
        return 'Keyif verdi';
      case SignalReason.artistic:
        return 'Yaratıcı';
      case SignalReason.other:
        return 'Değer kattı';
    }
  }

  String get emoji {
    switch (this) {
      case SignalReason.helpful:
        return '🤝';
      case SignalReason.learnedSomething:
        return '💡';
      case SignalReason.inspired:
        return '✨';
      case SignalReason.thoughtProvoking:
        return '🧠';
      case SignalReason.encouraging:
        return '🔥';
      case SignalReason.entertaining:
        return '😊';
      case SignalReason.artistic:
        return '🎨';
      case SignalReason.other:
        return '❤️';
    }
  }

  String get description {
    switch (this) {
      case SignalReason.helpful:
        return 'Günlük hayatıma veya bir sorunuma katkı sağladı.';
      case SignalReason.learnedSomething:
        return 'Bana yeni ve uygulanabilir bir şey öğretti.';
      case SignalReason.inspired:
        return 'Yeni bir fikir ya da hareket enerjisi verdi.';
      case SignalReason.thoughtProvoking:
        return 'Bir konuya farklı açıdan bakmamı sağladı.';
      case SignalReason.encouraging:
        return 'Denemek ve devam etmek için cesaret verdi.';
      case SignalReason.entertaining:
        return 'Kaliteli ve iyi hissettiren bir deneyimdi.';
      case SignalReason.artistic:
        return 'Yaratıcılığı ve anlatımıyla değer kattı.';
      case SignalReason.other:
        return 'Bende anlamlı bir etki bıraktı.';
    }
  }
}

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
    final normalized = value?.toString().trim().toLowerCase();

    for (final rarity in values) {
      if (rarity.value == normalized ||
          rarity.name.toLowerCase() == normalized) {
        return rarity;
      }
    }

    return fallback;
  }
}

class SignalModel {
  const SignalModel({
    required this.videoId,
    required this.userId,
    required this.reason,
    this.qualifiedWatchMs = 0,
    this.sessionId = '',
    this.createdAt,
    this.updatedAt,
  });

  final String videoId;
  final String userId;
  final SignalReason reason;
  final int qualifiedWatchMs;
  final String sessionId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SignalModel.fromMap({
    required Map<String, dynamic> map,
    required String videoId,
    required String userId,
  }) {
    return SignalModel(
      videoId: videoId,
      userId: userId,
      reason: SignalReason.fromValue(map['reason']) ?? SignalReason.other,
      qualifiedWatchMs: _readNonNegativeInt(map['qualifiedWatchMs']),
      sessionId: map['sessionId']?.toString().trim() ?? '',
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

class ArtifactModel {
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
  });

  final String id;
  final String name;
  final String emoji;

  final String assetUrl;
  final String animationUrl;

  final int coinCost;
  final ArtifactRarity rarity;
  final bool isActive;

  final int discoveryPulseUnits;

  @Deprecated('cost yerine coinCost kullanın.')
  int get cost => coinCost;

  bool get isAnimated => animationUrl.trim().isNotEmpty;

  bool get hasVisualAsset {
    return assetUrl.trim().isNotEmpty ||
        animationUrl.trim().isNotEmpty ||
        emoji.trim().isNotEmpty;
  }

  factory ArtifactModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ArtifactModel(
      id: documentId,
      name: _firstNonEmpty(<Object?>[map['name']], fallback: 'Hexa Artefaktı'),
      emoji: _firstNonEmpty(<Object?>[map['emoji']]),
      assetUrl: _firstNonEmpty(<Object?>[map['assetUrl'], map['imageUrl']]),
      animationUrl: _firstNonEmpty(<Object?>[
        map['animationUrl'],
        map['lottieUrl'],
      ]),
      coinCost: _readNonNegativeInt(map['coinCost'] ?? map['cost']),
      rarity: ArtifactRarity.fromValue(map['rarity']),
      isActive: _readBool(map['isActive'], fallback: true),
      discoveryPulseUnits: _readNonNegativeInt(map['discoveryPulseUnits']),
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

  factory StickerModel.fromMap(Map<String, dynamic> map, String documentId) {
    final artifact = ArtifactModel.fromMap(map, documentId);

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

String _firstNonEmpty(List<Object?> values, {String fallback = ''}) {
  for (final value in values) {
    final parsed = value?.toString().trim() ?? '';

    if (parsed.isNotEmpty) {
      return parsed;
    }
  }

  return fallback;
}

int _readNonNegativeInt(Object? value) {
  final parsed = value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '') ?? 0;

  return parsed < 0 ? 0 : parsed;
}

bool _readBool(Object? value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }

  final normalized = value?.toString().trim().toLowerCase();

  if (normalized == 'true' || normalized == '1') {
    return true;
  }

  if (normalized == 'false' || normalized == '0') {
    return false;
  }

  return fallback;
}

DateTime? _readDateTime(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    return DateTime.tryParse(value);
  }

  if (value is num) {
    final timestamp = value.toInt();

    return DateTime.fromMillisecondsSinceEpoch(
      timestamp.abs() < 100000000000 ? timestamp * 1000 : timestamp,
      isUtc: true,
    );
  }

  return null;
}
