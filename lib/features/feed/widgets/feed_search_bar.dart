import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../feed_repository.dart';

class FeedSearchBar extends ConsumerStatefulWidget {
  const FeedSearchBar({super.key, this.dismissToken = 0, this.onFocusChanged});

  final int dismissToken;
  final ValueChanged<bool>? onFocusChanged;

  @override
  ConsumerState<FeedSearchBar> createState() {
    return _FeedSearchBarState();
  }
}

class _FeedSearchBarState extends ConsumerState<FeedSearchBar>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isFocused = false;

  // ---- Animasyon kontrolcüleri ----
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _controller.text = ref.read(searchQueryProvider);
    _focusNode.addListener(_handleFocusChanged);

    // Şeffaf durumda süzülen ışık efekti
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Odaklanınca parlayan aura
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeOut));
    _glowController.value = 0.0;
  }

  @override
  void didUpdateWidget(covariant FeedSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.dismissToken != widget.dismissToken) {
      _collapse();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    _shimmerController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    final nextFocused = _focusNode.hasFocus;

    if (_isFocused == nextFocused) {
      return;
    }

    setState(() {
      _isFocused = nextFocused;
    });

    widget.onFocusChanged?.call(nextFocused);

    // Glow animasyonunu tetikle
    if (nextFocused) {
      _glowController.forward();
    } else {
      _glowController.reverse();
    }
  }

  void _collapse() {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  void _clearQuery() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    setState(() {});
    _focusNode.requestFocus();
  }

  void _changeSearchType(SearchType type) {
    ref.read(searchTypeProvider.notifier).state = type;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchType = ref.watch(searchTypeProvider);
    final currentQuery = ref.watch(searchQueryProvider);
    final hasQuery = currentQuery.trim().isNotEmpty;

    ref.listen<String>(searchQueryProvider, (previous, next) {
      if (_controller.text == next) return;
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    });

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 10,
      left: 12,
      right: 12,
      child: TapRegion(
        onTapOutside: (_) => _collapse(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final passiveWidth = hasQuery ? 210.0 : 164.0;

            return Align(
              alignment: Alignment.topCenter,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _glowController,
                  _shimmerController,
                ]),
                builder: (context, child) {
                  final glowOpacity = _glowAnimation.value;
                  final shimmerPos = _shimmerAnimation.value;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    width: _isFocused
                        ? constraints.maxWidth
                        : passiveWidth.clamp(140.0, constraints.maxWidth),
                    height: _isFocused ? 52 : 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      // Odaklıyken hafifçe parlayan dış aura
                      boxShadow: [
                        if (glowOpacity > 0.01)
                          BoxShadow(
                            color: Colors.white.withOpacity(0.15 * glowOpacity),
                            blurRadius: 28 * glowOpacity,
                            spreadRadius: 2 * glowOpacity,
                          ),
                        if (_isFocused)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Stack(
                        children: [
                          // Arka plan cam efekti
                          BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: _isFocused ? 20 : 10,
                              sigmaY: _isFocused ? 20 : 10,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(
                                  alpha: _isFocused ? 0.82 : 0.10,
                                ),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(
                                    alpha: _isFocused ? 0.20 : 0.07,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Hafif süzülen ışık (pasif durumda)
                          if (!_isFocused)
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment(shimmerPos, 0.0),
                                child: FractionallySizedBox(
                                  widthFactor: 0.6,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.0),
                                          Colors.white.withOpacity(0.08),
                                          Colors.white.withOpacity(0.0),
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // İçerik
                          Padding(
                            padding: EdgeInsets.only(
                              left: _isFocused ? 7.0 : 14.0,
                              right: _isFocused ? 7.0 : 14.0,
                            ),
                            child: Row(
                              children: [
                                if (_isFocused)
                                  _SearchTypeButton(
                                    type: searchType,
                                    onSelected: _changeSearchType,
                                  )
                                else
                                  const Icon(
                                    Icons.search_rounded,
                                    color: Color(0x70FFFFFF),
                                    size: 20,
                                  ),
                                SizedBox(width: _isFocused ? 5 : 9),
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    focusNode: _focusNode,
                                    cursorColor: Colors.white,
                                    textInputAction: TextInputAction.search,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: _isFocused ? 1 : 0.58,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    onChanged: (value) {
                                      ref
                                              .read(
                                                searchQueryProvider.notifier,
                                              )
                                              .state =
                                          value;
                                      setState(() {});
                                    },
                                    onSubmitted: (_) => _collapse(),
                                    decoration: InputDecoration(
                                      hintText: _isFocused
                                          ? _hintForType(searchType)
                                          : 'Ara',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: _isFocused ? 0.56 : 0.38,
                                        ),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 160),
                                  child:
                                      _isFocused && _controller.text.isNotEmpty
                                      ? IconButton(
                                          key: const ValueKey('clear-search'),
                                          tooltip: 'Aramayı temizle',
                                          onPressed: _clearQuery,
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            color: Colors.white70,
                                            size: 18,
                                          ),
                                        )
                                      : const SizedBox.shrink(
                                          key: ValueKey('empty-search-action'),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  String _hintForType(SearchType type) {
    switch (type) {
      case SearchType.video:
        return 'Video ara';
      case SearchType.user:
        return 'Kullanıcı ara';
      case SearchType.hashtag:
        return 'Hashtag ara';
    }
  }
}

class _SearchTypeButton extends StatelessWidget {
  const _SearchTypeButton({required this.type, required this.onSelected});

  final SearchType type;
  final ValueChanged<SearchType> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SearchType>(
      tooltip: 'Arama türü',
      initialValue: type,
      onSelected: onSelected,
      color: const Color(0xF21A1A1A),
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      itemBuilder: (context) {
        return SearchType.values
            .map((value) {
              return PopupMenuItem<SearchType>(
                value: value,
                child: Row(
                  children: [
                    Icon(_iconForType(value), color: Colors.white70, size: 19),
                    const SizedBox(width: 10),
                    Text(
                      _labelForType(value),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            })
            .toList(growable: false);
      },
      child: SizedBox(
        width: 38,
        height: 38,
        child: Icon(_iconForType(type), color: Colors.white, size: 20),
      ),
    );
  }

  IconData _iconForType(SearchType type) {
    switch (type) {
      case SearchType.video:
        return Icons.play_circle_outline_rounded;
      case SearchType.user:
        return Icons.person_outline_rounded;
      case SearchType.hashtag:
        return Icons.tag_rounded;
    }
  }

  String _labelForType(SearchType type) {
    switch (type) {
      case SearchType.video:
        return 'Video';
      case SearchType.user:
        return 'Kullanıcı';
      case SearchType.hashtag:
        return 'Hashtag';
    }
  }
}
