import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hexa/core/theme/hexa_theme.dart';
import 'package:hexa/features/feed/discover_screen.dart';
import 'package:hexa/features/feed/feed_screen.dart';
import 'package:hexa/features/feed/notifications_screen.dart';
import 'package:hexa/features/profile/profile_screen.dart';

final currentTabIndexProvider = StateProvider<int>((ref) => 0);

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  static const int _uploadTabIndex = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentTabIndexProvider);

    final pages = <Widget>[
      FeedScreen(isTabActive: currentIndex == 0),
      const DiscoverScreen(),
      const SizedBox.shrink(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    void selectDestination(int index) {
      if (index == _uploadTabIndex) {
        context.push('/upload');
        return;
      }

      ref.read(currentTabIndexProvider.notifier).state = index;
    }

    return Scaffold(
      backgroundColor: HexaColors.background,
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: HexaColors.surface,
          border: Border(top: BorderSide(color: HexaColors.border)),
          boxShadow: [
            BoxShadow(
              color: Color(0x120B141B),
              blurRadius: 24,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 72,
            selectedIndex: currentIndex,
            onDestinationSelected: selectDestination,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Ana Sayfa',
                tooltip: 'Ana Sayfa',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded),
                label: 'Keşfet',
                tooltip: 'Keşfet',
              ),
              NavigationDestination(
                icon: _UploadDestinationIcon(),
                selectedIcon: _UploadDestinationIcon(),
                label: 'Yükle',
                tooltip: 'Video Yükle',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_none_rounded),
                selectedIcon: Icon(Icons.notifications_rounded),
                label: 'Bildirimler',
                tooltip: 'Bildirimler',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profil',
                tooltip: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadDestinationIcon extends StatelessWidget {
  const _UploadDestinationIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: HexaColors.signal,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33D83A56),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
    );
  }
}
