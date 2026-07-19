import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

class DiscoverHeader extends StatelessWidget {
  const DiscoverHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Keşfet',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: HexaColors.inkOnDark,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.75,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Topluluğun öne çıkardığı videolar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: HexaColors.inkMutedOnDark,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.10,
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
    return Center(
      child: Semantics(
        label: 'Keşfet videoları yükleniyor',
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.1,
                color: HexaColors.purple,
                backgroundColor: Color(0x1AFFFFFF),
                strokeCap: StrokeCap.round,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Videolar yükleniyor',
              style: TextStyle(
                color: Color(0x70FFFFFF),
                fontSize: 13,
                height: 1.2,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.08,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiscoverErrorView extends StatelessWidget {
  const DiscoverErrorView({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.cloud_off_outlined,
                size: 31,
                color: Colors.white.withOpacity(0.32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Keşfet yüklenemedi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xEFFFFFFF),
                  fontSize: 17,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.30,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0x70FFFFFF),
                  fontSize: 13,
                  height: 1.42,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.08,
                ),
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
    final title = hasSearch ? 'Sonuç bulunamadı' : 'Henüz video yok';

    final message = hasSearch
        ? 'Başka bir kelime, konu veya kullanıcı adı deneyebilirsin.'
        : 'Yeni videolar paylaşıldığında burada görünmeye başlayacak.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.055),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: Icon(
                  hasSearch ? Icons.search_off_rounded : Icons.explore_outlined,
                  size: 27,
                  color: Colors.white.withOpacity(0.56),
                ),
              ),
              const SizedBox(height: 19),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xEFFFFFFF),
                  fontSize: 17,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.30,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0x70FFFFFF),
                  fontSize: 13,
                  height: 1.42,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.08,
                ),
              ),
              if (hasSearch) ...<Widget>[
                const SizedBox(height: 21),
                OutlinedButton.icon(
                  onPressed: onClearSearch,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white.withOpacity(0.88),
                    backgroundColor: Colors.white.withOpacity(0.055),
                    side: BorderSide(color: Colors.white.withOpacity(0.10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 11,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 17),
                  label: const Text(
                    'Aramayı temizle',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.08,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
