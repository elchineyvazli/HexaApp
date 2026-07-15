import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/follow_list_controller.dart';
import '../data/follow_repository.dart';
import '../widgets/follow_user_tile.dart';

class FollowListScreen extends StatelessWidget {
  const FollowListScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.initialType,
  });

  final String userId;
  final String username;
  final FollowListType initialType;

  @override
  Widget build(BuildContext context) {
    final initialIndex = initialType == FollowListType.followers ? 0 : 1;

    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(username.trim().isEmpty ? 'Bağlantılar' : username),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Takipçiler'),
              Tab(text: 'Takip Edilenler'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FollowListTab(
              userId: userId,
              type: FollowListType.followers,
            ),
            _FollowListTab(
              userId: userId,
              type: FollowListType.following,
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowListTab extends ConsumerWidget {
  const _FollowListTab({
    required this.userId,
    required this.type,
  });

  final String userId;
  final FollowListType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = FollowListKey(userId: userId, type: type);
    final state = ref.watch(followListControllerProvider(key));
    final controller = ref.read(followListControllerProvider(key).notifier);

    if (state.isInitialLoading && !state.hasContent) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && !state.hasContent) {
      return _FollowListErrorView(
        onRetry: controller.loadInitial,
      );
    }

    if (!state.hasContent) {
      return _EmptyFollowList(type: type, onRefresh: controller.refresh);
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 320) {
            controller.loadMore();
          }

          return false;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount:
              state.users.length +
              ((state.isLoadingMore || state.error != null) ? 1 : 0),
          separatorBuilder: (context, index) {
            return const Divider(height: 1, indent: 84);
          },
          itemBuilder: (context, index) {
            if (index >= state.users.length) {
              if (state.isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                  ),
                );
              }

              return _FollowListInlineError(onRetry: controller.loadInitial);
            }

            final item = state.users[index];

            return FollowUserTile(
              profile: item.profile,
              onTap: () {
                context.push('/profile/${item.profile.uid}');
              },
            );
          },
        ),
      ),
    );
  }
}

class _EmptyFollowList extends StatelessWidget {
  const _EmptyFollowList({
    required this.type,
    required this.onRefresh,
  });

  final FollowListType type;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isFollowers = type == FollowListType.followers;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFollowers
                            ? Icons.people_outline_rounded
                            : Icons.person_search_rounded,
                        size: 58,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isFollowers
                            ? 'Henüz takipçi yok'
                            : 'Henüz kimse takip edilmiyor',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FollowListErrorView extends StatelessWidget {
  const _FollowListErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 54,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            const Text(
              'Liste yüklenemedi.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}


class _FollowListInlineError extends StatelessWidget {
  const _FollowListInlineError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Flexible(child: Text('Liste yenilenemedi.')),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onRetry,
            child: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }
}
