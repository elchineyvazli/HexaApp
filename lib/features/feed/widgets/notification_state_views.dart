import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

class NotificationsHeader extends StatelessWidget {
  const NotificationsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HexaSpacing.md,
        HexaSpacing.md,
        HexaSpacing.md,
        HexaSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: HexaColors.signalSoft,
              borderRadius: BorderRadius.circular(HexaRadius.md),
              border: Border.all(color: HexaColors.border),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.notifications_rounded,
              color: HexaColors.signalStrong,
              size: 25,
            ),
          ),
          const SizedBox(width: HexaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bildirimler',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Topluluğundaki yeni hareketler',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: HexaColors.inkMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: HexaColors.lavenderSoft,
              borderRadius: BorderRadius.circular(HexaRadius.pill),
              border: Border.all(color: HexaColors.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite_rounded,
                  size: 14,
                  color: HexaColors.signal,
                ),
                SizedBox(width: 5),
                Text(
                  'HEXA',
                  style: TextStyle(
                    color: HexaColors.signalStrong,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsLoadingView extends StatelessWidget {
  const NotificationsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class NotificationsEmptyView extends StatelessWidget {
  const NotificationsEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(HexaSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 94,
              height: 94,
              decoration: const BoxDecoration(
                color: HexaColors.signalSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 43,
                color: HexaColors.signalStrong,
              ),
            ),
            const SizedBox(height: HexaSpacing.lg),
            Text(
              'Henüz bildirimin yok',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: HexaSpacing.xs),
            Text(
              'Signal, yorum ve takip hareketleri burada görünecek.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: HexaColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationsErrorView extends StatelessWidget {
  const NotificationsErrorView({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(HexaSpacing.lg),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(HexaSpacing.lg),
          decoration: BoxDecoration(
            color: HexaColors.surface,
            borderRadius: BorderRadius.circular(HexaRadius.lg),
            border: Border.all(color: HexaColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF1F0),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.notifications_off_outlined,
                  size: 35,
                  color: HexaColors.error,
                ),
              ),
              const SizedBox(height: HexaSpacing.md),
              Text(
                'Bildirimler yüklenemedi',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: HexaSpacing.xs),
              Text(
                'Bağlantını kontrol edip biraz sonra yeniden dene.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: HexaColors.inkMuted),
              ),
              const SizedBox(height: HexaSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(HexaSpacing.sm),
                decoration: BoxDecoration(
                  color: HexaColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(HexaRadius.md),
                  border: Border.all(color: HexaColors.border),
                ),
                child: Text(
                  message,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
