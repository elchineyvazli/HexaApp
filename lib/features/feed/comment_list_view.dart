import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommentListView extends StatelessWidget {
  const CommentListView({required this.videoId, super.key});

  final String videoId;

  static const Color _accentPurple = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _CommentLoadingView();
        }

        if (snapshot.hasError) {
          return const _CommentMessageView(
            icon: Icons.cloud_off_outlined,
            title: 'Yorumlar yüklenemedi',
            message: 'Bağlantını kontrol edip tekrar dene.',
          );
        }

        final documents =
            snapshot.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        if (documents.isEmpty) {
          return const _CommentMessageView(
            icon: Icons.mode_comment_outlined,
            title: 'Henüz yorum yok',
            message: 'İlk yorumu sen paylaş.',
          );
        }

        return ListView.separated(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 24),
          itemCount: documents.length,
          separatorBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(left: 49),
              child: Divider(
                height: 19,
                thickness: 1,
                color: Colors.white.withValues(alpha: 0.055),
              ),
            );
          },
          itemBuilder: (context, index) {
            final data = documents[index].data();

            return _CommentTile(
              username: _readUsername(data),
              avatarUrl: _readString(data['avatarUrl']),
              text: _readString(data['text']),
              sticker: _readString(data['sticker']),
              timeLabel: _formatTimestamp(data['createdAt']),
              likesCount: _readLikesCount(data),
              isLiked: data['isLiked'] == true,
            );
          },
        );
      },
    );
  }

  String _readUsername(Map<String, dynamic> data) {
    final username = _readString(data['username']);

    if (username.isNotEmpty) {
      return username;
    }

    final displayName = _readString(data['displayName']);

    if (displayName.isNotEmpty) {
      return displayName;
    }

    return '@anonim';
  }

  String _readString(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  int _readLikesCount(Map<String, dynamic> data) {
    final possibleValues = <dynamic>[
      data['likesCount'],
      data['likeCount'],
      data['likes'],
    ];

    for (final value in possibleValues) {
      if (value is int) {
        return value.clamp(0, 1 << 31);
      }

      if (value is num) {
        return value.toInt().clamp(0, 1 << 31);
      }

      if (value is List) {
        return value.length;
      }

      if (value is Map) {
        return value.length;
      }

      if (value is String) {
        final parsed = int.tryParse(value);

        if (parsed != null) {
          return parsed.clamp(0, 1 << 31);
        }
      }
    }

    return 0;
  }

  String _formatTimestamp(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is int) {
      date = DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (date == null) {
      return '';
    }

    final difference = DateTime.now().difference(date);

    if (difference.isNegative || difference.inSeconds < 45) {
      return 'şimdi';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} sa';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} g';
    }

    if (difference.inDays < 30) {
      return '${difference.inDays ~/ 7} hf';
    }

    if (difference.inDays < 365) {
      return '${difference.inDays ~/ 30} ay';
    }

    return '${difference.inDays ~/ 365} yıl';
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.username,
    required this.avatarUrl,
    required this.text,
    required this.sticker,
    required this.timeLabel,
    required this.likesCount,
    required this.isLiked,
  });

  final String username;
  final String avatarUrl;
  final String text;
  final String sticker;
  final String timeLabel;

  final int likesCount;
  final bool isLiked;

  bool get _hasText => text.isNotEmpty;
  bool get _hasSticker => sticker.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$username tarafından yapılan yorum',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _CommentAvatar(avatarUrl: avatarUrl),
          const SizedBox(width: 11),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xDFFFFFFF),
                            fontSize: 12,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.08,
                          ),
                        ),
                      ),
                      if (timeLabel.isNotEmpty) ...[
                        const SizedBox(width: 7),
                        Text(
                          timeLabel,
                          style: const TextStyle(
                            color: Color(0x66FFFFFF),
                            fontSize: 11,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_hasText) ...[
                    const SizedBox(height: 5),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Color(0xEBFFFFFF),
                        fontSize: 14,
                        height: 1.38,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.12,
                      ),
                    ),
                  ],
                  if (_hasSticker) ...[
                    SizedBox(height: _hasText ? 8 : 6),
                    Text(
                      sticker,
                      style: const TextStyle(fontSize: 30, height: 1.15),
                    ),
                  ],
                  if (!_hasText && !_hasSticker)
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Text(
                        'Yorum içeriği bulunamadı.',
                        style: TextStyle(
                          color: Color(0x66FFFFFF),
                          fontSize: 13,
                          height: 1.35,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _CommentLikeIndicator(count: likesCount, isLiked: isLiked),
        ],
      ),
    );
  }
}

class _CommentAvatar extends StatelessWidget {
  const _CommentAvatar({required this.avatarUrl});

  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
      ),
      child: ClipOval(
        child: ColoredBox(
          color: const Color(0xFF202027),
          child: avatarUrl.isEmpty
              ? const _AvatarFallback()
              : Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stackTrace) {
                    return const _AvatarFallback();
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return const _AvatarFallback();
                  },
                ),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.person_rounded, color: Color(0x99FFFFFF), size: 20),
    );
  }
}

class _CommentLikeIndicator extends StatelessWidget {
  const _CommentLikeIndicator({required this.count, required this.isLiked});

  final int count;
  final bool isLiked;

  @override
  Widget build(BuildContext context) {
    final color = isLiked ? const Color(0xFF8B5CF6) : const Color(0x70FFFFFF);

    return Semantics(
      label: '$count beğeni',
      child: SizedBox(
        width: 38,
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: color,
                size: 18,
              ),
              const SizedBox(height: 4),
              Text(
                _compactCount(count),
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _compactCount(int value) {
    if (value >= 1000000000) {
      return _formatCompact(value / 1000000000, 'B');
    }

    if (value >= 1000000) {
      return _formatCompact(value / 1000000, 'M');
    }

    if (value >= 1000) {
      return _formatCompact(value / 1000, 'K');
    }

    return value.toString();
  }

  String _formatCompact(double value, String suffix) {
    final formatted = value >= 10
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);

    final cleaned = formatted.endsWith('.0')
        ? formatted.substring(0, formatted.length - 2)
        : formatted;

    return '$cleaned$suffix';
  }
}

class _CommentLoadingView extends StatelessWidget {
  const _CommentLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF8B5CF6),
        ),
      ),
    );
  }
}

class _CommentMessageView extends StatelessWidget {
  const _CommentMessageView({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: const Color(0x66FFFFFF), size: 30),
            const SizedBox(height: 13),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xDFFFFFFF),
                fontSize: 15,
                height: 1.25,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0x70FFFFFF),
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
