import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../feed_repository.dart';

class FeedSearchBar extends ConsumerStatefulWidget {
  const FeedSearchBar({this.dismissToken = 0, this.onFocusChanged, super.key});

  final int dismissToken;
  final ValueChanged<bool>? onFocusChanged;

  @override
  ConsumerState<FeedSearchBar> createState() {
    return _FeedSearchBarState();
  }
}

class _FeedSearchBarState extends ConsumerState<FeedSearchBar> {
  static const Color _surfaceColor = Color(0xE6111116);
  static const Color _accentColor = Color(0xFF8B5CF6);

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isFocused = false;

  @override
  void initState() {
    super.initState();

    _controller.text = ref.read(searchQueryProvider);
    _focusNode.addListener(_handleFocusChanged);
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
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchType = ref.watch(searchTypeProvider);
    final currentQuery = ref.watch(searchQueryProvider);
    final hasQuery = currentQuery.trim().isNotEmpty;

    ref.listen<String>(searchQueryProvider, (previous, next) {
      if (_controller.text == next) {
        return;
      }

      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    });

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 12,
      left: 16,
      right: 16,
      child: TapRegion(
        onTapOutside: (_) {
          _collapse();
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final passiveWidth = hasQuery ? 228.0 : 176.0;

            final targetWidth = _isFocused
                ? constraints.maxWidth
                : passiveWidth > constraints.maxWidth
                ? constraints.maxWidth
                : passiveWidth;

            return Align(
              alignment: Alignment.topCenter,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                opacity: _isFocused ? 1 : 0.10,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  width: targetWidth,
                  height: _isFocused ? 52 : 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: _isFocused
                        ? const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x52000000),
                              blurRadius: 24,
                              offset: Offset(0, 10),
                            ),
                          ]
                        : const <BoxShadow>[],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: _isFocused ? 22 : 12,
                        sigmaY: _isFocused ? 22 : 12,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.only(
                          left: _isFocused ? 16 : 14,
                          right: _isFocused ? 8 : 14,
                        ),
                        decoration: BoxDecoration(
                          color: _isFocused
                              ? _surfaceColor
                              : Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _isFocused
                                ? Colors.white.withValues(alpha: 0.14)
                                : Colors.white.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.search_rounded,
                                size: _isFocused ? 21 : 20,
                                color: Colors.white.withValues(
                                  alpha: _isFocused ? 0.90 : 0.76,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                cursorColor: _accentColor,
                                cursorWidth: 1.6,
                                textInputAction: TextInputAction.search,
                                textCapitalization: TextCapitalization.none,
                                style: TextStyle(
                                  color: Colors.white.withValues(
                                    alpha: _isFocused ? 0.96 : 0.82,
                                  ),
                                  fontSize: 14,
                                  height: 1.2,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.15,
                                ),
                                onChanged: (value) {
                                  ref.read(searchQueryProvider.notifier).state =
                                      value;

                                  setState(() {});
                                },
                                onSubmitted: (_) {
                                  _collapse();
                                },
                                decoration: InputDecoration(
                                  hintText: _isFocused
                                      ? _hintForType(searchType)
                                      : 'Ara',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(
                                      alpha: _isFocused ? 0.42 : 0.68,
                                    ),
                                    fontSize: 14,
                                    height: 1.2,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.15,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isCollapsed: true,
                                ),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 160),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: _isFocused && _controller.text.isNotEmpty
                                  ? IconButton(
                                      key: const ValueKey<String>(
                                        'clear-search',
                                      ),
                                      tooltip: 'Aramayı temizle',
                                      onPressed: _clearQuery,
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 34,
                                            height: 34,
                                          ),
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: Colors.white.withValues(
                                          alpha: 0.68,
                                        ),
                                        size: 18,
                                      ),
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey<String>(
                                        'empty-clear-action',
                                      ),
                                    ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: _isFocused
                                  ? _SearchTypeButton(
                                      key: const ValueKey<String>(
                                        'search-type-button',
                                      ),
                                      type: searchType,
                                      onSelected: _changeSearchType,
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey<String>(
                                        'empty-type-button',
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
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
  const _SearchTypeButton({
    required this.type,
    required this.onSelected,
    super.key,
  });

  final SearchType type;
  final ValueChanged<SearchType> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SearchType>(
      tooltip: 'Arama türü',
      initialValue: type,
      onSelected: onSelected,
      color: const Color(0xFF17171C),
      elevation: 0,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 156, maxWidth: 180),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      itemBuilder: (context) {
        return SearchType.values
            .map((value) {
              final isSelected = value == type;

              return PopupMenuItem<SearchType>(
                value: value,
                height: 46,
                child: Row(
                  children: <Widget>[
                    Icon(
                      _iconForType(value),
                      size: 19,
                      color: isSelected
                          ? const Color(0xFF8B5CF6)
                          : Colors.white.withValues(alpha: 0.62),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        _labelForType(value),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.72),
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_rounded,
                        size: 17,
                        color: Color(0xFF8B5CF6),
                      ),
                  ],
                ),
              );
            })
            .toList(growable: false);
      },
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(
          Icons.tune_rounded,
          color: Colors.white.withValues(alpha: 0.62),
          size: 18,
        ),
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
