import 'dart:async';

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

const Color _appBackground = Color(0xFF050507);
const Color _navigationSurface = Color(0xFF0B0B0F);
const Color _accentPurple = Color(0xFF8B5CF6);

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() {
    return _MainScaffoldState();
  }
}

class _MainScaffoldState extends ConsumerState<MainScaffold>
    with WidgetsBindingObserver {
  static const int _uploadTabIndex = 2;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    Future<void>.microtask(() async {
      if (!mounted) {
        return;
      }

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

        if (!context.mounted) {
          return;
        }

        await context.push('/upload');

        if (!mounted) {
          return;
        }

        await musicController.setMediaSoundActive(
          ref.read(currentTabIndexProvider) == 0,
        );

        return;
      }

      ref.read(currentTabIndexProvider.notifier).state = index;
    }

    return Scaffold(
      backgroundColor: _appBackground,
      body: ColoredBox(
        color: _appBackground,
        child: IndexedStack(index: currentIndex, children: pages),
      ),
      bottomNavigationBar: _HexaBottomBar(
        currentIndex: currentIndex,
        onDestinationSelected: (index) {
          unawaited(selectDestination(index));
        },
      ),
    );
  }
}

class _HexaBottomBar extends StatelessWidget {
  const _HexaBottomBar({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _navigationSurface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 3),
        child: SizedBox(
          height: 62,
          child: Row(
            children: List<Widget>.generate(5, (index) {
              return Expanded(
                child: index == 2
                    ? _UploadDestinationButton(
                        onPressed: () {
                          onDestinationSelected(index);
                        },
                      )
                    : _NavItem(
                        icon: _iconForIndex(index, currentIndex == index),
                        label: _labelForIndex(index),
                        isSelected: currentIndex == index,
                        onPressed: () {
                          onDestinationSelected(index);
                        },
                      ),
              );
            }, growable: false),
          ),
        ),
      ),
    );
  }

  IconData _iconForIndex(int index, bool selected) {
    switch (index) {
      case 0:
        return selected ? Icons.home_rounded : Icons.home_outlined;

      case 1:
        return selected ? Icons.explore_rounded : Icons.explore_outlined;

      case 3:
        return selected
            ? Icons.notifications_rounded
            : Icons.notifications_none_rounded;

      case 4:
        return selected ? Icons.person_rounded : Icons.person_outline_rounded;

      default:
        return Icons.circle_outlined;
    }
  }

  String _labelForIndex(int index) {
    switch (index) {
      case 0:
        return 'Ana Sayfa';

      case 1:
        return 'Keşfet';

      case 2:
        return 'Video yükle';

      case 3:
        return 'Bildirimler';

      case 4:
        return 'Profil';

      default:
        return '';
    }
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  State<_NavItem> createState() {
    return _NavItemState();
  }
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    final iconColor = widget.isSelected
        ? _accentPurple
        : Colors.white.withOpacity(0.58);

    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: widget.label,
      child: Tooltip(
        message: widget.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            _setPressed(true);
          },
          onTapCancel: () {
            _setPressed(false);
          },
          onTapUp: (_) {
            _setPressed(false);
            widget.onPressed();
          },
          child: AnimatedScale(
            scale: _pressed ? 0.88 : 1,
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 130),
            curve: Curves.easeOutCubic,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedScale(
                  scale: widget.isSelected ? 1.05 : 1,
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: Icon(widget.icon, color: iconColor, size: 24),
                ),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: widget.isSelected ? 4 : 0,
                  height: widget.isSelected ? 4 : 0,
                  decoration: const BoxDecoration(
                    color: _accentPurple,
                    shape: BoxShape.circle,
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

class _UploadDestinationButton extends StatefulWidget {
  const _UploadDestinationButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_UploadDestinationButton> createState() {
    return _UploadDestinationButtonState();
  }
}

class _UploadDestinationButtonState extends State<_UploadDestinationButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    return Semantics(
      button: true,
      label: 'Video yükle',
      child: Tooltip(
        message: 'Video yükle',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            _setPressed(true);
          },
          onTapCancel: () {
            _setPressed(false);
          },
          onTapUp: (_) {
            _setPressed(false);
            widget.onPressed();
          },
          child: Center(
            child: AnimatedScale(
              scale: _pressed ? 0.90 : 1,
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 130),
              curve: Curves.easeOutCubic,
              child: Container(
                width: 46,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _accentPurple,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
