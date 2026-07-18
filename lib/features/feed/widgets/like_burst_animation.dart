import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/hexa_theme.dart';

class LikeBurstAnimation extends StatefulWidget {
  const LikeBurstAnimation({
    required this.token,
    required this.origin,
    required this.signalCount,
    super.key,
  });

  final int token;
  final Offset origin;
  final int signalCount;

  @override
  State<LikeBurstAnimation> createState() {
    return _LikeBurstAnimationState();
  }
}

class _LikeBurstAnimationState extends State<LikeBurstAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Timer? _staticPulseTimer;

  bool _reduceMotion = false;
  bool _showStaticPulse = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _reduceMotion = HexaMotion.reduceMotionOf(context);
  }

  @override
  void didUpdateWidget(covariant LikeBurstAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.token == widget.token || widget.token <= 0) {
      return;
    }

    if (_reduceMotion) {
      _staticPulseTimer?.cancel();

      setState(() {
        _showStaticPulse = true;
      });

      _staticPulseTimer = Timer(HexaMotion.normal, () {
        if (!mounted) {
          return;
        }

        setState(() {
          _showStaticPulse = false;
        });
      });

      return;
    }

    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _staticPulseTimer?.cancel();
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion) {
      return IgnorePointer(
        child: AnimatedOpacity(
          opacity: _showStaticPulse ? 1 : 0,
          duration: HexaMotion.instant,
          child: CustomPaint(
            painter: _HexaBurstPainter(
              origin: widget.origin,
              progress: 0.42,
              opacity: 0.9,
              staticMode: true,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final rawProgress = _controller.value;

          if (rawProgress <= 0 || rawProgress >= 1) {
            return const SizedBox.shrink();
          }

          final progress = Curves.easeOutCubic.transform(rawProgress);

          final opacity =
              1 - Curves.easeIn.transform(_interval(rawProgress, 0.58, 1));

          final countOpacity = _countOpacity(rawProgress);

          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CustomPaint(
                painter: _HexaBurstPainter(
                  origin: widget.origin,
                  progress: progress,
                  opacity: opacity,
                ),
              ),
              Positioned(
                left: widget.origin.dx - 70,
                top:
                    widget.origin.dy +
                    49 -
                    13 * _interval(rawProgress, 0.55, 1),
                width: 140,
                child: Opacity(
                  opacity: countOpacity,
                  child: Text(
                    compactSignalCount(widget.signalCount),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: HexaColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                      shadows: <Shadow>[
                        Shadow(color: HexaColors.earth, blurRadius: 13),
                        Shadow(color: HexaColors.signalGlow, blurRadius: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _countOpacity(double progress) {
    if (progress < 0.16) {
      return 0;
    }

    if (progress < 0.58) {
      return _interval(progress, 0.16, 0.3);
    }

    return 1 - _interval(progress, 0.58, 1);
  }
}

class _HexaBurstPainter extends CustomPainter {
  const _HexaBurstPainter({
    required this.origin,
    required this.progress,
    required this.opacity,
    this.staticMode = false,
  });

  final Offset origin;
  final double progress;
  final double opacity;
  final bool staticMode;

  @override
  void paint(Canvas canvas, Size size) {
    final safeOpacity = opacity.clamp(0.0, 1.0).toDouble();

    final double coreScale = staticMode
        ? 1.0
        : Curves.easeOutBack.transform(_interval(progress, 0.0, 0.44));

    _drawCore(canvas, coreScale: coreScale, opacity: safeOpacity);

    if (!staticMode) {
      _drawParticles(canvas, opacity: safeOpacity);
    }
  }

  void _drawCore(
    Canvas canvas, {
    required double coreScale,
    required double opacity,
  }) {
    final radius = 37 * coreScale;

    final glowRect = Rect.fromCircle(center: origin, radius: radius * 1.7);

    canvas.drawCircle(
      origin,
      radius * 1.7,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            HexaColors.error.withAlpha((115 * opacity).round()),
            HexaColors.signal.withAlpha((66 * opacity).round()),
            HexaColors.transparent,
          ],
        ).createShader(glowRect),
    );

    final rotation = progress * math.pi * 0.9;

    final path = _hexagonPath(
      center: origin,
      radius: radius,
      rotation: rotation,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = HexaColors.hopePink.withAlpha((235 * opacity).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = HexaColors.signal.withAlpha((48 * opacity).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14,
    );

    final coreRect = Rect.fromCircle(center: origin, radius: radius * 0.58);

    canvas.drawCircle(
      origin,
      radius * 0.58,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            HexaColors.hopePink.withAlpha((255 * opacity).round()),
            HexaColors.error.withAlpha((255 * opacity).round()),
            HexaColors.horizon.withAlpha((255 * opacity).round()),
          ],
        ).createShader(coreRect),
    );

    canvas.drawPath(
      _sparkPath(center: origin, radius: radius * 0.31),
      Paint()..color = HexaColors.white.withAlpha((255 * opacity).round()),
    );
  }

  void _drawParticles(Canvas canvas, {required double opacity}) {
    const particleCount = 16;

    for (var index = 0; index < particleCount; index++) {
      final angle =
          index * math.pi * 2 / particleCount + (index.isEven ? 0.08 : -0.05);

      final multiplier = 0.82 + (index % 4) * 0.09;

      final distance = 31 + 73 * progress * multiplier;

      final point = Offset(
        origin.dx + math.cos(angle) * distance,
        origin.dy + math.sin(angle) * distance,
      );

      final particleOpacity = opacity * (1 - _interval(progress, 0.52, 1));

      final particleSize = (index.isEven ? 4.2 : 2.7) * (1 - progress * 0.3);

      final color = index % 3 == 0
          ? HexaColors.warning
          : index % 3 == 1
          ? HexaColors.hopePink
          : const Color(0xFFFFD166);

      if (index.isEven) {
        canvas.save();
        canvas.translate(point.dx, point.dy);
        canvas.rotate(progress * math.pi * 3 + index * 0.17);

        canvas.drawPath(
          _miniStarPath(particleSize),
          Paint()..color = color.withAlpha((255 * particleOpacity).round()),
        );

        canvas.restore();
      } else {
        canvas.drawCircle(
          point,
          particleSize,
          Paint()..color = color.withAlpha((255 * particleOpacity).round()),
        );
      }
    }
  }

  Path _hexagonPath({
    required Offset center,
    required double radius,
    required double rotation,
  }) {
    final path = Path();

    for (var index = 0; index < 6; index++) {
      final angle = rotation - math.pi / 2 + index * math.pi / 3;

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

  Path _sparkPath({required Offset center, required double radius}) {
    return Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(
        center.dx + radius * 0.12,
        center.dy - radius * 0.12,
        center.dx + radius,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx + radius * 0.12,
        center.dy + radius * 0.12,
        center.dx,
        center.dy + radius,
      )
      ..quadraticBezierTo(
        center.dx - radius * 0.12,
        center.dy + radius * 0.12,
        center.dx - radius,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx - radius * 0.12,
        center.dy - radius * 0.12,
        center.dx,
        center.dy - radius,
      )
      ..close();
  }

  Path _miniStarPath(double radius) {
    return Path()
      ..moveTo(0, -radius)
      ..lineTo(radius * 0.27, -radius * 0.27)
      ..lineTo(radius, 0)
      ..lineTo(radius * 0.27, radius * 0.27)
      ..lineTo(0, radius)
      ..lineTo(-radius * 0.27, radius * 0.27)
      ..lineTo(-radius, 0)
      ..lineTo(-radius * 0.27, -radius * 0.27)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _HexaBurstPainter oldDelegate) {
    return oldDelegate.origin != origin ||
        oldDelegate.progress != progress ||
        oldDelegate.opacity != opacity ||
        oldDelegate.staticMode != staticMode;
  }
}

double _interval(double value, double start, double end) {
  if (end <= start) {
    return value >= end ? 1 : 0;
  }

  return ((value - start) / (end - start)).clamp(0, 1).toDouble();
}

String compactSignalCount(int value) {
  if (value >= 1000000) {
    final digits = value >= 10000000 ? 0 : 1;

    return '${(value / 1000000).toStringAsFixed(digits)}M';
  }

  if (value >= 1000) {
    final digits = value >= 10000 ? 0 : 1;

    return '${(value / 1000).toStringAsFixed(digits)}K';
  }

  return value.toString();
}
