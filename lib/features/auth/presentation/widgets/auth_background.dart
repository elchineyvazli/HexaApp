import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

/// Auth ve profil tamamlama ekranlarında kullanılan yumuşak açık arka plan.
/// Herhangi bir görsel dosyasına ihtiyaç duymaz.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      HexaColors.background,
                      Color(0xFFFFFBFC),
                      Color(0xFFF3FAF7),
                    ],
                    stops: [0, 0.52, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -96,
              right: -78,
              child: _SoftOrb(
                size: 260,
                innerColor: Color(0x55D8D0F4),
                outerColor: Color(0x00D8D0F4),
              ),
            ),
            Positioned(
              top: 210,
              left: -112,
              child: _SoftOrb(
                size: 250,
                innerColor: Color(0x44FFE9ED),
                outerColor: Color(0x00FFE9ED),
              ),
            ),
            Positioned(
              right: -100,
              bottom: -74,
              child: _SoftOrb(
                size: 290,
                innerColor: Color(0x55BFE8D8),
                outerColor: Color(0x00BFE8D8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftOrb extends StatelessWidget {
  const _SoftOrb({
    required this.size,
    required this.innerColor,
    required this.outerColor,
  });

  final double size;
  final Color innerColor;
  final Color outerColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [innerColor, outerColor]),
        ),
      ),
    );
  }
}
