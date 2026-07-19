import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/hexa_theme.dart';
import 'feed_models.dart';
import 'feed_repository.dart';
import 'video_item.dart';
import 'widgets/feed_search_bar.dart';
import 'widgets/feed_state_views.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({this.isTabActive = true, super.key});

  final bool isTabActive;

  @override
  ConsumerState<FeedScreen> createState() {
    return _FeedScreenState();
  }
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  static const Color _feedBackground = Color(0xFF050507);

  late final PageController _pageController;

  int _currentPage = 0;
  int _dismissInteractionToken = 0;

  bool _interactionOpen = false;
  bool _pageCorrectionScheduled = false;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant FeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isTabActive && !widget.isTabActive && _interactionOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _dismissInteraction();
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _setInteractionOpen(bool value) {
    if (!mounted || _interactionOpen == value) {
      return;
    }

    if (value) {
      FocusManager.instance.primaryFocus?.unfocus();
      HapticFeedback.lightImpact();
    }

    setState(() {
      _interactionOpen = value;
    });
  }

  void _dismissInteraction() {
    if (!_interactionOpen || !mounted) {
      return;
    }

    setState(() {
      _interactionOpen = false;
      _dismissInteractionToken++;
    });
  }

  void _keepPageInRange(int itemCount) {
    if (itemCount == 0 ||
        _currentPage < itemCount ||
        _pageCorrectionScheduled) {
      return;
    }

    _pageCorrectionScheduled = true;

    final targetPage = itemCount - 1;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageCorrectionScheduled = false;

      if (!mounted) {
        return;
      }

      setState(() {
        _currentPage = targetPage;
        _interactionOpen = false;
        _dismissInteractionToken++;
      });

      if (_pageController.hasClients) {
        _pageController.jumpToPage(targetPage);
      }
    });
  }

  void _handlePageChanged(int index, List<VideoModel> videos) {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _currentPage = index;
      _interactionOpen = false;
      _dismissInteractionToken++;
    });

    if (widget.isTabActive) {
      HapticFeedback.selectionClick();
    }

    if (index >= videos.length - 3) {
      unawaited(ref.read(feedControllerProvider.notifier).loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedControllerProvider);
    final videos = feedState.videos;

    _keepPageInRange(videos.length);

    ref.listen<FeedFailure?>(
      feedControllerProvider.select((state) => state.error),
      (previous, next) {
        if (next == null ||
            !mounted ||
            !ref.read(feedControllerProvider).hasContent) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.message),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xF216161B),
              elevation: 0,
              margin: const EdgeInsets.all(HexaSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              action: SnackBarAction(
                label: 'Dene',
                textColor: const Color(0xFF8B5CF6),
                onPressed: () {
                  unawaited(
                    ref.read(feedControllerProvider.notifier).loadMore(),
                  );
                },
              ),
            ),
          );
      },
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _feedBackground,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: PopScope<Object?>(
        canPop: !_interactionOpen,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _dismissInteraction();
          }
        },
        child: ColoredBox(
          color: _feedBackground,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _buildContent(state: feedState, videos: videos),

              if (videos.isNotEmpty) ...[
                const _FeedTopScrim(),
                FeedSearchBar(
                  dismissToken: _dismissInteractionToken,
                  onFocusChanged: _setInteractionOpen,
                ),
              ],

              if (feedState.isLoadingMore &&
                  videos.isNotEmpty &&
                  !_interactionOpen)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.paddingOf(context).bottom + HexaSpacing.sm,
                  child: const IgnorePointer(
                    child: Center(child: FeedLoadingMorePill()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required FeedState state,
    required List<VideoModel> videos,
  }) {
    if (state.isInitialLoading && videos.isEmpty) {
      return const FeedLoadingView();
    }

    if (state.error != null && videos.isEmpty) {
      return FeedMessageView(
        icon: Icons.cloud_off_rounded,
        title: 'Akışa bağlanamadık',
        message: state.error!.message,
        buttonLabel: 'Tekrar dene',
        onPressed: () {
          unawaited(ref.read(feedControllerProvider.notifier).loadInitial());
        },
      );
    }

    if (videos.isEmpty) {
      return FeedMessageView(
        icon: Icons.hexagon_outlined,
        title: 'Akış henüz sessiz',
        message: 'İlk içeriği paylaşarak Hexa’yı başlat.',
        buttonLabel: 'Video seç',
        onPressed: () {
          context.push('/upload');
        },
      );
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      physics: _interactionOpen
          ? const NeverScrollableScrollPhysics()
          : const PageScrollPhysics(parent: ClampingScrollPhysics()),
      pageSnapping: true,
      allowImplicitScrolling: true,
      itemCount: videos.length,
      onPageChanged: (index) {
        _handlePageChanged(index, videos);
      },
      itemBuilder: (context, index) {
        final video = videos[index];
        final distance = (index - _currentPage).abs();

        return RepaintBoundary(
          key: ValueKey<String>(video.id),
          child: VideoItem(
            video: video,
            isActive: widget.isTabActive && index == _currentPage,
            shouldPreload: distance <= 1,
            dismissInteractionToken: _dismissInteractionToken,
            onInteractionStateChanged: _setInteractionOpen,
          ),
        );
      },
    );
  }
}

class _FeedTopScrim extends StatelessWidget {
  const _FeedTopScrim();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 128,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xA6050507),
                Color(0x4D050507),
                Color(0x00050507),
              ],
              stops: <double>[0, 0.48, 1],
            ),
          ),
        ),
      ),
    );
  }
}
