import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'feed_models.dart';

enum SearchType { video, user, hashtag }

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchTypeProvider = StateProvider<SearchType>((ref) => SearchType.video);

final feedFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.watch(feedFirestoreProvider));
});

final feedControllerProvider =
    StateNotifierProvider.autoDispose<FeedController, FeedState>((ref) {
      final controller = FeedController(ref.watch(feedRepositoryProvider));

      unawaited(controller.loadInitial());

      return controller;
    });

final filteredFeedVideosProvider = Provider.autoDispose<List<VideoModel>>((
  ref,
) {
  final videos = ref.watch(
    feedControllerProvider.select((state) => state.videos),
  );

  final query = ref.watch(searchQueryProvider).trim();

  final type = ref.watch(searchTypeProvider);

  if (query.isEmpty) {
    return videos;
  }

  return List<VideoModel>.unmodifiable(
    videos.where((video) {
      switch (type) {
        case SearchType.video:
          return video.matchesVideoQuery(query);

        case SearchType.user:
          return video.matchesUserQuery(query);

        case SearchType.hashtag:
          return video.matchesHashtagQuery(query);
      }
    }),
  );
});

@Deprecated('feedControllerProvider kullanın.')
final videosStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref
      .watch(feedRepositoryProvider)
      .getVideos(
        query: ref.watch(searchQueryProvider),
        type: ref.watch(searchTypeProvider),
      );
});

enum FeedFailureCode {
  permission,
  authentication,
  network,
  missingIndex,
  unavailable,
  unknown,
}

@immutable
class FeedFailure implements Exception {
  const FeedFailure({required this.code, required this.message, this.cause});

  factory FeedFailure.from(Object error) {
    if (error is FeedFailure) {
      return error;
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return FeedFailure(
            code: FeedFailureCode.permission,
            message: 'Feed güvenlik kuralları tarafından engellendi.',
            cause: error,
          );

        case 'unauthenticated':
          return FeedFailure(
            code: FeedFailureCode.authentication,
            message: 'Feed için yeniden giriş yapmalısın.',
            cause: error,
          );

        case 'failed-precondition':
          return FeedFailure(
            code: FeedFailureCode.missingIndex,
            message: 'Feed sorgusu için Firestore indeksi eksik.',
            cause: error,
          );

        case 'unavailable':
        case 'network-request-failed':
          return FeedFailure(
            code: FeedFailureCode.network,
            message: 'Feed bağlantısı kurulamadı.',
            cause: error,
          );

        case 'deadline-exceeded':
        case 'aborted':
          return FeedFailure(
            code: FeedFailureCode.unavailable,
            message: 'Feed şu anda yanıt vermiyor.',
            cause: error,
          );
      }
    }

    return FeedFailure(
      code: FeedFailureCode.unknown,
      message: 'Feed yüklenemedi.',
      cause: error,
    );
  }

  final FeedFailureCode code;
  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

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

  final FeedFailure? error;

  bool get hasContent => videos.isNotEmpty;

  bool get isBusy {
    return isInitialLoading || isRefreshing || isLoadingMore;
  }

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
      error: identical(error, _keepPreviousValue)
          ? this.error
          : error as FeedFailure?,
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
  static const int maximumPageSize = 30;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _videosCollection {
    return _firestore.collection('videos');
  }

  Query<Map<String, dynamic>> _readyFeedQuery() {
    return _videosCollection
        .where('status', isEqualTo: 'ready')
        .where('visibility', isEqualTo: 'public')
        .orderBy('createdAt', descending: true);
  }

  Future<FeedPage> fetchPage({
    DocumentSnapshot<Map<String, dynamic>>? after,
    int limit = defaultPageSize,
  }) async {
    final safeLimit = limit.clamp(1, maximumPageSize).toInt();

    final fetchLimit = (safeLimit * 2).clamp(safeLimit + 1, 50).toInt();

    Query<Map<String, dynamic>> query = _readyFeedQuery().limit(fetchLimit);

    if (after != null) {
      query = query.startAfterDocument(after);
    }

    final snapshot = await query.get();

    final videos = <VideoModel>[];
    var cursor = after;
    var consumedDocuments = 0;

    for (final document in snapshot.docs) {
      cursor = document;
      consumedDocuments++;

      final video = VideoModel.fromMap(document.data(), document.id);

      if (video.isFeedEligible) {
        videos.add(video);
      }

      if (videos.length >= safeLimit) {
        break;
      }
    }

    final stoppedBeforeSnapshotEnd = consumedDocuments < snapshot.docs.length;

    final mayHaveAnotherFirestorePage = snapshot.docs.length == fetchLimit;

    return FeedPage(
      videos: List<VideoModel>.unmodifiable(videos),
      cursor: cursor,
      hasMore: stoppedBeforeSnapshotEnd || mayHaveAnotherFirestorePage,
    );
  }

  Stream<List<VideoModel>> watchLatestVideos({int limit = 50}) {
    final safeLimit = limit.clamp(1, 100).toInt();

    return _readyFeedQuery().limit(safeLimit).snapshots().map((snapshot) {
      final videos = snapshot.docs
          .map((document) => VideoModel.fromMap(document.data(), document.id))
          .where((video) => video.isFeedEligible)
          .toList(growable: false);

      return List<VideoModel>.unmodifiable(videos);
    });
  }

  @Deprecated('watchLatestVideos kullanın.')
  Stream<List<Map<String, dynamic>>> getVideos({
    String query = '',
    SearchType type = SearchType.video,
  }) {
    return _readyFeedQuery().limit(50).snapshots().map((snapshot) {
      final normalizedQuery = query.trim();

      return snapshot.docs
          .where((document) {
            final model = VideoModel.fromMap(document.data(), document.id);

            if (!model.isFeedEligible) {
              return false;
            }

            switch (type) {
              case SearchType.video:
                return model.matchesVideoQuery(normalizedQuery);

              case SearchType.user:
                return model.matchesUserQuery(normalizedQuery);

              case SearchType.hashtag:
                return model.matchesHashtagQuery(normalizedQuery);
            }
          })
          .map(
            (document) => <String, dynamic>{
              ...document.data(),
              'id': document.id,
            },
          )
          .toList(growable: false);
    });
  }
}

class FeedController extends StateNotifier<FeedState> {
  FeedController(this._repository) : super(const FeedState());

  final FeedRepository _repository;

  DocumentSnapshot<Map<String, dynamic>>? _cursor;

  int _requestGeneration = 0;
  bool _disposed = false;

  Future<void> loadInitial() async {
    final generation = ++_requestGeneration;
    final hasContent = state.hasContent;

    state = state.copyWith(
      isInitialLoading: !hasContent,
      isRefreshing: hasContent,
      isLoadingMore: false,
      error: null,
    );

    try {
      final page = await _repository.fetchPage();

      if (!_isCurrent(generation)) {
        return;
      }

      _cursor = page.cursor;

      state = FeedState(
        videos: _mergeUnique(page.videos),
        hasMore: page.hasMore,
      );
    } catch (error) {
      if (!_isCurrent(generation)) {
        return;
      }

      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        error: FeedFailure.from(error),
      );
    }
  }

  Future<void> refresh() => loadInitial();

  Future<void> loadMore() async {
    if (state.isBusy || !state.hasMore) {
      return;
    }

    final generation = _requestGeneration;

    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final page = await _repository.fetchPage(after: _cursor);

      if (!_isCurrent(generation)) {
        return;
      }

      _cursor = page.cursor;

      state = state.copyWith(
        videos: _mergeUnique(<VideoModel>[...state.videos, ...page.videos]),
        isLoadingMore: false,
        hasMore: page.hasMore,
        error: null,
      );
    } catch (error) {
      if (!_isCurrent(generation)) {
        return;
      }

      state = state.copyWith(
        isLoadingMore: false,
        error: FeedFailure.from(error),
      );
    }
  }

  void replaceVideo(VideoModel updatedVideo) {
    final index = state.videos.indexWhere(
      (video) => video.id == updatedVideo.id,
    );

    if (index < 0) {
      return;
    }

    final videos = List<VideoModel>.of(state.videos);

    videos[index] = updatedVideo;

    state = state.copyWith(videos: List<VideoModel>.unmodifiable(videos));
  }

  void incrementViewLocally(String videoId) {
    final index = state.videos.indexWhere((video) => video.id == videoId);

    if (index < 0) {
      return;
    }

    final current = state.videos[index];

    replaceVideo(current.copyWith(viewsCount: current.viewsCount + 1));
  }

  List<VideoModel> _mergeUnique(Iterable<VideoModel> source) {
    final ids = <String>{};
    final result = <VideoModel>[];

    for (final video in source) {
      final id = video.id.trim();

      if (id.isEmpty || !ids.add(id)) {
        continue;
      }

      result.add(video);
    }

    return List<VideoModel>.unmodifiable(result);
  }

  bool _isCurrent(int generation) {
    return !_disposed && generation == _requestGeneration;
  }

  @override
  void dispose() {
    _disposed = true;
    _requestGeneration++;

    super.dispose();
  }
}
