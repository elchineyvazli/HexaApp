import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/follow_repository.dart';

@immutable
class FollowListKey {
  const FollowListKey({
    required this.userId,
    required this.type,
  });

  final String userId;
  final FollowListType type;

  @override
  bool operator ==(Object other) {
    return other is FollowListKey &&
        other.userId == userId &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(userId, type);
}

@immutable
class FollowListState {
  const FollowListState({
    this.users = const <FollowListUser>[],
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<FollowListUser> users;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  bool get hasContent => users.isNotEmpty;

  FollowListState copyWith({
    List<FollowListUser>? users,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error = _keepPreviousValue,
  }) {
    return FollowListState(
      users: users ?? this.users,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: identical(error, _keepPreviousValue) ? this.error : error,
    );
  }
}

const Object _keepPreviousValue = Object();

final followListControllerProvider = StateNotifierProvider.autoDispose
    .family<FollowListController, FollowListState, FollowListKey>(
  (ref, key) {
    final controller = FollowListController(
      repository: ref.watch(followRepositoryProvider),
      key: key,
    );

    controller.loadInitial();
    return controller;
  },
);

class FollowListController extends StateNotifier<FollowListState> {
  FollowListController({
    required FollowRepository repository,
    required FollowListKey key,
  }) : _repository = repository,
       _key = key,
       super(const FollowListState());

  final FollowRepository _repository;
  final FollowListKey _key;

  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  int _requestGeneration = 0;

  Future<void> loadInitial() async {
    final generation = ++_requestGeneration;
    final hasContent = state.users.isNotEmpty;

    state = state.copyWith(
      isInitialLoading: !hasContent,
      isRefreshing: hasContent,
      isLoadingMore: false,
      error: null,
    );

    try {
      final page = await _repository.fetchFollowPage(
        ownerUserId: _key.userId,
        type: _key.type,
      );

      if (!mounted || generation != _requestGeneration) {
        return;
      }

      _cursor = page.cursor;
      state = FollowListState(
        users: _deduplicate(page.users),
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
      final page = await _repository.fetchFollowPage(
        ownerUserId: _key.userId,
        type: _key.type,
        after: _cursor,
      );

      if (!mounted || generation != _requestGeneration) {
        return;
      }

      _cursor = page.cursor;
      state = state.copyWith(
        users: _deduplicate(<FollowListUser>[
          ...state.users,
          ...page.users,
        ]),
        isLoadingMore: false,
        hasMore: page.hasMore,
        error: null,
      );
    } catch (error) {
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      state = state.copyWith(
        isLoadingMore: false,
        error: error,
      );
    }
  }

  List<FollowListUser> _deduplicate(List<FollowListUser> source) {
    final usersById = <String, FollowListUser>{};

    for (final user in source) {
      final userId = user.profile.uid.trim();

      if (userId.isNotEmpty) {
        usersById[userId] = user;
      }
    }

    return List<FollowListUser>.unmodifiable(usersById.values);
  }
}
