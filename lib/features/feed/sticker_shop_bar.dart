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
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFF131424),
        // Üst kenara ince bir gradient ışık
        border: Border(top: BorderSide(color: Color(0x209D4EDD), width: 1)),
      ),
      child: Stack(
        children: [
          // Arka planda yavaşça kayan bir ışık huzmesi
          Positioned.fill(child: _ShimmerBackground()),
          // Sticker listesi
          ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stickers.length,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            itemBuilder: (context, index) {
              final sticker = stickers[index];
              // En pahalı iki stickera özel "efsanevi" etiketi
              final isLegendary = sticker.cost >= 50;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _StickerCard(
                  sticker: sticker,
                  isLegendary: isLegendary,
                  onTap: () => onStickerTap(sticker),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Arka planda soldan sağa kayan hafif bir ışık
class _ShimmerBackground extends StatefulWidget {
  @override
  State<_ShimmerBackground> createState() => _ShimmerBackgroundState();
}

class _ShimmerBackgroundState extends State<_ShimmerBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ShimmerPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double progress;

  _ShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(progress * 2 - 1, 0),
        end: Alignment(progress * 2 + 0.5, 0),
        colors: [
          const Color(0x009D4EDD),
          const Color(0x089D4EDD),
          const Color(0x009D4EDD),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// Her bir sticker kartı
class _StickerCard extends StatefulWidget {
  final StickerModel sticker;
  final bool isLegendary;
  final VoidCallback onTap;

  const _StickerCard({
    required this.sticker,
    required this.isLegendary,
    required this.onTap,
  });

  @override
  State<_StickerCard> createState() => _StickerCardState();
}

class _StickerCardState extends State<_StickerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // Efsanevi kartlar sürekli hafif parlasın
    if (widget.isLegendary) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpensive = widget.sticker.cost >= 25;
    final borderColor = widget.isLegendary
        ? const Color(0xFFFFD700) // altın
        : isExpensive
        ? const Color(0xFF9D4EDD) // mor
        : const Color(0xFF9D4EDD).withOpacity(0.3);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? 0.93 : _pulseAnimation.value,
            child: Container(
              width: 64,
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1B30).withOpacity(0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor,
                  width: widget.isLegendary ? 1.8 : 1.2,
                ),
                boxShadow: [
                  if (widget.isLegendary)
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  if (isExpensive && !widget.isLegendary)
                    BoxShadow(
                      color: const Color(0xFF9D4EDD).withOpacity(0.15),
                      blurRadius: 8,
                    ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Emoji
                      Text(
                        widget.sticker.emoji,
                        style: TextStyle(
                          fontSize: widget.isLegendary ? 26 : 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Coin miktarı
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5E00).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.sticker.cost}',
                          style: const TextStyle(
                            color: Color(0xFFFF5E00),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Efsanevi kartlarda taç simgesi
                  if (widget.isLegendary)
                    Positioned(
                      top: -4,
                      right: -2,
                      child: Transform.rotate(
                        angle: 0.2,
                        child: const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFD700),
                          size: 14,
                          shadows: [
                            Shadow(color: Color(0x99FFD700), blurRadius: 6),
                          ],
                        ),
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
