// lib/features/feed/hexa_comment_sheet.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'feed_models.dart';
import 'comment_list_view.dart';
import 'sticker_shop_bar.dart';

class HexaCommentSheet extends StatefulWidget {
  final String videoId;
  const HexaCommentSheet({super.key, required this.videoId});

  @override
  State<HexaCommentSheet> createState() => _HexaCommentSheetState();
}

class _HexaCommentSheetState extends State<HexaCommentSheet> with SingleTickerProviderStateMixin {
  int _userCoins = 995;
  final TextEditingController _commentController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  String _activeFlyingSticker = '';

  final List<StickerModel> _luxuryStickers = [
    const StickerModel(id: 'st_1', emoji: '🔥', name: 'Neon Fire', cost: 5),
    const StickerModel(id: 'st_2', emoji: '💎', name: 'Cyber Diamond', cost: 10),
    const StickerModel(id: 'st_3', emoji: '👑', name: 'Hexa Crown', cost: 25),
    const StickerModel(id: 'st_4', emoji: '🚀', name: 'Quantum Rocket', cost: 50),
    const StickerModel(id: 'st_5', emoji: '🛸', name: 'Neon UFO', cost: 75),
    const StickerModel(id: 'st_6', emoji: '⚡', name: 'Overdrive', cost: 5),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scaleAnimation = Tween<double>(begin: 0.5, end: 3.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // ⚡ DİNAMİK YORUM ARTIŞ MOTORU ⚡
  Future<void> _postComment(String text, {String sticker = ''}) async {
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? '@hexa_user';

    final videoRef = FirebaseFirestore.instance.collection('videos').doc(widget.videoId);

    // 1. Yorumu koleksiyona yaz
    await videoRef.collection('comments').add({
      'username': username,
      'text': text,
      'sticker': sticker,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Ana videonun yorum sayacını artır
    await videoRef.update({
      'commentsCount': FieldValue.increment(1),
    });
  }

  void _triggerStickerAnimation(String emoji) {
    setState(() => _activeFlyingSticker = emoji);
    _animationController.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _activeFlyingSticker = '');
    });
  }

  void _handleStickerTap(StickerModel sticker) {
    if (_userCoins >= sticker.cost) {
      setState(() => _userCoins -= sticker.cost);
      _postComment('Lüks bir sticker gönderdi!', sticker: sticker.emoji);
      _triggerStickerAnimation(sticker.emoji);
    } else {
      _showCoinShopDialog(sticker);
    }
  }

  void _showCoinShopDialog(StickerModel sticker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121320).withOpacity(0.9),
        title: const Text('COIN YETERSİZ!', style: TextStyle(color: Colors.white)),
        content: const Text('Bu işlem için yeterli bakiyen yok.', style: TextStyle(color: Colors.white54)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.65 + bottomPadding,
            padding: EdgeInsets.only(bottom: bottomPadding),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0E15).withOpacity(0.85),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: const Color(0xFF9D4EDD).withOpacity(0.4), width: 1.5)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('YORUMLAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('C: $_userCoins', style: const TextStyle(color: Color(0xFFFF5E00), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF1F2031), height: 1),
                
                Expanded(child: CommentListView(videoId: widget.videoId)),
                
                StickerShopBar(stickers: _luxuryStickers, onStickerTap: _handleStickerTap),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFF0D0E15),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Siber dünyaya bir yorum bırak...',
                            hintStyle: const TextStyle(color: Color(0xFF4E516B)),
                            filled: true,
                            fillColor: const Color(0xFF181926),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFFFF5E00)),
                        onPressed: () {
                          if (_commentController.text.trim().isNotEmpty) {
                            _postComment(_commentController.text.trim());
                            _commentController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_activeFlyingSticker.isNotEmpty)
            IgnorePointer(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Text(_activeFlyingSticker, style: const TextStyle(fontSize: 80)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}