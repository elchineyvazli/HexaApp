import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

class NotificationsHeader extends StatelessWidget {
  const NotificationsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Bildirimler',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: HexaColors.inkOnDark,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.75,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hesabındaki son hareketler',
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

class NotificationsLoadingView extends StatelessWidget {
  const NotificationsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Bildirimler yükleniyor',
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
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Bildirimler yükleniyor',
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

class NotificationsEmptyView extends StatelessWidget {
  const NotificationsEmptyView({super.key});

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
                  Icons.notifications_none_rounded,
                  size: 27,
                  color: Colors.white.withOpacity(0.56),
                ),
              ),
              const SizedBox(height: 19),
              const Text(
                'Henüz bildirimin yok',
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
              const Text(
                'Beğeni, yorum ve takip hareketleri burada görünecek.',
                textAlign: TextAlign.center,
                style: TextStyle(
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

class NotificationsErrorView extends StatelessWidget {
  const NotificationsErrorView({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final semanticMessage = message.trim().isEmpty
        ? 'Bildirimler yüklenemedi'
        : 'Bildirimler yüklenemedi. $message';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
        child: Semantics(
          label: semanticMessage,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.notifications_off_outlined,
                  size: 31,
                  color: Colors.white.withOpacity(0.32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bildirimler yüklenemedi',
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
                const Text(
                  'Bağlantını kontrol edip biraz sonra yeniden dene.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
      ),
    );
  }
}
