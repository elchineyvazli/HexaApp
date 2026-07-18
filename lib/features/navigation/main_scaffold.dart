import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hexa/core/theme/hexa_theme.dart';
import 'package:hexa/features/feed/discover_screen.dart';
import 'package:hexa/features/feed/feed_screen.dart';
import 'package:hexa/features/feed/notifications_screen.dart';
import 'package:hexa/features/profile/profile_screen.dart';

import 'ambient_music_controller.dart';

final currentTabIndexProvider = StateProvider<int>((ref) => 0);

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const int _uploadTabIndex = 2;

  // ---- Animasyon kontrolcüleri ----
  late final AnimationController _bgGradientController;
  late final Animation<Alignment> _bgGradientAnimation;

  late final AnimationController _navIndicatorController;
  late final Animation<double> _navIndicatorAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // --- Arka plan gradyanı yavaş kaydırma (20 saniye) ---
    _bgGradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
    _bgGradientAnimation = AlignmentTween(
      begin: const Alignment(-0.2, -0.4),
      end: const Alignment(0.2, 0.4),
    ).animate(_bgGradientController);

    // --- Navigasyon çizgisi için basit bir animasyon ---
    _navIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _navIndicatorAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _navIndicatorController, curve: Curves.easeOut),
    );
    // İlk değeri 1 yap, direkt görünsün.
    _navIndicatorController.value = 1.0;

    Future<void>.microtask(() async {
      if (!mounted) return;
      final currentIndex = ref.read(currentTabIndexProvider);
      await ref
          .read(ambientMusicControllerProvider.notifier)
          .setMediaSoundActive(currentIndex == 0);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isActive = state == AppLifecycleState.resumed;
    unawaited(
      ref
          .read(ambientMusicControllerProvider.notifier)
          .setApplicationActive(isActive),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgGradientController.dispose();
    _navIndicatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentTabIndexProvider);

    ref.listen<int>(currentTabIndexProvider, (previous, next) {
      unawaited(
        ref
            .read(ambientMusicControllerProvider.notifier)
            .setMediaSoundActive(next == 0),
      );
      // Navigasyon çizgisi konum değiştirirken animasyonu sıfırlayıp tekrar oynat
      _navIndicatorController
        ..reset()
        ..forward();
    });

    final pages = <Widget>[
      FeedScreen(isTabActive: currentIndex == 0),
      const DiscoverScreen(),
      const SizedBox.shrink(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    Future<void> selectDestination(int index) async {
      final musicController = ref.read(ambientMusicControllerProvider.notifier);

      if (index == _uploadTabIndex) {
        await musicController.setMediaSoundActive(true);
        if (!context.mounted) return;
        await context.push('/upload');
        if (!mounted) return;
        await musicController.setMediaSoundActive(
          ref.read(currentTabIndexProvider) == 0,
        );
        return;
      }

      ref.read(currentTabIndexProvider.notifier).state = index;
    }

    return Scaffold(
      backgroundColor: HexaColors.background,
      body: AnimatedBuilder(
        animation: _bgGradientAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _bgGradientAnimation.value,
                end: const Alignment(1.2, 1.2),
                colors: HexaGradients.page.colors,
              ),
            ),
            child: child,
          );
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 480),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(currentIndex),
            child: IndexedStack(index: currentIndex, children: pages),
          ),
        ),
      ),
      bottomNavigationBar: _HexaBottomBar(
        currentIndex: currentIndex,
        navIndicatorAnimation: _navIndicatorAnimation,
        onDestinationSelected: (index) {
          unawaited(selectDestination(index));
        },
      ),
    );
  }
}

// ------------------- Özel Alt Navigasyon Barı -------------------
class _HexaBottomBar extends StatelessWidget {
  final int currentIndex;
  final Animation<double> navIndicatorAnimation;
  final ValueChanged<int> onDestinationSelected;

  const _HexaBottomBar({
    required this.currentIndex,
    required this.navIndicatorAnimation,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final double indicatorWidth = 40.0;
    final double totalWidth = MediaQuery.of(context).size.width;
    final double itemWidth = totalWidth / 5;
    final double indicatorOffset =
        (itemWidth * currentIndex) + (itemWidth - indicatorWidth) / 2;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFCFD), Color(0xFFFFF5F9)],
        ),
        border: Border(top: BorderSide(color: HexaColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x182F1713),
            blurRadius: 28,
            spreadRadius: -8,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            children: [
              // Seçili sekme çizgisi (parlak, kayan)
              AnimatedBuilder(
                animation: navIndicatorAnimation,
                builder: (context, _) {
                  return Positioned(
                    left: indicatorOffset,
                    top: 0,
                    child: Container(
                      width: indicatorWidth,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: HexaGradients.signal,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: HexaColors.signal.withOpacity(0.6),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Navigasyon ikonları
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (index) {
                  final isSelected = currentIndex == index;
                  return Expanded(
                    child: _NavItem(
                      icon: _iconForIndex(index, isSelected),
                      label: _labelForIndex(index),
                      isSelected: isSelected,
                      onTap: () => onDestinationSelected(index),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconForIndex(int index, bool selected) {
    switch (index) {
      case 0:
        return Icon(selected ? Icons.home_rounded : Icons.home_outlined);
      case 1:
        return Icon(selected ? Icons.explore_rounded : Icons.explore_outlined);
      case 2:
        return const _UploadDestinationIcon(); // özel yükleme butonu
      case 3:
        return Icon(
          selected
              ? Icons.notifications_rounded
              : Icons.notifications_none_rounded,
        );
      case 4:
        return Icon(
          selected ? Icons.person_rounded : Icons.person_outline_rounded,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _labelForIndex(int index) {
    switch (index) {
      case 0:
        return 'Ana Sayfa';
      case 1:
        return 'Keşfet';
      case 2:
        return 'Yükle';
      case 3:
        return 'Bildirimler';
      case 4:
        return 'Profil';
      default:
        return '';
    }
  }
}

class _NavItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          icon,
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ------------------- Yükleme Butonu (ışık halkalı) -------------------
class _UploadDestinationIcon extends StatefulWidget {
  const _UploadDestinationIcon();

  @override
  State<_UploadDestinationIcon> createState() => _UploadDestinationIconState();
}

class _UploadDestinationIconState extends State<_UploadDestinationIcon>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnim;

  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final scale = reduceMotion
        ? const AlwaysStoppedAnimation<double>(1.0)
        : _scaleAnim;

    return ScaleTransition(
      scale: scale,
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, child) {
          return CustomPaint(
            painter: _GlowRingPainter(
              glowOpacity: reduceMotion ? 0.0 : _glowAnim.value,
            ),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: HexaGradients.signal,
                borderRadius: BorderRadius.circular(HexaRadius.md),
                boxShadow: [
                  ...HexaShadows.signal,
                  if (!reduceMotion)
                    BoxShadow(
                      color: HexaColors.signal.withOpacity(
                        0.3 * _glowAnim.value,
                      ),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GlowRingPainter extends CustomPainter {
  final double glowOpacity;

  _GlowRingPainter({required this.glowOpacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (glowOpacity <= 0.0) return;

    final paint = Paint()
      ..color = HexaColors.signal.withOpacity(0.25 * glowOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 1.5 + (4 * glowOpacity);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowRingPainter oldDelegate) {
    return oldDelegate.glowOpacity != glowOpacity;
  }
}

// AnimatedBuilder yerine kendi widget'ımızı kullandık, 
// Flutter'da AnimatedBuilder aslında AnimatedWidget'tır.
// Yukarıda AnimatedBuilder diye geçen widget'ı düzeltelim: aslında `AnimatedBuilder` yok, `AnimatedWidget` kullanmamız lazım.
// Ama biz direkt `AnimatedBuilder` yazdık, Flutter'da `AnimatedBuilder` var. Doğru.