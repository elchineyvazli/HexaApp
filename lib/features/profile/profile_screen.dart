// lib/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hexa/features/auth/application/auth_service.dart'; // authStateProvider için eklendi
import 'profile_model.dart';
import 'profile_widgets.dart';
import 'edit_profile_sheet.dart';
import 'unauthenticated_profile_view.dart'; // YENİ EKLENDİ: Misafir ekranı importu
import 'widgets/sliver_app_bar_delegate.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  late String _targetUserId;
  bool _isCurrentUser = true;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  void _initUser() {
    final currentUid = _auth.currentUser?.uid ?? '';
    _targetUserId = widget.userId ?? currentUid;
    _isCurrentUser = (_targetUserId == currentUid);
  }

  Stream<UserProfileModel> _getUserProfileStream() {
    return _firestore
        .collection('users')
        .doc(_targetUserId)
        .snapshots()
        .map((doc) => UserProfileModel.fromMap(doc.data(), _targetUserId));
  }

  Stream<QuerySnapshot> _getUserVideosStream() {
    return _firestore
        .collection('videos')
        .where('uploaderId', isEqualTo: _targetUserId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    // YENİ: Firebase oturumunu canlı dinliyoruz!
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
      ),
      error: (err, stack) => Center(
        child: Text('Hata: $err', style: const TextStyle(color: Colors.white)),
      ),
      data: (user) {
        // EĞER KULLANICI GİRİŞ YAPMAMIŞSA (VEYA OTURUM YOKSA) VE KENDİ PROFİLİNE BAKIYORSA:
        if (user == null && widget.userId == null) {
          return const UnauthenticatedProfileView(); // Doğrudan Giriş/Kayıt ekranını göster!
        }

        // Kullanıcı giriş yapmışsa mevcut id'yi güncelle ve normal profili çiz
        if (widget.userId == null &&
            user != null &&
            _targetUserId != user.uid) {
          _targetUserId = user.uid;
          _isCurrentUser = true;
        }

        return StreamBuilder<UserProfileModel>(
          stream: _getUserProfileStream(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
              );
            }

            final userProfile =
                userSnapshot.data ??
                UserProfileModel.fromMap(null, _targetUserId);

            return Container(
              color: const Color(0xFF0F172A),
              child: StreamBuilder<QuerySnapshot>(
                stream: _getUserVideosStream(),
                builder: (context, videosSnapshot) {
                  final videoDocs = videosSnapshot.data?.docs ?? [];

                  final int postsCount = videoDocs.length;
                  int totalLikes = 0;
                  for (var doc in videoDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    totalLikes += (data['likesCount'] as int? ?? 0);
                  }

                  return DefaultTabController(
                    length: 2,
                    child: NestedScrollView(
                      headerSliverBuilder: (context, _) {
                        return [
                          SliverToBoxAdapter(
                            child: SafeArea(
                              child: ProfileHeader(
                                user: userProfile,
                                postsCount: postsCount,
                                totalLikes: totalLikes,
                                isCurrentUser: _isCurrentUser,
                                onEditProfile: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) =>
                                        EditProfileSheet(user: userProfile),
                                  );
                                },
                              ),
                            ),
                          ),
                          SliverPersistentHeader(
                            delegate: SliverAppBarDelegate(
                              const TabBar(
                                indicatorColor: Color(0xFFFF5E00),
                                labelColor: Colors.white,
                                unselectedLabelColor: Color(0xFF8E92B2),
                                tabs: [
                                  Tab(icon: Icon(Icons.grid_on)),
                                  Tab(icon: Icon(Icons.favorite_border)),
                                ],
                              ),
                            ),
                            pinned: true,
                          ),
                        ];
                      },
                      body: TabBarView(
                        children: [
                          if (videoDocs.isEmpty)
                            const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.videocam_off_outlined,
                                    color: Colors.white38,
                                    size: 48,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Henüz bir video yüklenmemiş.',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ],
                              ),
                            )
                          else
                            GridView.builder(
                              padding: const EdgeInsets.all(2),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 0.7,
                                    crossAxisSpacing: 2,
                                    mainAxisSpacing: 2,
                                  ),
                              itemCount: videoDocs.length,
                              itemBuilder: (context, index) {
                                final data =
                                    videoDocs[index].data()
                                        as Map<String, dynamic>;
                                final likes = data['likesCount'] ?? 0;

                                return GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    color: const Color(0xFF1E293B),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        const Center(
                                          child: Icon(
                                            Icons.play_arrow_rounded,
                                            color: Colors.white38,
                                            size: 36,
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 6,
                                          left: 6,
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.favorite,
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$likes',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
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
                          const Center(
                            child: Text(
                              'Gizli Bölge 🔒',
                              style: TextStyle(color: Colors.white54),
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
        );
      },
    );
  }
}
