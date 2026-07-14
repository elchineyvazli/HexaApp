import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexa/features/auth/application/auth_service.dart';

import '../feed/feed_models.dart';
import '../settings/settings_screen.dart';
import 'edit_profile_sheet.dart';
import 'profile_model.dart';
import 'profile_video_viewer_screen.dart';
import 'profile_widgets.dart';
import 'unauthenticated_profile_view.dart';
import 'widgets/profile_video_tile.dart';
import 'widgets/sliver_app_bar_delegate.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.userId});

  final String? userId;

  @override
  ConsumerState<ProfileScreen> createState() {
    return _ProfileScreenState();
  }
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String _targetUserId;
  bool _isCurrentUser = true;

  @override
  void initState() {
    super.initState();
    _initializeTargetUser();
  }

  void _initializeTargetUser() {
    final currentUserId = _auth.currentUser?.uid ?? '';

    _targetUserId = widget.userId ?? currentUserId;

    _isCurrentUser = _targetUserId == currentUserId;
  }

  Stream<UserProfileModel> _profileStream() {
    return _firestore
        .collection('users')
        .doc(_targetUserId)
        .snapshots()
        .map(
          (document) =>
              UserProfileModel.fromMap(document.data(), _targetUserId),
        );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _videosStream() {
    return _firestore
        .collection('videos')
        .where('uploaderId', isEqualTo: _targetUserId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const _ProfileLoadingView(),
      error: (error, stackTrace) {
        return _ProfileErrorView(message: error.toString());
      },
      data: (user) {
        if (user == null && widget.userId == null) {
          return const UnauthenticatedProfileView();
        }

        if (widget.userId == null &&
            user != null &&
            _targetUserId != user.uid) {
          _targetUserId = user.uid;
          _isCurrentUser = true;
        }

        return StreamBuilder<UserProfileModel>(
          stream: _profileStream(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _ProfileLoadingView();
            }

            if (profileSnapshot.hasError) {
              return _ProfileErrorView(
                message: profileSnapshot.error.toString(),
              );
            }

            final profile =
                profileSnapshot.data ??
                UserProfileModel.fromMap(null, _targetUserId);

            return _buildProfile(profile);
          },
        );
      },
    );
  }

  Widget _buildProfile(UserProfileModel profile) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _videosStream(),
        builder: (context, videosSnapshot) {
          if (videosSnapshot.hasError) {
            return _ProfileErrorView(message: videosSnapshot.error.toString());
          }

          final documents =
              videosSnapshot.data?.docs ??
              const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

          final videos = documents
              .map(
                (document) => VideoModel.fromMap(document.data(), document.id),
              )
              .toList(growable: false);

          final postCount = videos.length;

          final totalSignals = videos.fold<int>(0, (total, video) {
            return total + video.signalCount;
          });

          return DefaultTabController(
            length: 2,
            child: NestedScrollView(
              headerSliverBuilder: (context, _) {
                final scheme = Theme.of(context).colorScheme;

                return [
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          if (_isCurrentUser)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: 4,
                                  right: 8,
                                ),
                                child: IconButton(
                                  tooltip: 'Profil menüsü',
                                  onPressed: () {
                                    _showProfileMenu(profile);
                                  },
                                  icon: const Icon(Icons.menu_rounded),
                                ),
                              ),
                            ),
                          ProfileHeader(
                            user: profile,
                            postsCount: postCount,
                            totalLikes: totalSignals,
                            isCurrentUser: _isCurrentUser,
                            onEditProfile: () {
                              _openEditProfile(profile);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: SliverAppBarDelegate(
                      TabBar(
                        indicatorColor: scheme.primary,
                        labelColor: scheme.onSurface,
                        unselectedLabelColor: scheme.onSurfaceVariant,
                        tabs: const [
                          Tab(icon: Icon(Icons.grid_view_rounded)),
                          Tab(icon: Icon(Icons.bookmark_border_rounded)),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _buildVideoGrid(videos),
                  const _SavedVideosPlaceholder(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openEditProfile(UserProfileModel profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return EditProfileSheet(user: profile);
      },
    );
  }

  Future<void> _showProfileMenu(UserProfileModel profile) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.settings_rounded),
                title: const Text('Ayarlar'),
                subtitle: const Text('Tema, Hexa modu ve depolama'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(sheetContext).pop();

                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) {
                        return const SettingsScreen();
                      },
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Profili düzenle'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openEditProfile(profile);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Hesaptan çık',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _auth.signOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoGrid(List<VideoModel> videos) {
    if (videos.isEmpty) {
      return const _EmptyProfileVideos();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];

        return ProfileVideoTile(
          thumbnailUrl: video.thumbnailUrl,
          viewsCount: video.viewsCount,
          onTap: () {
            _openVideoViewer(videos: videos, initialIndex: index);
          },
        );
      },
    );
  }

  void _openVideoViewer({
    required List<VideoModel> videos,
    required int initialIndex,
  }) {
    if (videos.isEmpty || initialIndex < 0 || initialIndex >= videos.length) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return ProfileVideoViewerScreen(
            videos: List<VideoModel>.unmodifiable(videos),
            initialIndex: initialIndex,
          );
        },
      ),
    );
  }
}

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      ),
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  const _ProfileErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Profil yüklenemedi.\n$message',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _EmptyProfileVideos extends StatelessWidget {
  const _EmptyProfileVideos();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.videocam_off_outlined,
            color: scheme.onSurfaceVariant,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Henüz bir video yüklenmemiş.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SavedVideosPlaceholder extends StatelessWidget {
  const _SavedVideosPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Kaydedilen videolar yakında burada.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
