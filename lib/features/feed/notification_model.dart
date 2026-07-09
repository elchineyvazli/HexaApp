// lib/features/feed/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Gelen bildirim türleri
enum NotificationType { like, comment, follow, system }

class NotificationModel {
  final String id;
  final NotificationType type;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String message;
  final String? targetId; // Örn: Tıklanılan videonun ID'si
  final Timestamp? createdAt;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.message,
    this.targetId,
    this.createdAt,
    required this.isRead,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    NotificationType parsedType;
    switch (map['type']) {
      case 'like':
        parsedType = NotificationType.like;
        break;
      case 'comment':
        parsedType = NotificationType.comment;
        break;
      case 'follow':
        parsedType = NotificationType.follow;
        break;
      default:
        parsedType = NotificationType.system;
    }

    return NotificationModel(
      id: docId,
      type: parsedType,
      senderId: map['senderId'] as String? ?? 'system',
      senderName: map['senderName'] as String? ?? 'Siber Yolcu',
      senderAvatar: map['senderAvatar'] as String? ?? '',
      message: map['message'] as String? ?? 'Yeni bir sinyal aldın.',
      targetId: map['targetId'] as String?,
      createdAt: map['createdAt'] as Timestamp?,
      isRead: map['isRead'] as bool? ?? false,
    );
  }
}

// ⚡ CANLI BİLDİRİM AKIŞI (STREAM PROVIDER) ⚡
final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return NotificationModel.fromMap(doc.data(), doc.id);
    }).toList();
  });
});