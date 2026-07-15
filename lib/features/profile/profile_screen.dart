import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexa/features/auth/application/auth_service.dart';

import '../feed/feed_models.dart';
import '../settings/settings_screen.dart';
import 'application/follow_controller.dart';
import 'data/follow_repository.dart';
import 'edit_profile_sheet.dart';
import 'presentation/follow_list_screen.dart';
import 'profile_model.dart';
import 'profile_video_viewer_screen.dart';
import 'profile_widgets.dart';
import 'unauthenticated_profile_view.dart';
import 'widgets/profile_state_views.dart';
import 'widgets/profile_video_tile.dart';
import 'widgets/profile_page_chrome.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

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

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.userId != widget.userId) {
      _initializeTargetUser();
    }
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
      loading: () => const ProfileLoadingView(),
      error: (error, stackTrace) {
        return ProfileErrorView(message: error.toString());
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
              return const ProfileLoadingView();
            }

            if (profileSnapshot.hasError) {
              return ProfileErrorView(
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
    final followStatus = _isCurrentUser
        ? null
        : ref.watch(followStatusProvider(_targetUserId));
    final followAction = _isCurrentUser
        ? null
        : ref.watch(followControllerProvider(_targetUserId));
    final isFollowing = followStatus?.asData?.value ?? false;
    final isFollowBusy =
        (followStatus?.isLoading ?? false) ||
        (followAction?.isLoading ?? false);
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: profilePageGradient),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _videosStream(),
        builder: (context, videosSnapshot) {
          if (videosSnapshot.hasError) {
            return ProfileErrorView(message: videosSnapshot.error.toString());
          }

          final documents =
              videosSnapshot.data?.docs ??
              const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

          final videos = documents
              .map(
                (document) => VideoModel.fromMap(document.data(), document.id),
              )
              .where((video) => video.isReady)
              .toList(growable: false);
          final totalSignals = videos.fold<int>(
            0,
            (total, video) => total + video.signalCount,
          );

          return DefaultTabController(
            length: 2,
            child: NestedScrollView(
              headerSliverBuilder: (context, _) {
                final canGoBack =
                    !_isCurrentUser && Navigator.of(context).canPop();

                return [
                  SliverToBoxAdapter(
                    child: ProfilePageHeader(
                      profile: profile,
                      isCurrentUser: _isCurrentUser,
                      canGoBack: canGoBack,
                      onMenu: () {
                        _showProfileMenu(profile);
                      },
                      child: ProfileHeader(
                        user: profile,
                        postsCount: videos.length,
                        totalSignals: totalSignals,
                        followersCount: profile.followersCount,
                        followingCount: profile.followingCount,
                        isCurrentUser: _isCurrentUser,
                        isFollowing: isFollowing,
                        isFollowBusy: isFollowBusy,
                        onEditProfile: () {
                          _openEditProfile(profile);
                        },
                        onToggleFollow: () {
                          _toggleFollow(isFollowing: isFollowing);
                        },
                        onFollowersTap: () {
                          _openFollowList(
                            profile: profile,
                            initialType: FollowListType.followers,
                          );
                        },
                        onFollowingTap: () {
                          _openFollowList(
                            profile: profile,
                            initialType: FollowListType.following,
                          );
                        },
                      ),
                    ),
                  ),
                  const ProfileTabSliver(),
                ];
              },
              body: TabBarView(
                children: [
                  _buildVideoGrid(videos),
                  const SavedVideosPlaceholder(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleFollow({required bool isFollowing}) async {
    if (_isCurrentUser) {
      return;
    }

    try {
      await ref
          .read(followControllerProvider(_targetUserId).notifier)
          .toggle(isFollowing: isFollowing);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(followErrorMessage(error))));
    }
  }

  void _openFollowList({
    required UserProfileModel profile,
    required FollowListType initialType,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return FollowListScreen(
            userId: profile.uid,
            username: profile.username,
            initialType: initialType,
          );
        },
      ),
    );
  }

  Future<void> _openEditProfile(UserProfileModel profile) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: HexaColors.surface,
      barrierColor: const Color(0x662F1713),
      builder: (sheetContext) {
        return EditProfileSheet(user: profile);
      },
    );
  }

  Future<void> _showProfileMenu(UserProfileModel profile) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: HexaColors.surface,
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
                      builder: (context) => const SettingsScreen(),
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
                  color: HexaColors.error,
                ),
                title: const Text(
                  'Hesaptan çık',
                  style: TextStyle(
                    color: HexaColors.error,
                    fontWeight: FontWeight.w700,
                  ),
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
      return const EmptyProfileVideos();
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        HexaSpacing.sm,
        HexaSpacing.sm,
        HexaSpacing.sm,
        110,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.72,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
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
