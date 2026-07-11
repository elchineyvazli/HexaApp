import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

/// Hexa'nın yeni marka işareti: altıgen yapı + kalp biçimli Signal.
class HexagonLogo extends StatelessWidget {
  const HexagonLogo({
    this.size = 92,
    this.showShadow = true,
    super.key,
  });

  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Hexa Signal logosu',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: HexagonPainter(showShadow: showShadow),
            ),
            Container(
              width: size * 0.42,
              height: size * 0.42,
              decoration: const BoxDecoration(
                color: HexaColors.signal,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: size * 0.23,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HexagonPainter extends CustomPainter {
  const HexagonPainter({this.showShadow = true});

  final bool showShadow;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.47;

    for (var index = 0; index < 6; index++) {
      final angle = -math.pi / 2 + (math.pi / 3 * index);
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    if (showShadow) {
      canvas.drawShadow(
        path,
        const Color(0x2AD83A56),
        size.shortestSide * 0.1,
        false,
      );
    }

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          HexaColors.signalSoft,
        ],
      ).createShader(Offset.zero & size);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, size.shortestSide * 0.018).toDouble()
      ..color = HexaColors.signal;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant HexagonPainter oldDelegate) {
    return oldDelegate.showShadow != showShadow;
  }
}
