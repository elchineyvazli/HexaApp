import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

/// HEXA'nın sade marka işareti.
///
/// Koyu veya açık yüzey üzerinde kullanılabilen altıgen dış form ve
/// merkezde Signal işaretinden oluşur.
class HexagonLogo extends StatelessWidget {
  const HexagonLogo({this.size = 92, this.showShadow = true, super.key});

  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Semantics(
      image: true,
      label: 'HEXA logosu',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            CustomPaint(
              size: Size.square(size),
              painter: HexagonPainter(
                showShadow: showShadow,
                brightness: brightness,
              ),
            ),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                return HexaGradients.signal.createShader(bounds);
              },
              child: Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: size * 0.22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HexagonPainter extends CustomPainter {
  const HexagonPainter({
    this.showShadow = true,
    this.brightness = Brightness.dark,
  });

  final bool showShadow;
  final Brightness brightness;

  bool get _isDark {
    return brightness == Brightness.dark;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.44;

    final outerPath = _createHexagonPath(center: center, radius: radius);

    if (showShadow) {
      final glowPaint = Paint()
        ..shader = HexaGradients.signal.createShader(bounds)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.0, size.shortestSide * 0.045)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          size.shortestSide * 0.075,
        );

      canvas.drawPath(outerPath, glowPaint);
    }

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _isDark ? HexaColors.surfaceDark : HexaColors.surface;

    canvas.drawPath(outerPath, fillPaint);

    final borderPaint = Paint()
      ..shader = HexaGradients.signal.createShader(bounds)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.3, size.shortestSide * 0.024)
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(outerPath, borderPaint);

    final innerPath = _createHexagonPath(center: center, radius: radius * 0.76);

    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, size.shortestSide * 0.009)
      ..color = _isDark
          ? Colors.white.withOpacity(0.055)
          : Colors.black.withOpacity(0.045);

    canvas.drawPath(innerPath, innerPaint);
  }

  Path _createHexagonPath({required Offset center, required double radius}) {
    final path = Path();

    for (var index = 0; index < 6; index++) {
      final angle = -math.pi / 2 + index * math.pi / 3;

      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );

      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    return path..close();
  }

  @override
  bool shouldRepaint(covariant HexagonPainter oldDelegate) {
    return oldDelegate.showShadow != showShadow ||
        oldDelegate.brightness != brightness;
  }
}
