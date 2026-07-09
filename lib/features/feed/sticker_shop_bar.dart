// lib/features/feed/sticker_shop_bar.dart
import 'package:flutter/material.dart';
import 'feed_models.dart';

class StickerShopBar extends StatelessWidget {
  final List<StickerModel> stickers;
  final Function(StickerModel) onStickerTap;

  const StickerShopBar({
    super.key,
    required this.stickers,
    required this.onStickerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      color: const Color(0xFF131424),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stickers.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          final sticker = stickers[index];
          return GestureDetector(
            onTap: () => onStickerTap(sticker),
            child: Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1B30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF9D4EDD).withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(sticker.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 2),
                  Text(
                    '${sticker.cost} C',
                    style: const TextStyle(
                      color: Color(0xFFFF5E00),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}