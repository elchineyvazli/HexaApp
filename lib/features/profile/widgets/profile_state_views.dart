import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

import 'profile_page_chrome.dart';

class ProfileLoadingView extends StatelessWidget {
  const ProfileLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProfileStateBackground(
      child: Center(child: _ProfileLoadingCard()),
    );
  }
}

class ProfileErrorView extends StatelessWidget {
  const ProfileErrorView({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _ProfileStateBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(HexaSpacing.lg),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(HexaSpacing.lg),
            decoration: BoxDecoration(
              color: const Color(0xFAFFFFFF),
              borderRadius: BorderRadius.circular(HexaRadius.lg),
              border: Border.all(color: profileOrangeBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x16EA580C),
                  blurRadius: 22,
                  spreadRadius: -5,
                  offset: Offset(0, 9),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _ProfileStateIcon(
                  icon: Icons.person_off_outlined,
                  iconColor: HexaColors.error,
                  backgroundColor: Color(0xFFFFF1F0),
                  borderColor: Color(0xFFF7C8C4),
                ),
                const SizedBox(height: HexaSpacing.lg),
                Text(
                  'Profil yüklenemedi',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: HexaColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: HexaSpacing.xs),
                Text(
                  'Bağlantını kontrol edip biraz sonra yeniden dene.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HexaColors.inkMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: HexaSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(HexaSpacing.sm),
                  decoration: BoxDecoration(
                    color: profileOrangeSoft,
                    borderRadius: BorderRadius.circular(HexaRadius.md),
                    border: Border.all(color: profileOrangeBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: profileOrangeStrong,
                        size: 19,
                      ),
                      const SizedBox(width: HexaSpacing.xs),
                      Expanded(
                        child: Text(
                          message,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: HexaColors.inkMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyProfileVideos extends StatelessWidget {
  const EmptyProfileVideos({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProfileEmptyState(
      icon: Icons.video_library_outlined,
      title: 'Henüz video yok',
      description: 'Bu profilde yayınlanan videolar burada görüntülenecek.',
    );
  }
}

class SavedVideosPlaceholder extends StatelessWidget {
  const SavedVideosPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProfileEmptyState(
      icon: Icons.bookmark_border_rounded,
      title: 'Kaydedilenler hazırlanıyor',
      description:
          'Değerli bulduğun videoları yakında burada saklayabileceksin.',
      badge: 'YAKINDA',
    );
  }
}

class _ProfileStateBackground extends StatelessWidget {
  const _ProfileStateBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: profilePageGradient),
        child: SafeArea(child: child),
      ),
    );
  }
}

class _ProfileLoadingCard extends StatelessWidget {
  const _ProfileLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      margin: const EdgeInsets.all(HexaSpacing.lg),
      padding: const EdgeInsets.all(HexaSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFAFFFFFF),
        borderRadius: BorderRadius.circular(HexaRadius.lg),
        border: Border.all(color: profileOrangeBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16EA580C),
            blurRadius: 22,
            spreadRadius: -5,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              color: profileOrangeStrong,
              strokeWidth: 3.5,
            ),
          ),
          const SizedBox(height: HexaSpacing.md),
          Text(
            'Profil hazırlanıyor',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: HexaColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: HexaSpacing.xs),
          Text(
            'Kullanıcı bilgileri yükleniyor.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: HexaColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _ProfileEmptyState extends StatelessWidget {
  const _ProfileEmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          HexaSpacing.lg,
          HexaSpacing.md,
          HexaSpacing.lg,
          110,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.fromLTRB(
            HexaSpacing.lg,
            HexaSpacing.xl,
            HexaSpacing.lg,
            HexaSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFAFFFFFF),
            borderRadius: BorderRadius.circular(HexaRadius.lg),
            border: Border.all(color: profileOrangeBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12EA580C),
                blurRadius: 20,
                spreadRadius: -5,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: profileOrangeSoft,
                    borderRadius: BorderRadius.circular(HexaRadius.pill),
                    border: Border.all(color: profileOrangeBorder),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: profileOrangeStrong,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: HexaSpacing.md),
              ],
              _ProfileStateIcon(
                icon: icon,
                iconColor: profileOrangeStrong,
                backgroundColor: profileOrangeSoft,
                borderColor: profileOrangeBorder,
              ),
              const SizedBox(height: HexaSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: HexaColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: HexaSpacing.xs),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: HexaColors.inkMuted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStateIcon extends StatelessWidget {
  const _ProfileStateIcon({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: HexaColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.4),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: iconColor, size: 35),
      ),
    );
  }
}
