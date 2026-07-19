import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

import 'widgets/discover_state_views.dart';
import 'widgets/discover_video_card.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() {
    return _DiscoverScreenState();
  }
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  String _searchQuery = '';
  bool _searchFocused = false;

  Stream<QuerySnapshot<Map<String, dynamic>>> get _videosStream {
    return FirebaseFirestore.instance
        .collection('videos')
        .orderBy('likesCount', descending: true)
        .snapshots();
  }

  @override
  void initState() {
    super.initState();

    _searchFocusNode.addListener(_handleSearchFocusChanged);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_handleSearchFocusChanged);

    _searchFocusNode.dispose();
    _searchController.dispose();

    super.dispose();
  }

  void _handleSearchFocusChanged() {
    final nextFocused = _searchFocusNode.hasFocus;

    if (_searchFocused == nextFocused) {
      return;
    }

    setState(() {
      _searchFocused = nextFocused;
    });
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
    });

    _searchFocusNode.requestFocus();
  }

  bool _matchesSearch(Map<String, dynamic> data, String normalizedQuery) {
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final searchableValues = <Object?>[
      data['caption'],
      data['description'],
      data['username'],
      data['uploaderDisplayName'],
    ];

    return searchableValues.any((value) {
      return value.toString().trim().toLowerCase().contains(normalizedQuery);
    });
  }

  Future<void> _refresh() async {
    await FirebaseFirestore.instance
        .collection('videos')
        .orderBy('likesCount', descending: true)
        .limit(1)
        .get();
  }

  int _columnCountForWidth(double width) {
    if (width >= 1100) {
      return 6;
    }

    if (width >= 800) {
      return 5;
    }

    if (width >= 560) {
      return 4;
    }

    return 3;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: HexaColors.backgroundDark,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: HexaColors.backgroundDark,
        body: SafeArea(
          bottom: false,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const DiscoverHeader(),
                _DiscoverSearchField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  query: _searchQuery,
                  isFocused: _searchFocused,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  onClear: _clearSearch,
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _videosStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const DiscoverLoadingView();
                      }

                      if (snapshot.hasError) {
                        return DiscoverErrorView(
                          message: snapshot.error.toString(),
                        );
                      }

                      final normalizedQuery = _searchQuery.trim().toLowerCase();

                      final documents =
                          snapshot.data?.docs ??
                          const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                      final videos = documents
                          .where((document) {
                            return _matchesSearch(
                              document.data(),
                              normalizedQuery,
                            );
                          })
                          .toList(growable: false);

                      if (videos.isEmpty) {
                        return DiscoverEmptyView(
                          hasSearch: normalizedQuery.isNotEmpty,
                          onClearSearch: _clearSearch,
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final columnCount = _columnCountForWidth(
                            constraints.maxWidth,
                          );

                          return RefreshIndicator(
                            onRefresh: _refresh,
                            color: HexaColors.purple,
                            backgroundColor: HexaColors.surfaceStrongDark,
                            displacement: 18,
                            edgeOffset: 4,
                            strokeWidth: 2,
                            child: GridView.builder(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: ClampingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.fromLTRB(2, 0, 2, 96),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columnCount,
                                    crossAxisSpacing: 2,
                                    mainAxisSpacing: 2,
                                    childAspectRatio: 0.70,
                                  ),
                              itemCount: videos.length,
                              itemBuilder: (context, index) {
                                final document = videos[index];

                                return DiscoverVideoCard(
                                  data: document.data(),
                                  rank: index + 1,
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
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

class _DiscoverSearchField extends StatelessWidget {
  const _DiscoverSearchField({
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.isFocused,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  final String query;
  final bool isFocused;

  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    final hasQuery = query.trim().isNotEmpty;

    return AnimatedContainer(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: 48,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isFocused ? HexaColors.surfaceMutedDark : HexaColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFocused
              ? HexaColors.purple.withOpacity(0.72)
              : Colors.white.withOpacity(0.07),
          width: 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.search_rounded,
            color: isFocused
                ? Colors.white.withOpacity(0.84)
                : Colors.white.withOpacity(0.46),
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.search,
              cursorColor: HexaColors.purple,
              cursorWidth: 1.6,
              onChanged: onChanged,
              style: const TextStyle(
                color: Color(0xF2FFFFFF),
                fontSize: 14,
                height: 1.2,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.14,
              ),
              decoration: const InputDecoration(
                filled: false,
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Video, üretici veya konu ara',
                hintStyle: TextStyle(
                  color: Color(0x70FFFFFF),
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.14,
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 150),
            child: hasQuery
                ? IconButton(
                    key: const ValueKey<String>('clear-discover-search'),
                    tooltip: 'Aramayı temizle',
                    onPressed: onClear,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 34,
                    ),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withOpacity(0.56),
                      size: 18,
                    ),
                  )
                : const SizedBox.shrink(
                    key: ValueKey<String>('empty-discover-search'),
                  ),
          ),
        ],
      ),
    );
  }
}
