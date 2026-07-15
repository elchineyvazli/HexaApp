// lib/features/feed/feed_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'feed_models.dart';

enum SearchType { video, user, hashtag }

final searchQueryProvider = StateProvider<String>((ref) => '');
final searchTypeProvider = StateProvider<SearchType>((ref) => SearchType.video);

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(FirebaseFirestore.instance);
});

final feedControllerProvider =
    StateNotifierProvider.autoDispose<FeedController, FeedState>((ref) {
      final controller = FeedController(ref.watch(feedRepositoryProvider));
      controller.loadInitial();
      return controller;
    });

final filteredFeedVideosProvider = Provider.autoDispose<List<VideoModel>>((
  ref,
) {
  final videos = ref.watch(
    feedControllerProvider.select((state) => state.videos),
  );
  final rawQuery = ref.watch(searchQueryProvider).trim().toLowerCase();
  final type = ref.watch(searchTypeProvider);

  if (rawQuery.isEmpty) {
    return videos;
  }

  return videos
      .where((video) {
        switch (type) {
          case SearchType.video:
            return video.caption.toLowerCase().contains(rawQuery);
          case SearchType.user:
            final cleanQuery = rawQuery.startsWith('@')
                ? rawQuery.substring(1)
                : rawQuery;
            final username = video.username.replaceFirst('@', '').toLowerCase();
            final displayName = video.uploaderDisplayName.toLowerCase();
            return username.contains(cleanQuery) ||
                displayName.contains(cleanQuery);
          case SearchType.hashtag:
            final cleanTag = rawQuery.startsWith('#') ? rawQuery : '#$rawQuery';
            return video.caption.toLowerCase().contains(cleanTag);
        }
      })
      .toList(growable: false);
});

@Deprecated('feedControllerProvider kullanın.')
final videosStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final type = ref.watch(searchTypeProvider);
  return ref.watch(feedRepositoryProvider).getVideos(query: query, type: type);
});

@immutable
class FeedState {
  const FeedState({
    this.videos = const <VideoModel>[],
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<VideoModel> videos;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  bool get hasContent => videos.isNotEmpty;

  FeedState copyWith({
    List<VideoModel>? videos,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error = _keepPreviousValue,
  }) {
    return FeedState(
      videos: videos ?? this.videos,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: identical(error, _keepPreviousValue) ? this.error : error,
    );
  }
}

const Object _keepPreviousValue = Object();

class FeedPage {
  const FeedPage({
    required this.videos,
    required this.cursor,
    required this.hasMore,
  });

  final List<VideoModel> videos;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}

class FeedRepository {
  FeedRepository(this._firestore);

  static const int defaultPageSize = 12;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _videosCollection =>
      _firestore.collection('videos');

  Future<FeedPage> fetchPage({
    DocumentSnapshot<Map<String, dynamic>>? after,
    int limit = defaultPageSize,
  }) async {
    final videos = <VideoModel>[];
    var cursor = after;
    var hasMore = true;
    var scannedPages = 0;

    // En yeni belgeler hâlâ işleniyor olabilir. Hazır video bulana kadar
    // birkaç ham Firestore sayfasını tarar; böylece boş feed'de takılı kalmaz.
    while (videos.length < limit && hasMore && scannedPages < 10) {
      Query<Map<String, dynamic>> query = _videosCollection
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      final snapshot = await query.get();
      scannedPages++;

      if (snapshot.docs.isEmpty) {
        hasMore = false;
        break;
      }

      cursor = snapshot.docs.last;
      hasMore = snapshot.docs.length == limit;

      for (final document in snapshot.docs) {
        final video = VideoModel.fromMap(document.data(), document.id);
        if (_isFeedReady(video)) {
          videos.add(video);
          if (videos.length == limit) {
            break;
          }
        }
      }
    }

    return FeedPage(
      videos: List<VideoModel>.unmodifiable(videos),
      cursor: cursor,
      hasMore: hasMore,
    );
  }

  Stream<List<Map<String, dynamic>>> getVideos({
    String query = '',
    SearchType type = SearchType.video,
  }) {
    return _videosCollection.limit(50).snapshots().map((snapshot) {
      final normalizedQuery = query.trim().toLowerCase();
      final documents = snapshot.docs
          .map((document) {
            return <String, dynamic>{...document.data(), 'id': document.id};
          })
          .where((data) {
            final model = VideoModel.fromMap(
              data,
              data['id']?.toString() ?? '',
            );

            if (!_isFeedReady(model)) {
              return false;
            }

            if (normalizedQuery.isEmpty) {
              return true;
            }

            switch (type) {
              case SearchType.video:
                return model.caption.toLowerCase().contains(normalizedQuery);
              case SearchType.user:
                final cleanQuery = normalizedQuery.startsWith('@')
                    ? normalizedQuery.substring(1)
                    : normalizedQuery;
                return model.username
                        .replaceFirst('@', '')
                        .toLowerCase()
                        .contains(cleanQuery) ||
                    model.uploaderDisplayName.toLowerCase().contains(
                      cleanQuery,
                    );
              case SearchType.hashtag:
                final cleanTag = normalizedQuery.startsWith('#')
                    ? normalizedQuery
                    : '#$normalizedQuery';
                return model.caption.toLowerCase().contains(cleanTag);
            }
          })
          .toList(growable: false);

      documents.sort((a, b) {
        final aDate = _readTimestamp(a['createdAt']);
        final bDate = _readTimestamp(b['createdAt']);
        return bDate.compareTo(aDate);
      });

      return documents;
    });
  }

  bool _isFeedReady(VideoModel video) {
    return video.isReady &&
        video.isPubliclyVisible &&
        video.playbackUrl.trim().isNotEmpty;
  }
}

class FeedController extends StateNotifier<FeedState> {
  FeedController(this._repository) : super(const FeedState());

  final FeedRepository _repository;

  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  int _requestGeneration = 0;

  Future<void> loadInitial() async {
    final generation = ++_requestGeneration;
    final hasContent = state.videos.isNotEmpty;

    state = state.copyWith(
      isInitialLoading: !hasContent,
      isRefreshing: hasContent,
      isLoadingMore: false,
      error: null,
    );

    try {
      final page = await _repository.fetchPage();
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      _cursor = page.cursor;
      state = FeedState(
        videos: _deduplicate(page.videos),
        hasMore: page.hasMore,
      );
    } catch (error) {
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        error: error,
      );
    }
  }

  Future<void> refresh() => loadInitial();

  Future<void> loadMore() async {
    if (state.isInitialLoading ||
        state.isRefreshing ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    final generation = _requestGeneration;
    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final page = await _repository.fetchPage(after: _cursor);
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      _cursor = page.cursor;
      state = state.copyWith(
        videos: _deduplicate(<VideoModel>[...state.videos, ...page.videos]),
        isLoadingMore: false,
        hasMore: page.hasMore,
        error: null,
      );
    } catch (error) {
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      state = state.copyWith(isLoadingMore: false, error: error);
    }
  }

  List<VideoModel> _deduplicate(List<VideoModel> source) {
    final byId = <String, VideoModel>{};
    for (final video in source) {
      if (video.id.trim().isNotEmpty) {
        byId[video.id] = video;
      }
    }
    return List<VideoModel>.unmodifiable(byId.values);
  }
}

DateTime _readTimestamp(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}
