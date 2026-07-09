// lib/features/feed/feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'feed_repository.dart';
import 'feed_models.dart';
import 'video_item.dart';
import 'widgets/feed_search_bar.dart'; // YENİ: Arama barımızı bağladık!

class FeedScreen extends ConsumerStatefulWidget {
  final bool isTabActive;

  const FeedScreen({super.key, this.isTabActive = true});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  int _currentPage = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videosAsyncValue = ref.watch(videosStreamProvider);

    return Container(
      color: const Color(0xFF0F172A),
      child: Stack(
        children: [
          // 1. KATMAN: Dikey Video Akışı (PageView)
          videosAsyncValue.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Akış Hatası: $error',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            data: (rawVideos) {
              if (rawVideos.isEmpty) {
                return const Center(
                  child: Text(
                    "Aradığın kriterlere uygun sinyal bulunamadı. 🛰️",
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                );
              }

              final List<VideoModel> videos = rawVideos.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final id = data['id'] ?? 'vid_$index';
                return VideoModel.fromMap(data, id);
              }).toList();

              return PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                pageSnapping: true,
                itemCount: videos.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return VideoItem(
                    video: videos[index],
                    isActive: (index == _currentPage) && widget.isTabActive,
                  );
                },
              );
            },
          ),

          // 2. KATMAN: Üstte Süzülen 3 Filtreli Arama Barı
          const FeedSearchBar(),
        ],
      ),
    );
  }
}