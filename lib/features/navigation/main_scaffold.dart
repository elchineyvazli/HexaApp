// lib/features/navigation/main_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/feed/feed_screen.dart';
import '../../features/feed/upload_screen.dart';
import '../../features/feed/notifications_screen.dart';
import '../../features/profile/profile_screen.dart';

// YENİ PROVIDER: Aktif olan alt sekme indeksini global olarak yayınlar
final currentTabIndexProvider = StateProvider<int>((ref) => 0);

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  void _onTabTapped(int index) {
    // Riverpod üzerindeki aktif sekme numarasını anında değiştiriyoruz
    ref.read(currentTabIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    // Provider'dan o an hangi sekmede olduğumuzu dinliyoruz
    final currentIndex = ref.watch(currentTabIndexProvider);

    final List<Widget> pages = [
      const FeedScreen(),
      const NotificationsScreen(), // Yer tutucu yerine Bildirim ekranı
      const UploadScreen(),
      const _PlaceholderScreen(title: 'Mesajlar 💬'),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: _onTabTapped,
          backgroundColor: const Color(0xFF0F172A),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFFF5E00),
          unselectedItemColor: const Color(0xFF8E92B2),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 28),
              activeIcon: Icon(Icons.home, size: 28),
              label: 'Akış',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none_rounded, size: 28),
              activeIcon: Icon(Icons.notifications_rounded, size: 28),
              label: 'Bildirimler',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5E00), Color(0xFF9D4EDD)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 26),
              ),
              label: 'Yükle',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded, size: 26),
              activeIcon: Icon(Icons.chat_bubble_rounded, size: 26),
              label: 'Mesajlar',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded, size: 28),
              activeIcon: Icon(Icons.person_rounded, size: 28),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(color: Colors.white54, fontSize: 16),
        ),
      ),
    );
  }
}
