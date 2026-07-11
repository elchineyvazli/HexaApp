// lib/features/feed/feed_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

import 'feed_models.dart';
import 'feed_repository.dart';
import 'video_item.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({
    super.key,
    this.isTabActive = true,
  });

  final bool isTabActive;

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

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

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedControllerProvider);
    final videos = ref.watch(filteredFeedVideosProvider);
    final hasSearch = ref.watch(searchQueryProvider).trim().isNotEmpty;

    _keepPageInRange(videos.length);

    ref.listen<Object?>(
      feedControllerProvider.select((state) => state.error),
      (previous, next) {
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
              content: const Text(
                'Yeni videolar yüklenemedi. Bağlantını kontrol edip tekrar dene.',
              ),
              action: SnackBarAction(
                label: 'Dene',
                onPressed: () {
                  ref.read(feedControllerProvider.notifier).loadMore();
                },
              ),
            ),
          );
      },
    );

    return ColoredBox(
      color: const Color(0xFF2F1713),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildContent(
            context: context,
            state: feedState,
            videos: videos,
            hasSearch: hasSearch,
          ),
          _FeedTopBar(
            isRefreshing: feedState.isRefreshing,
            onRefresh: () {
              HapticFeedback.selectionClick();
              ref.read(feedControllerProvider.notifier).refresh();
            },
            onSearchChanged: _resetToFirstVideo,
          ),
          if (feedState.isLoadingMore && videos.isNotEmpty)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Center(child: _LoadingMorePill()),
            ),
        ],
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
      return const _FeedLoadingView();
    }

    if (state.error != null && videos.isEmpty) {
      return _FeedMessageView(
        icon: Icons.cloud_off_rounded,
        title: 'Akışa bağlanamadık',
        message:
            'İnternet bağlantını kontrol et. Videoların burada seni bekliyor.',
        buttonLabel: 'Tekrar dene',
        buttonIcon: Icons.refresh_rounded,
        onPressed: () {
          ref.read(feedControllerProvider.notifier).loadInitial();
        },
      );
    }

    if (videos.isEmpty) {
      return _FeedMessageView(
        icon: hasSearch
            ? Icons.search_off_rounded
            : Icons.favorite_outline_rounded,
        title: hasSearch ? 'Eşleşen video yok' : 'İlk değerli videoyu paylaş',
        message: hasSearch
            ? 'Arama ifadesini sadeleştir veya başka bir filtre dene.'
            : 'Hexa akışı henüz boş. İnsanlara gerçekten katkı sağlayan ilk videoyu sen yükle.',
        buttonLabel: hasSearch ? 'Aramayı temizle' : 'Video yükle',
        buttonIcon: hasSearch ? Icons.close_rounded : Icons.add_rounded,
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
      physics: const BouncingScrollPhysics(),
      pageSnapping: true,
      allowImplicitScrolling: true,
      itemCount: videos.length,
      onPageChanged: (index) {
        setState(() => _currentPage = index);
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
            ),
          ),
        );
      },
    );
  }
}

class _FeedTopBar extends ConsumerStatefulWidget {
  const _FeedTopBar({
    required this.isRefreshing,
    required this.onRefresh,
    required this.onSearchChanged,
  });

  final bool isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback onSearchChanged;

  @override
  ConsumerState<_FeedTopBar> createState() => _FeedTopBarState();
}

class _FeedTopBarState extends ConsumerState<_FeedTopBar> {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;
  bool _isSearchOpen = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(searchQueryProvider),
    );
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _isSearchOpen = true);
    HapticFeedback.selectionClick();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _closeSearch() {
    _focusNode.unfocus();
    setState(() => _isSearchOpen = false);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    setState(() {});
    widget.onSearchChanged();
  }

  @override
  Widget build(BuildContext context) {
    final currentType = ref.watch(searchTypeProvider);

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 10,
      left: 14,
      right: 14,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              padding: EdgeInsets.fromLTRB(
                12,
                _isSearchOpen ? 12 : 8,
                12,
                _isSearchOpen ? 12 : 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xD9141C21),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x33FFFFFF)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: _isSearchOpen
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const _SignalMark(),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _focusNode,
                                onChanged: (value) {
                                  ref
                                      .read(searchQueryProvider.notifier)
                                      .state = value;
                                  setState(() {});
                                  widget.onSearchChanged();
                                },
                                textInputAction: TextInputAction.search,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                cursorColor: HexaColors.signalSoft,
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: false,
                                  hintText: _hintFor(currentType),
                                  hintStyle: const TextStyle(
                                    color: Color(0xB3FFFFFF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                onPressed: _clearSearch,
                                tooltip: 'Aramayı temizle',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white70,
                                ),
                              ),
                            IconButton(
                              onPressed: _closeSearch,
                              tooltip: 'Aramayı kapat',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.keyboard_arrow_up_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: SearchType.values.map((type) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: type == SearchType.hashtag ? 0 : 6,
                                ),
                                child: _SearchFilterChip(
                                  type: type,
                                  selected: currentType == type,
                                  onTap: () {
                                    ref
                                        .read(searchTypeProvider.notifier)
                                        .state = type;
                                    widget.onSearchChanged();
                                  },
                                ),
                              ),
                            );
                          }).toList(growable: false),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const _SignalMark(),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Değer akışı',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'İnsanlara katkı sağlayan videolar',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xB3FFFFFF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _TopBarIconButton(
                          tooltip: 'Ara',
                          icon: Icons.search_rounded,
                          onPressed: _openSearch,
                        ),
                        const SizedBox(width: 4),
                        _TopBarIconButton(
                          tooltip: 'Yenile',
                          icon: Icons.refresh_rounded,
                          isBusy: widget.isRefreshing,
                          onPressed: widget.isRefreshing
                              ? null
                              : widget.onRefresh,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  String _hintFor(SearchType type) {
    switch (type) {
      case SearchType.video:
        return 'Videolarda ara';
      case SearchType.user:
        return 'Üretici ara';
      case SearchType.hashtag:
        return '#etiket ara';
    }
  }
}

class _SignalMark extends StatelessWidget {
  const _SignalMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: HexaColors.signal,
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55D83A56),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(
        Icons.favorite_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.isBusy = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0x1FFFFFFF),
        foregroundColor: Colors.white,
      ),
      icon: isBusy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon),
    );
  }
}

class _SearchFilterChip extends StatelessWidget {
  const _SearchFilterChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final SearchType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : const Color(0x1AFFFFFF),
      borderRadius: BorderRadius.circular(HexaRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HexaRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _iconFor(type),
                size: 15,
                color: selected ? HexaColors.ink : Colors.white70,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  _labelFor(type),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? HexaColors.ink : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(SearchType value) {
    switch (value) {
      case SearchType.video:
        return Icons.play_circle_outline_rounded;
      case SearchType.user:
        return Icons.person_outline_rounded;
      case SearchType.hashtag:
        return Icons.tag_rounded;
    }
  }

  String _labelFor(SearchType value) {
    switch (value) {
      case SearchType.video:
        return 'Video';
      case SearchType.user:
        return 'Kişi';
      case SearchType.hashtag:
        return 'Etiket';
    }
  }
}

class _FeedLoadingView extends StatefulWidget {
  const _FeedLoadingView();

  @override
  State<_FeedLoadingView> createState() => _FeedLoadingViewState();
}

class _FeedLoadingViewState extends State<_FeedLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.88, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: HexaColors.signal,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66D83A56),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 31,
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Değerli videolar hazırlanıyor',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Birazdan akıştasın',
            style: TextStyle(
              color: Color(0xB3FFFFFF),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedMessageView extends StatelessWidget {
  const _FeedMessageView({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 110, 28, 36),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0x1FFFFFFF),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0x26FFFFFF)),
                  ),
                  child: Icon(icon, color: Colors.white, size: 34),
                ),
                const SizedBox(height: 22),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onPressed,
                  icon: Icon(buttonIcon),
                  label: Text(buttonLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingMorePill extends StatelessWidget {
  const _LoadingMorePill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC141C21),
        borderRadius: BorderRadius.circular(HexaRadius.pill),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Yeni videolar geliyor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
