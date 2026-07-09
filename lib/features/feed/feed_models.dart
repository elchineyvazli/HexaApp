// lib/features/feed/feed_models.dart

class VideoModel {
  final String id;
  final String videoUrl;
  final String username;
  final String caption;
  final String uploaderId;
  final int likes;
  final int viewsCount;
  final int sharesCount;
  final int commentsCount;

  const VideoModel({
    required this.id,
    required this.videoUrl,
    required this.username,
    required this.caption,
    required this.uploaderId,
    required this.likes,
    required this.viewsCount,
    required this.sharesCount,
    required this.commentsCount,
  });

  // ⚡ GÜNCEL: Sıfır hata toleranslı ve tam tip güvenlikli köprü ⚡
  factory VideoModel.fromMap(Map<String, dynamic> map, String docId) {
    final uploader = map['uploaderId'] as String?;

    return VideoModel(
      id: docId,
      videoUrl: map['videoUrl'] as String? ?? '',
      username:
          map['username'] as String? ??
          (uploader != null ? '@$uploader' : '@cyber_user'),
      caption: map['description'] as String? ?? 'Hexa Akışı...',
      // ⚡ ONARILAN KISIM: Kopyala-yapıştır hatası giderildi, güvenli siber kimlik varsayılanı eklendi!
      uploaderId: uploader ?? 'system_admin',
      likes: map['likesCount'] as int? ?? 0,
      viewsCount: map['viewsCount'] as int? ?? 0,
      sharesCount: map['sharesCount'] as int? ?? 0,
      commentsCount: map['commentsCount'] as int? ?? 0,
    );
  }
}

class StickerModel {
  final String id;
  final String emoji;
  final String name;
  final int cost;

  const StickerModel({
    required this.id,
    required this.emoji,
    required this.name,
    required this.cost,
  });
}
