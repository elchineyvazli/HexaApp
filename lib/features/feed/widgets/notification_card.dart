import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

import '../notification_model.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({required this.item, super.key});

  final NotificationModel item;

  @override
  Widget build(BuildContext context) {
    final visual = _notificationVisual(item.type);

    return Semantics(
      label: '${item.senderName}: ${item.message}',
      child: AnimatedContainer(
        duration: HexaMotion.fast,
        curve: Curves.easeOutCubic,
        color: item.isRead
            ? Colors.transparent
            : HexaColors.purple.withOpacity(0.055),
        padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _NotificationAvatar(
              avatarUrl: item.senderAvatar,
              senderName: item.senderName,
              icon: visual.icon,
              accentColor: visual.color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NotificationContent(
                item: item,
                accentColor: visual.color,
                typeLabel: visual.label,
              ),
            ),
            if (!item.isRead) ...<Widget>[
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(top: 7),
                child: _UnreadIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationAvatar extends StatelessWidget {
  const _NotificationAvatar({
    required this.avatarUrl,
    required this.senderName,
    required this.icon,
    required this.accentColor,
  });

  final String avatarUrl;
  final String senderName;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final normalizedAvatarUrl = avatarUrl.trim();

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: ClipOval(
            child: ColoredBox(
              color: HexaColors.surfaceMutedDark,
              child: normalizedAvatarUrl.isEmpty
                  ? _AvatarFallback(senderName: senderName)
                  : Image.network(
                      normalizedAvatarUrl,
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (context, error, stackTrace) {
                        return _AvatarFallback(senderName: senderName);
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }

                        return _AvatarFallback(senderName: senderName);
                      },
                    ),
            ),
          ),
        ),
        Positioned(
          right: -3,
          bottom: -2,
          child: Container(
            width: 19,
            height: 19,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HexaColors.surfaceStrongDark,
              shape: BoxShape.circle,
              border: Border.all(color: HexaColors.backgroundDark, width: 2),
            ),
            child: Icon(icon, color: accentColor, size: 11),
          ),
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.senderName});

  final String senderName;

  @override
  Widget build(BuildContext context) {
    final normalizedName = senderName.trim();

    final letter = normalizedName.isEmpty
        ? 'H'
        : normalizedName.substring(0, 1).toUpperCase();

    return Center(
      child: Text(
        letter,
        style: const TextStyle(
          color: Color(0xDFFFFFFF),
          fontSize: 17,
          height: 1,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
        ),
      ),
    );
  }
}

class _NotificationContent extends StatelessWidget {
  const _NotificationContent({
    required this.item,
    required this.accentColor,
    required this.typeLabel,
  });

  final NotificationModel item;
  final Color accentColor;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    final normalizedName = item.senderName.trim();

    final senderName = normalizedName.isEmpty
        ? 'Hexa kullanıcısı'
        : normalizedName;

    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text.rich(
            TextSpan(
              style: const TextStyle(
                color: Color(0xCFFFFFFF),
                fontSize: 14,
                height: 1.38,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.14,
              ),
              children: <InlineSpan>[
                TextSpan(
                  text: '$senderName ',
                  style: const TextStyle(
                    color: Color(0xF2FFFFFF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: item.message),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: <Widget>[
              Text(
                typeLabel,
                style: TextStyle(
                  color: accentColor.withOpacity(0.88),
                  fontSize: 11,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.04,
                ),
              ),
              Container(
                width: 3,
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 7),
                decoration: const BoxDecoration(
                  color: Color(0x4DFFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
              Flexible(
                child: Text(
                  _formatNotificationTimestamp(item.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0x66FFFFFF),
                    fontSize: 11,
                    height: 1,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.04,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnreadIndicator extends StatelessWidget {
  const _UnreadIndicator();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Okunmamış bildirim',
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: HexaColors.purple,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

typedef _NotificationVisual = ({Color color, IconData icon, String label});

_NotificationVisual _notificationVisual(NotificationType type) {
  switch (type) {
    case NotificationType.like:
      return (
        color: HexaColors.purple,
        icon: Icons.favorite_rounded,
        label: 'Beğeni',
      );

    case NotificationType.comment:
      return (
        color: HexaColors.cyan,
        icon: Icons.mode_comment_rounded,
        label: 'Yorum',
      );

    case NotificationType.follow:
      return (
        color: HexaColors.purpleSoft,
        icon: Icons.person_add_rounded,
        label: 'Takip',
      );

    case NotificationType.system:
      return (
        color: HexaColors.inkMutedOnDark,
        icon: Icons.hexagon_outlined,
        label: 'HEXA',
      );
  }
}

String _formatNotificationTimestamp(Timestamp? timestamp) {
  if (timestamp == null) {
    return 'Şimdi';
  }

  final date = timestamp.toDate();
  final difference = DateTime.now().difference(date);

  if (difference.isNegative || difference.inSeconds < 30) {
    return 'Şimdi';
  }

  if (difference.inMinutes < 1) {
    return '${difference.inSeconds} sn önce';
  }

  if (difference.inHours < 1) {
    return '${difference.inMinutes} dk önce';
  }

  if (difference.inDays < 1) {
    return '${difference.inHours} sa önce';
  }

  if (difference.inDays < 7) {
    return '${difference.inDays} gün önce';
  }

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');

  return '$day.$month.${date.year}';
}
