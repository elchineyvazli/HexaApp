// lib/features/profile/profile_widgets.dart
import 'package:flutter/material.dart';
import 'profile_model.dart';
import 'widgets/stat_column.dart'; // Yeni ayırdığımız parçayı bağladık

class ProfileHeader extends StatelessWidget {
  final UserProfileModel user;
  final int postsCount;
  final int totalLikes;
  final bool isCurrentUser;
  final VoidCallback onEditProfile;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.postsCount,
    required this.totalLikes,
    required this.isCurrentUser,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ⚡ YENİ: Kullanıcı Adı (Username) Profil Fotoğrafının Tam Üstünde! ⚡
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontFamily: 'Orbitron',
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.verified, color: Color(0xFFFF5E00), size: 18),
              ],
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Profil Resmi
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF5E00), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5E00).withOpacity(0.25),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: const Color(0xFF1E293B),
                  backgroundImage: user.profileImageUrl.isNotEmpty
                      ? NetworkImage(user.profileImageUrl)
                      : null,
                  child: user.profileImageUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white70,
                        )
                      : null,
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StatColumn(label: 'Gönderi', value: '$postsCount'),
                    StatColumn(
                      label: 'Takipçi',
                      value: _formatNumber(user.followersCount),
                    ),
                    StatColumn(
                      label: 'Beğeni',
                      value: _formatNumber(totalLikes),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Biyografi Alanı
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              user.bio,
              style: const TextStyle(
                color: Color(0xFF8E92B2),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Aksiyon Butonları & Canlı Coin Bakiyesi
          Row(
            children: [
              if (isCurrentUser)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: const BorderSide(color: Color(0xFF334155)),
                    ),
                    onPressed: onEditProfile,
                    child: const Text(
                      'Profili Düzenle',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5E00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Takip Et',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              const SizedBox(width: 12),

              // ⚡ CANLI COIN ROZETİ (Firestore'dan anlık beslenir) ⚡
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5E00).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF5E00)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Color(0xFFFF5E00),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${user.coins} C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatNumber(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}
