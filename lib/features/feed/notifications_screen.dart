// lib/features/feed/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'SİBER SİNYALLER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontFamily: 'Orbitron',
          ),
        ),
        centerTitle: false,
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
        ),
        error: (error, stack) => Center(
          child: Text('Sinyal Hatası: $error', style: const TextStyle(color: Colors.redAccent)),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  const Text(
                    'Henüz gelen bir sinyal yok.',
                    style: TextStyle(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = notifications[index];
              return _buildNotificationCard(context, item);
            },
          );
        },
      ),
    );
  }

  // ⚡ BUKALEMUN SİBERPUNK BİLDİRİM KARTI ⚡
  Widget _buildNotificationCard(BuildContext context, NotificationModel item) {
    final theme = _getNotificationTheme(item.type);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF181926),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isRead ? Colors.white12 : theme.color.withOpacity(0.6),
          width: item.isRead ? 1.0 : 1.5,
        ),
        boxShadow: item.isRead
            ? []
            : [
                BoxShadow(
                  color: theme.color.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ],
      ),
      child: Row(
        children: [
          // İkon / Avatar Alanı
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.color, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF0F172A),
                  backgroundImage: item.senderAvatar.isNotEmpty ? NetworkImage(item.senderAvatar) : null,
                  child: item.senderAvatar.isEmpty
                      ? const Icon(Icons.person, color: Colors.white70, size: 20)
                      : null,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(theme.icon, color: Colors.white, size: 10),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Metin ve İçerik
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${item.senderName} ',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      TextSpan(
                        text: item.message,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(item.createdAt),
                  style: TextStyle(color: theme.color.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Okunmadı İşareti (Küçük Neon Daire)
          if (!item.isRead)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: theme.color, blurRadius: 6)],
              ),
            ),
        ],
      ),
    );
  }

  // Bildirim Türüne Göre Renk ve İkon Belirleme Motoru
  ({Color color, IconData icon}) _getNotificationTheme(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return (color: const Color(0xFFEF4444), icon: Icons.favorite_rounded); // Neon Kırmızı
      case NotificationType.comment:
        return (color: const Color(0xFF9D4EDD), icon: Icons.chat_bubble_rounded); // Kuantum Moru
      case NotificationType.follow:
        return (color: const Color(0xFF00E5FF), icon: Icons.person_add_rounded); // Lazer Siyan
      case NotificationType.system:
        return (color: const Color(0xFFFF5E00), icon: Icons.bolt_rounded); // Neon Turuncu
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Şimdi';
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inSeconds < 60) return '${diff.inSeconds}sn önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk önce';
    if (diff.inHours < 24) return '${diff.inHours}sa önce';
    return '${diff.inDays}g önce';
  }
}