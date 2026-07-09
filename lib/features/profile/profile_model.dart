// lib/features/profile/profile_model.dart

class UserProfileModel {
  final String uid;
  final String username;
  final String displayName;
  final String profileImageUrl;
  final String bio;
  final int coins;
  final int followersCount;
  final int followingCount;

  const UserProfileModel({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.profileImageUrl,
    required this.bio,
    required this.coins,
    required this.followersCount,
    required this.followingCount,
  });

  // Gelen veride eksik alan varsa uygulama patlamaz, varsayılan (default) değer devreye girer
  factory UserProfileModel.fromMap(Map<String, dynamic>? data, String uid) {
    final map = data ?? {};
    final email = map['email'] as String? ?? 'siber@hexa.com';
    final defaultUsername = '@${email.split('@')[0]}';

    return UserProfileModel(
      uid: uid,
      username: map['username'] as String? ?? defaultUsername,
      displayName: map['displayName'] as String? ?? 'Hexa Kullanıcısı',
      profileImageUrl: map['profileImageUrl'] as String? ?? '',
      bio:
          map['bio'] as String? ??
          'Siber ağda yeni nesil içerik üreticisi 🚀\n#Hexa #Cyberpunk #Coders',
      coins: map['coins'] as int? ?? 0,
      followersCount: map['followersCount'] as int? ?? 0,
      followingCount: map['followingCount'] as int? ?? 0,
    );
  }
}
