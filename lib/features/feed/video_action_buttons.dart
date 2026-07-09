// lib/features/feed/video_action_buttons.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'feed_models.dart';
import 'hexa_comment_sheet.dart';
import 'widgets/hexa_like_circle.dart';

class VideoActionButtons extends StatefulWidget {
  final VideoModel video;

  const VideoActionButtons({super.key, required this.video});

  @override
  State<VideoActionButtons> createState() => _VideoActionButtonsState();
}

class _VideoActionButtonsState extends State<VideoActionButtons> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final videoRef = FirebaseFirestore.instance.collection('videos').doc(widget.video.id);
    final likeRef = videoRef.collection('likes').doc(user?.uid ?? 'guest');

    // ⚡ CANLI DİNLEYİCİ: Hem videonun güncel sayısını hem de senin beğenini aynı anda dinliyoruz!
    return StreamBuilder<DocumentSnapshot>(
      stream: videoRef.snapshots(),
      builder: (context, videoSnapshot) {
        final videoData = videoSnapshot.data?.data() as Map<String, dynamic>?;
        final currentLikes = videoData?['likesCount'] as int? ?? widget.video.likes;

        return StreamBuilder<DocumentSnapshot>(
          stream: likeRef.snapshots(),
          builder: (context, likeSnapshot) {
            final isLiked = likeSnapshot.hasData && likeSnapshot.data!.exists;

            return Positioned(
              right: 16,
              bottom: 50,
              child: Column(
                children: [
                  // Profil İkonu
                  GestureDetector(
                    onTap: () => context.push('/chat/${widget.video.username.replaceAll('@', '')}'),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF5E00)),
                      child: const CircleAvatar(
                        radius: 24, 
                        backgroundColor: Color(0xFF181926), 
                        child: Icon(Icons.person, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Beğeni Dairesi & Bildirim Tetikleyici
                  HexaLikeCircle(
                    isLiked: isLiked,
                    onTap: () async {
                      if (user == null) return;

                      // Bildirim dokümanı için benzersiz bir referans (Senin ID'n + Video ID'si)
                      // Bu sayede aynı videoyu 10 kere beğenip geri alsa bile 10 ayrı bildirim çöpü oluşmaz!
                      final notificationRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.video.uploaderId)
                          .collection('notifications')
                          .doc('${user.uid}_${widget.video.id}');

                      await FirebaseFirestore.instance.runTransaction((transaction) async {
                        if (isLiked) {
                          // 1. BEĞENİ GERİ ALINIYOR
                          transaction.delete(likeRef);
                          transaction.update(videoRef, {'likesCount': currentLikes > 0 ? currentLikes - 1 : 0});
                          
                          // Bildirimi de sessizce sil (Kendi videosu değilse)
                          if (user.uid != widget.video.uploaderId) {
                            transaction.delete(notificationRef);
                          }
                        } else {
                          // 2. VİDEO BEĞENİLİYOR
                          transaction.set(likeRef, {'userId': user.uid, 'createdAt': FieldValue.serverTimestamp()});
                          transaction.update(videoRef, {'likesCount': currentLikes + 1});

                          // ⚡ BİLDİRİM SİNYALİ ATEŞLENİYOR! (Kendi videosunu beğenmediyse)
                          if (user.uid != widget.video.uploaderId) {
                            transaction.set(notificationRef, {
                              'type': 'like',
                              'senderId': user.uid,
                              'senderName': user.displayName ?? '@${user.email?.split('@')[0] ?? 'siber_yolcu'}',
                              'senderAvatar': user.photoURL ?? '',
                              'message': 'siber ağda bir videonu beğendi! 🔥',
                              'targetId': widget.video.id,
                              'createdAt': FieldValue.serverTimestamp(),
                              'isRead': false,
                            });
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 6),
                  
                  Text(
                    '$currentLikes',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Yorum ve Paylaş Butonları
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF9D4EDD), size: 30), 
                    onPressed: () => showModalBottomSheet(
                      context: context, 
                      isScrollControlled: true, 
                      backgroundColor: Colors.transparent, 
                      builder: (context) => HexaCommentSheet(videoId: widget.video.id),
                    ),
                  ),
                  Text('${widget.video.commentsCount}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  IconButton(icon: const Icon(Icons.share, color: Colors.white, size: 28), onPressed: () {}),
                ],
              ),
            );
          },
        );
      },
    );
  }
}