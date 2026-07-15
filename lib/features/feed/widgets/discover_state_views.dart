import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

class DiscoverHeader extends StatelessWidget {
  const DiscoverHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HexaSpacing.md,
        HexaSpacing.md,
        HexaSpacing.md,
        0,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: HexaColors.lavenderSoft,
              borderRadius: BorderRadius.circular(HexaRadius.md),
              border: Border.all(color: HexaColors.border),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.explore_rounded,
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
                  'Keşfet',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Topluluğun değer verdiği videolar',
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
              color: HexaColors.mintSoft,
              borderRadius: BorderRadius.circular(HexaRadius.pill),
              border: Border.all(color: HexaColors.mint),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: HexaColors.success,
                  size: 15,
                ),
                SizedBox(width: 5),
                Text(
                  'ÖNE ÇIKAN',
                  style: TextStyle(
                    color: HexaColors.success,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.65,
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

class DiscoverLoadingView extends StatelessWidget {
  const DiscoverLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class DiscoverErrorView extends StatelessWidget {
  const DiscoverErrorView({required this.message, super.key});

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
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: HexaColors.error,
              ),
              const SizedBox(height: HexaSpacing.md),
              Text(
                'Keşfet yüklenemedi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: HexaSpacing.xs),
              Text(
                message,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DiscoverEmptyView extends StatelessWidget {
  const DiscoverEmptyView({
    required this.hasSearch,
    required this.onClearSearch,
    super.key,
  });

  final bool hasSearch;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(HexaSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: HexaColors.signalSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                hasSearch ? Icons.search_off_rounded : Icons.explore_outlined,
                size: 42,
                color: HexaColors.signalStrong,
              ),
            ),
            const SizedBox(height: HexaSpacing.lg),
            Text(
              hasSearch ? 'Eşleşen video bulunamadı' : 'Keşfedilecek video yok',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: HexaSpacing.xs),
            Text(
              hasSearch
                  ? 'Başka bir kelime veya kullanıcı adı deneyebilirsin.'
                  : 'Topluluk video paylaştıkça öne çıkan içerikler burada görünecek.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: HexaColors.inkMuted),
            ),
            if (hasSearch) ...[
              const SizedBox(height: HexaSpacing.lg),
              OutlinedButton.icon(
                onPressed: onClearSearch,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Aramayı temizle'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
