// lib/features/profile/widgets/avatar_media_station_sheet.dart
import 'package:flutter/material.dart';

class AvatarMediaStationSheet extends StatelessWidget {
  final String profileImageUrl;
  final VoidCallback onPickMedia;

  const AvatarMediaStationSheet({
    super.key,
    required this.profileImageUrl,
    required this.onPickMedia,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // ⚡ Yukarıdan aşağı çekildiğinde X'e basmış gibi ekranı yok et ⚡
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! > 10) Navigator.pop(context);
      },
      child: Container(
        height: MediaQuery.of(context).size.height,
        color: const Color(0xFF0D0E15).withOpacity(0.95),
        child: SafeArea(
          child: Stack(
            children: [
              // Kapatma İkonu (En üst sağda)
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Medya İçeriği & Değiştir Butonları
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF5E00), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5E00).withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: const Color(0xFF1E293B),
                        backgroundImage: profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : null,
                        child: profileImageUrl.isEmpty
                            ? const Icon(Icons.person, size: 80, color: Colors.white70)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'SİBER AVATAR İSTASYONU',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aşağı kaydırarak kapatabilirsin ⬇️',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(height: 40),

                    // Aksiyon Butonu
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5E00),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: onPickMedia,
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: const Text(
                        'Yeni Görsel / Video Seç',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}