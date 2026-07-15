import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui'; // Glassmorphism efekti için

// 1. GENİŞLETİLMİŞ MESAJ VERİ MODELİ
class MessageModel {
  final String id;
  final String senderId;
  final String? text; // Nullable yaptık, çünkü mesaj sadece sticker olabilir
  final String?
  stickerPath; // Eğer gönderilen bir sticker ise emojisi/yolu buraya gelecek
  final DateTime timestamp;

  const MessageModel({
    required this.id,
    required this.senderId,
    this.text,
    this.stickerPath,
    required this.timestamp,
  });
}

// Sticker Ürün Modeli (RevenueCat entegrasyon şablonu)
class StickerItem {
  final String id;
  final String name;
  final String price;
  final String emoji;
  final Color glowColor;

  const StickerItem({
    required this.id,
    required this.name,
    required this.price,
    required this.emoji,
    required this.glowColor,
  });
}

class ChatScreen extends StatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  // Mağazada sergilenecek lüks siberpunk sticker listesi
  final List<StickerItem> _storeStickers = [
    const StickerItem(
      id: 'st_neon_crystal',
      name: 'NEON KRİSTAL',
      price: '4.99 \$',
      emoji: '💎',
      glowColor: Color(0xFF6C5CE7),
    ),
    const StickerItem(
      id: 'st_cyber_crown',
      name: 'SİBER TAÇ',
      price: '11.99 \$',
      emoji: '👑',
      glowColor: Color(0xFFFF5E00),
    ),
    const StickerItem(
      id: 'st_plasma_heart',
      name: 'PLAZMA KALP',
      price: '29.99 \$',
      emoji: '❤️‍🔥',
      glowColor: Colors.pinkAccent,
    ),
  ];

  final List<MessageModel> _messages = [
    MessageModel(
      id: 'm1',
      senderId: 'other',
      text:
          'Selam! Videomu beğenmene sevindim. Hexa fütürizmi hakkında ne düşünüyorsun?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    MessageModel(
      id: 'm2',
      senderId: 'me',
      text: 'Harika bir akış hızı var, mimariyi çok beğendim! ⚡',
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        MessageModel(
          id: DateTime.now().toString(),
          senderId: 'me',
          text: _messageController.text.trim(),
          timestamp: DateTime.now(),
        ),
      );
    });
    _messageController.clear();
  }

  // RevenueCat üzerinden sticker satın alınma simülasyonu ve chate fırlatma
  void _purchaseAndSendSticker(StickerItem sticker) {
    // Burada satın alma tetiklenecek. Satın alım başarılı olunca chate ekliyoruz:
    setState(() {
      _messages.add(
        MessageModel(
          id: DateTime.now().toString(),
          senderId: 'me',
          stickerPath: sticker.emoji,
          timestamp: DateTime.now(),
        ),
      );
    });
    context.pop(); // Mağazayı kapat
  }

  // ALTTAN AÇILAN GLASSMORPHIC HEXA MAĞAZA PANELDEN OLUŞTURULMASI
  void _showStickerStore() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors
          .transparent, // Arkadaki blur efektini görmek için transparan yaptık
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.45,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(
                  0xFF181926,
                ).withOpacity(0.85), // Transparan Frosted Basalt
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF6C5CE7).withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8E92B2).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'HEXA LUXE STORE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sticker Ürün Listesi
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _storeStickers.length,
                      itemBuilder: (context, index) {
                        final item = _storeStickers[index];
                        return GestureDetector(
                          onTap: () => _purchaseAndSendSticker(item),
                          child: Container(
                            width: 130,
                            margin: const EdgeInsets.only(right: 16, bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D0E15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: item.glowColor.withOpacity(0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: item.glowColor.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.emoji,
                                  style: const TextStyle(fontSize: 40),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.price,
                                  style: TextStyle(
                                    color: item.glowColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181926),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFFF5E00).withOpacity(0.2),
              child: const Icon(Icons.person, color: Color(0xFFFF5E00)),
            ),
            const SizedBox(width: 12),
            Text(
              '@${widget.chatId}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                final isMe = message.senderId == 'me';

                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: message.stickerPath != null
                      ? Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF181926),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFF5E00).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            message.stickerPath!,
                            style: const TextStyle(fontSize: 48),
                          ),
                        )
                      : Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFFFF5E00)
                                : const Color(0xFF181926),
                            borderRadius: BorderRadius.circular(16).copyWith(
                              bottomRight: isMe
                                  ? const Radius.circular(0)
                                  : const Radius.circular(16),
                              bottomLeft: isMe
                                  ? const Radius.circular(16)
                                  : const Radius.circular(0),
                            ),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Text(
                            message.text ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF181926),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.bolt, color: Color(0xFF6C5CE7), size: 28),
              onPressed: _showStickerStore, // Tetikleyiciyi buraya bağladık!
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Mesajını fırlat...',
                  hintStyle: TextStyle(color: Color(0xFF8E92B2)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFFFF5E00), size: 28),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
