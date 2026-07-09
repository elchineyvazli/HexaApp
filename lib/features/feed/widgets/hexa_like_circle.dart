// lib/features/feed/widgets/hexa_like_circle.dart
import 'package:flutter/material.dart';

class HexaLikeCircle extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;

  const HexaLikeCircle({super.key, required this.isLiked, required this.onTap});

  @override
  State<HexaLikeCircle> createState() => _HexaLikeCircleState();
}

class _HexaLikeCircleState extends State<HexaLikeCircle> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Dış halkanın sürekli garip bir şekilde dönmesi için sonsuz rotasyon kontrolcüsü
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

    // Halkanın organik/garip nefes alıp verme efekti için pulse kontrolcüsü
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isLiked ? const Color(0xFFEF4444) : Colors.white; // Beğenilince Neon Kırmızı

    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Katman: Sürekli dönen kesikli dış teknolojik halka
            RotationTransition(
              turns: _rotationController,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: activeColor.withOpacity(0.4),
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: CircularProgressIndicator(
                    value: 0.25, // Garip bir kesik halka görüntüsü verir
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(activeColor.withOpacity(0.6)),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ),
            
            // 2. Katman: Çekirdek Daire (Beğenildiğinde parlar ve içi dolar)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isLiked ? const Color(0xFFEF4444) : Colors.transparent,
                border: Border.all(
                  color: activeColor,
                  width: widget.isLiked ? 0 : 2,
                ),
                boxShadow: widget.isLiked
                    ? [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withOpacity(0.8),
                          blurRadius: 12,
                          spreadRadius: 3,
                        )
                      ]
                    : [],
              ),
              child: widget.isLiked
                  ? const Icon(Icons.bolt, color: Colors.white, size: 16) // Siberpunk aktivasyon şimşeği
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}