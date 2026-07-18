import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentListView extends StatelessWidget {
  final String videoId;

  const CommentListView({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              tween: Tween(begin: 0.8, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: const Text(
                'İlk yorumu sen yap!',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final username = data['username'] ?? '@anonim';
            final text = data['text'] ?? '';
            final sticker = data['sticker'] ?? '';
            final isStickerComment = sticker.toString().isNotEmpty;

            // Yeni yorumlar hafif sıçrayarak gelsin
            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              tween: Tween(begin: 0.9, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: isStickerComment
                    ? BoxDecoration(
                        color: const Color(0xFF1A1B30).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF5E00).withOpacity(0.5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5E00).withOpacity(0.15),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      )
                    : null,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF1F2031),
                    child: Icon(
                      Icons.person,
                      color: Color(0xFF8E92B2),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    username,
                    style: TextStyle(
                      color: isStickerComment
                          ? const Color(0xFFFF5E00)
                          : const Color(0xFF8E92B2),
                      fontSize: 12,
                      fontWeight: isStickerComment
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      if (isStickerComment) ...[
                        const SizedBox(width: 8),
                        Text(sticker, style: const TextStyle(fontSize: 24)),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
