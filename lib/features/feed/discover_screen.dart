import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

import 'widgets/discover_state_views.dart';
import 'widgets/discover_video_card.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  Stream<QuerySnapshot<Map<String, dynamic>>> get _videosStream {
    return FirebaseFirestore.instance
        .collection('videos')
        .orderBy('likesCount', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DiscoverHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  HexaSpacing.md,
                  HexaSpacing.sm,
                  HexaSpacing.md,
                  HexaSpacing.md,
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Video, üretici veya konu ara',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.trim().isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Aramayı temizle',
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
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

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: GridView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(
                          HexaSpacing.md,
                          0,
                          HexaSpacing.md,
                          110,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 260,
                              crossAxisSpacing: HexaSpacing.sm,
                              mainAxisSpacing: HexaSpacing.sm,
                              childAspectRatio: 0.68,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
