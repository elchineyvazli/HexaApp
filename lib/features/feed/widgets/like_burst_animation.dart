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

  Timer? _staticFeedbackTimer;

  bool _reduceMotion = false;
  bool _showStaticFeedback = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
      _staticFeedbackTimer?.cancel();

      setState(() {
        _showStaticFeedback = true;
      });

      _staticFeedbackTimer = Timer(const Duration(milliseconds: 700), () {
        if (!mounted) {
          return;
        }

        setState(() {
          _showStaticFeedback = false;
        });
      });

      return;
    }

    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _staticFeedbackTimer?.cancel();
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion) {
      return IgnorePointer(
        child: AnimatedOpacity(
          opacity: _showStaticFeedback ? 1 : 0,
          duration: HexaMotion.instant,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned(
                left: widget.origin.dx - 42,
                top: widget.origin.dy - 42,
                width: 84,
                height: 84,
                child: const Center(child: _HeartGlyph(size: 62)),
              ),
              Positioned(
                left: widget.origin.dx - 70,
                top: widget.origin.dy + 40,
                width: 140,
                child: _LikeCountLabel(count: widget.signalCount),
              ),
            ],
          ),
        ),
      );
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;

          if (progress <= 0 || progress >= 1) {
            return const SizedBox.shrink();
          }

          final heartEntry = Curves.easeOutBack.transform(
            _interval(progress, 0, 0.34),
          );

          final heartExit =
              1 - Curves.easeInCubic.transform(_interval(progress, 0.64, 1));

          final heartOpacity = (heartEntry * heartExit)
              .clamp(0.0, 1.0)
              .toDouble();

          final heartScale =
              heartEntry *
              (1 -
                  0.08 *
                      Curves.easeOut.transform(
                        _interval(progress, 0.34, 0.64),
                      ));

          final heartRise =
              28 *
              Curves.easeOutCubic.transform(_interval(progress, 0.12, 0.82));

          final heartRotation =
              -0.12 +
              0.12 *
                  Curves.easeOutCubic.transform(_interval(progress, 0, 0.40));

          final countOpacity = _countOpacity(progress);

          final countRise =
              10 *
              Curves.easeOutCubic.transform(_interval(progress, 0.30, 0.72));

          final particleProgress = Curves.easeOutCubic.transform(
            _interval(progress, 0.04, 0.70),
          );

          final particleOpacity =
              1 - Curves.easeInCubic.transform(_interval(progress, 0.38, 0.76));

          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _LikeParticlePainter(
                    origin: widget.origin,
                    progress: particleProgress,
                    opacity: particleOpacity,
                  ),
                ),
              ),
              Positioned(
                left: widget.origin.dx - 48,
                top: widget.origin.dy - 48,
                width: 96,
                height: 96,
                child: Opacity(
                  opacity: heartOpacity,
                  child: Transform.translate(
                    offset: Offset(0, -heartRise),
                    child: Transform.rotate(
                      angle: heartRotation,
                      child: Transform.scale(
                        scale: heartScale,
                        child: const Center(child: _HeartGlyph(size: 72)),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: widget.origin.dx - 70,
                top: widget.origin.dy + 40 - countRise,
                width: 140,
                child: Opacity(
                  opacity: countOpacity,
                  child: _LikeCountLabel(count: widget.signalCount),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _countOpacity(double progress) {
    if (progress < 0.28) {
      return 0;
    }

    if (progress < 0.48) {
      return Curves.easeOutCubic.transform(_interval(progress, 0.28, 0.48));
    }

    if (progress < 0.76) {
      return 1;
    }

    return 1 - Curves.easeInCubic.transform(_interval(progress, 0.76, 1));
  }
}

class _HeartGlyph extends StatelessWidget {
  const _HeartGlyph({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Icon(
          Icons.favorite_rounded,
          size: size + 8,
          color: const Color(0x668B5CF6),
          shadows: const <Shadow>[
            Shadow(color: Color(0xB38B5CF6), blurRadius: 28),
            Shadow(color: Color(0x6606B6D4), blurRadius: 42),
          ],
        ),
        Icon(
          Icons.favorite_rounded,
          size: size,
          color: const Color(0xFF8B5CF6),
          shadows: const <Shadow>[
            Shadow(
              color: Color(0x99000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        Positioned(
          top: size * 0.24,
          left: size * 0.31,
          child: Container(
            width: size * 0.12,
            height: size * 0.12,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.70),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _LikeCountLabel extends StatelessWidget {
  const _LikeCountLabel({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(
          Icons.favorite_rounded,
          color: Color(0xFF8B5CF6),
          size: 18,
          shadows: <Shadow>[
            Shadow(
              color: Color(0xB3000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        const SizedBox(width: 6),
        Text(
          compactSignalCount(count),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.25,
            shadows: <Shadow>[
              Shadow(
                color: Color(0xCC000000),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LikeParticlePainter extends CustomPainter {
  const _LikeParticlePainter({
    required this.origin,
    required this.progress,
    required this.opacity,
  });

  final Offset origin;
  final double progress;
  final double opacity;

  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _cyan = Color(0xFF06B6D4);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || opacity <= 0) {
      return;
    }

    final safeOpacity = opacity.clamp(0.0, 1.0).toDouble();

    final ringRadius = 22 + 38 * progress;

    canvas.drawCircle(
      origin,
      ringRadius,
      Paint()
        ..color = _purple.withValues(alpha: 0.30 * safeOpacity * (1 - progress))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    const particleCount = 10;

    for (var index = 0; index < particleCount; index++) {
      final angle = -math.pi / 2 + index * math.pi * 2 / particleCount;

      final distance = 18 + (42 + (index.isEven ? 8 : 0)) * progress;

      final point = Offset(
        origin.dx + math.cos(angle) * distance,
        origin.dy + math.sin(angle) * distance,
      );

      final particleSize = (index.isEven ? 3.1 : 2.3) * (1 - 0.35 * progress);

      final color = index.isEven ? _purple : _cyan;

      canvas.drawCircle(
        point,
        particleSize,
        Paint()
          ..color = color.withValues(
            alpha: safeOpacity * (1 - 0.24 * progress),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LikeParticlePainter oldDelegate) {
    return oldDelegate.origin != origin ||
        oldDelegate.progress != progress ||
        oldDelegate.opacity != opacity;
  }
}

double _interval(double value, double start, double end) {
  if (end <= start) {
    return value >= end ? 1 : 0;
  }

  return ((value - start) / (end - start)).clamp(0.0, 1.0).toDouble();
}

String compactSignalCount(int value) {
  if (value >= 1000000000) {
    return _compactCount(value: value, divisor: 1000000000, suffix: 'B');
  }

  if (value >= 1000000) {
    return _compactCount(value: value, divisor: 1000000, suffix: 'M');
  }

  if (value >= 1000) {
    return _compactCount(value: value, divisor: 1000, suffix: 'K');
  }

  return value.toString();
}

String _compactCount({
  required int value,
  required int divisor,
  required String suffix,
}) {
  final compactValue = value / divisor;

  final formatted = compactValue >= 10
      ? compactValue.toStringAsFixed(0)
      : compactValue.toStringAsFixed(1);

  final cleaned = formatted.endsWith('.0')
      ? formatted.substring(0, formatted.length - 2)
      : formatted;

  return '$cleaned$suffix';
}
