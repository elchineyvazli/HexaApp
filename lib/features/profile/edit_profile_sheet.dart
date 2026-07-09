// lib/features/profile/edit_profile_sheet.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_model.dart';
import 'widgets/avatar_media_station_sheet.dart';
import 'widgets/cyber_category_selector.dart';

class EditProfileSheet extends StatefulWidget {
  final UserProfileModel user;

  const EditProfileSheet({super.key, required this.user});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  bool _isLoading = false;
  String? _selectedCategory;

  final List<String> _categories = [
    'Video Editor',
    'Streamer',
    'Coder',
    'Gamer',
    'Drone Pilot',
    'Cyber Nomad'
  ];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _bioController = TextEditingController(text: widget.user.bio);
    _selectedCategory = 'Coder';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final newUsername = _usernameController.text.trim();
    final newBio = _bioController.text.trim();

    if (newUsername.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set({
            'username': newUsername.startsWith('@') ? newUsername : '@$newUsername',
            'bio': newBio,
            'category': _selectedCategory ?? 'Cyber Nomad',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e'), backgroundColor: const Color(0xFFFF5E00)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAvatarBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AvatarMediaStationSheet(
        profileImageUrl: widget.user.profileImageUrl,
        onPickMedia: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Galeriden seçim motoru yakında! 🚀')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // ⚡ X (Twitter) tarzi aşağı kaydırarak kapatma kalkanı ⚡
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! > 12) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Profili Düzenle',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Color(0xFFFF5E00), strokeWidth: 2))
                    : const Text('KAYDET', style: TextStyle(color: Color(0xFFFF5E00), fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. KATMAN: AVATAR & UZUN BASMA ETKİLEŞİMİ ---
              Center(
                child: GestureDetector(
                  onLongPress: _showAvatarBottomSheet,
                  onTap: _showAvatarBottomSheet,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFF5E00), width: 2),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFFF5E00).withOpacity(0.25), blurRadius: 15, spreadRadius: 2)
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFF1E293B),
                          backgroundImage: widget.user.profileImageUrl.isNotEmpty
                              ? NetworkImage(widget.user.profileImageUrl)
                              : null,
                          child: widget.user.profileImageUrl.isEmpty
                              ? const Icon(Icons.person, size: 50, color: Colors.white70)
                              : null,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF9D4EDD),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text('Değiştirmek için basılı tut', style: TextStyle(color: Colors.white38, fontSize: 11)),
              ),
              const SizedBox(height: 32),

              // --- 2. KATMAN: FORM ALANLARI ---
              const Text('KULLANICI ADI', style: TextStyle(color: Color(0xFFFF5E00), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF181926),
                  hintText: '@username',
                  hintStyle: const TextStyle(color: Colors.white24),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF5E00), width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),

              const Text('BİYOGRAFİ', style: TextStyle(color: Color(0xFF9D4EDD), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              TextField(
                controller: _bioController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF181926),
                  hintText: 'Siber dünyada yeni bir yolcu...',
                  hintStyle: const TextStyle(color: Colors.white24),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF9D4EDD), width: 1.5)),
                ),
              ),
              const SizedBox(height: 24),

              // --- 3. KATMAN: KATEGORİ SEÇİMİ (CYBER PILLS) ---
              const Text('SİBER KİMLİK KATEGORİSİ', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              CyberCategorySelector(
                categories: _categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: (cat) {
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}