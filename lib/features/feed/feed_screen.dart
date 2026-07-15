import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'feed_models.dart';
import 'feed_repository.dart';
import 'video_item.dart';
import 'widgets/feed_state_views.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key, this.isTabActive = true});

  final bool isTabActive;

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  int _dismissInteractionToken = 0;
  bool _interactionOpen = false;

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

  void _resetToFirstVideo() {
    if (_currentPage != 0) {
      setState(() => _currentPage = 0);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    });
  }

  void _keepPageInRange(int itemCount) {
    if (itemCount == 0 || _currentPage < itemCount) {
      return;
    }

    final target = itemCount - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _currentPage = target);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(target);
      }
    });
  }

  void _setInteractionOpen(bool value) {
    if (!mounted || _interactionOpen == value) {
      return;
    }
    setState(() => _interactionOpen = value);
  }

  void _dismissInteraction() {
    if (!_interactionOpen) {
      return;
    }
    setState(() => _dismissInteractionToken++);
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedControllerProvider);
    final videos = ref.watch(filteredFeedVideosProvider);
    final hasSearch = ref.watch(searchQueryProvider).trim().isNotEmpty;

    _keepPageInRange(videos.length);

    ref.listen<Object?>(feedControllerProvider.select((state) => state.error), (
      previous,
      next,
    ) {
      if (next == null || !mounted) {
        return;
      }

      final currentState = ref.read(feedControllerProvider);
      if (!currentState.hasContent) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Yeni videolar yüklenemedi.'),
            action: SnackBarAction(
              label: 'Dene',
              onPressed: () {
                ref.read(feedControllerProvider.notifier).loadMore();
              },
            ),
          ),
        );
    });

    return PopScope(
      canPop: !_interactionOpen,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _dismissInteraction();
        }
      },
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildContent(
              context: context,
              state: feedState,
              videos: videos,
              hasSearch: hasSearch,
            ),
            if (feedState.isLoadingMore && videos.isNotEmpty)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 14,
                child: Center(child: FeedLoadingMorePill()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required FeedState state,
    required List<VideoModel> videos,
    required bool hasSearch,
  }) {
    if (state.isInitialLoading && videos.isEmpty) {
      return const FeedLoadingView();
    }

    if (state.error != null && videos.isEmpty) {
      return FeedMessageView(
        icon: Icons.cloud_off_rounded,
        title: 'Akışa bağlanamadık',
        message: 'Bağlantını kontrol edip yeniden deneyebilirsin.',
        buttonLabel: 'Tekrar dene',
        onPressed: () {
          ref.read(feedControllerProvider.notifier).loadInitial();
        },
      );
    }

    if (videos.isEmpty) {
      return FeedMessageView(
        icon: hasSearch ? Icons.search_off_rounded : Icons.hexagon_outlined,
        title: hasSearch ? 'Eşleşen video yok' : 'Akış henüz boş',
        message: hasSearch
            ? 'Arama ifadesini sadeleştir veya aramayı temizle.'
            : 'İlk videoyu paylaşarak akışı başlatabilirsin.',
        buttonLabel: hasSearch ? 'Aramayı temizle' : 'Video yükle',
        onPressed: () {
          if (hasSearch) {
            ref.read(searchQueryProvider.notifier).state = '';
            _resetToFirstVideo();
          } else {
            context.push('/upload');
          }
        },
      );
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      physics: _interactionOpen
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      pageSnapping: true,
      allowImplicitScrolling: true,
      itemCount: videos.length,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
          _interactionOpen = false;
        });
        HapticFeedback.selectionClick();

        if (index >= videos.length - 3) {
          ref.read(feedControllerProvider.notifier).loadMore();
        }
      },
      itemBuilder: (context, index) {
        final distanceFromCurrent = (index - _currentPage).abs();
        return RepaintBoundary(
          key: ValueKey<String>(videos[index].id),
          child: SizedBox.expand(
            child: VideoItem(
              video: videos[index],
              isActive: widget.isTabActive && index == _currentPage,
              shouldPreload: distanceFromCurrent <= 1,
              dismissInteractionToken: _dismissInteractionToken,
              onInteractionStateChanged: _setInteractionOpen,
            ),
          ),
        );
      },
    );
  }
}
