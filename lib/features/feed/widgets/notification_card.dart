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
        curve: HexaMotion.enter,
        padding: const EdgeInsets.all(HexaSpacing.md),
        decoration: BoxDecoration(
          color: item.isRead ? HexaColors.surface : visual.background,
          borderRadius: BorderRadius.circular(HexaRadius.lg),
          border: Border.all(
            color: item.isRead ? HexaColors.border : visual.border,
            width: item.isRead ? 1 : 1.3,
          ),
          boxShadow: item.isRead ? const [] : HexaShadows.soft,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NotificationAvatar(
              avatarUrl: item.senderAvatar,
              senderName: item.senderName,
              icon: visual.icon,
              color: visual.color,
              background: visual.iconBackground,
            ),
            const SizedBox(width: HexaSpacing.sm),
            Expanded(
              child: _NotificationContent(
                item: item,
                accentColor: visual.color,
                typeLabel: visual.label,
              ),
            ),
            if (!item.isRead) ...[
              const SizedBox(width: HexaSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: visual.color,
                    shape: BoxShape.circle,
                  ),
                ),
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
    required this.color,
    required this.background,
  });

  final String avatarUrl;
  final String senderName;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: HexaColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: HexaColors.border),
          ),
          child: ClipOval(
            child: avatarUrl.trim().isEmpty
                ? _AvatarFallback(senderName: senderName)
                : Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _AvatarFallback(senderName: senderName);
                    },
                  ),
          ),
        ),
        Positioned(
          right: -3,
          bottom: -3,
          child: Container(
            width: 23,
            height: 23,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              border: Border.all(color: HexaColors.surface, width: 2),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 13),
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
    final cleanName = senderName.trim();

    final letter = cleanName.isEmpty
        ? 'H'
        : cleanName.substring(0, 1).toUpperCase();

    return DecoratedBox(
      decoration: const BoxDecoration(color: HexaColors.surfaceMuted),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: HexaColors.signalStrong,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
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
    final baseStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: HexaColors.inkMuted, height: 1.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: baseStyle,
            children: [
              TextSpan(
                text: item.senderName.trim().isEmpty
                    ? 'Hexa kullanıcısı '
                    : '${item.senderName.trim()} ',
                style: const TextStyle(
                  color: HexaColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(text: item.message),
            ],
          ),
        ),
        const SizedBox(height: HexaSpacing.xs),
        Wrap(
          spacing: HexaSpacing.xs,
          runSpacing: HexaSpacing.xxs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(HexaRadius.pill),
              ),
              child: Text(
                typeLabel,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              _formatNotificationTimestamp(item.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HexaColors.inkSoft,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

typedef _NotificationVisual = ({
  Color color,
  Color background,
  Color iconBackground,
  Color border,
  IconData icon,
  String label,
});

_NotificationVisual _notificationVisual(NotificationType type) {
  switch (type) {
    case NotificationType.like:
      return (
        color: HexaColors.signalStrong,
        background: HexaColors.surfaceWarm,
        iconBackground: HexaColors.signalSoft,
        border: HexaColors.borderStrong,
        icon: Icons.favorite_rounded,
        label: 'Signal',
      );

    case NotificationType.comment:
      return (
        color: HexaColors.mauve,
        background: HexaColors.lavenderSoft,
        iconBackground: HexaColors.lavender,
        border: HexaColors.borderStrong,
        icon: Icons.chat_bubble_rounded,
        label: 'Yorum',
      );

    case NotificationType.follow:
      return (
        color: HexaColors.success,
        background: HexaColors.mintSoft,
        iconBackground: HexaColors.mint,
        border: HexaColors.mint,
        icon: Icons.person_add_rounded,
        label: 'Takip',
      );

    case NotificationType.system:
      return (
        color: HexaColors.warning,
        background: const Color(0xFFFFF7EE),
        iconBackground: const Color(0xFFFFE5C7),
        border: const Color(0xFFF2D0A8),
        icon: Icons.auto_awesome_rounded,
        label: 'Hexa',
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
