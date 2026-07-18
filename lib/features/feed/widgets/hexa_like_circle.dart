import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/hexa_theme.dart';

class HexaLikeCircle extends StatefulWidget {
  const HexaLikeCircle({
    required this.isLiked,
    required this.onTap,
    this.size = 48,
    super.key,
  });

  final bool isLiked;
  final VoidCallback onTap;
  final double size;

  @override
  State<HexaLikeCircle> createState() {
    return _HexaLikeCircleState();
  }
}

class _HexaLikeCircleState extends State<HexaLikeCircle>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;

  late final AnimationController _breatheController;

  late final AnimationController _burstController;

  final math.Random _random = math.Random();

  List<_HexaParticle> _particles = const <_HexaParticle>[];

  bool _pressed = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final reduceMotion = HexaMotion.reduceMotionOf(context);

    if (_reduceMotion == reduceMotion &&
        (_rotationController.isAnimating || reduceMotion)) {
      return;
    }

    _reduceMotion = reduceMotion;

    if (_reduceMotion) {
      _rotationController
        ..stop()
        ..value = 0.08;

      _breatheController
        ..stop()
        ..value = 0.5;

      return;
    }

    if (!_rotationController.isAnimating) {
      _rotationController.repeat();
    }

    if (!_breatheController.isAnimating) {
      _breatheController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant HexaLikeCircle oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isLiked && widget.isLiked) {
      _triggerBurst();
    }
  }

  void _triggerBurst() {
    if (_reduceMotion) {
      return;
    }

    final particles = List<_HexaParticle>.generate(14, (index) {
      final baseAngle = math.pi * 2 * index / 14;

      return _HexaParticle(
        angle: baseAngle + (_random.nextDouble() - 0.5) * 0.28,
        distanceMultiplier: 0.72 + _random.nextDouble() * 0.46,
        size: 1.8 + _random.nextDouble() * 2.5,
        rotation: _random.nextDouble() * math.pi,
        isStar: index.isEven,
      );
    }, growable: false);

    setState(() {
      _particles = particles;
    });

    _burstController.forward(from: 0).whenComplete(() {
      if (!mounted) {
        return;
      }

      setState(() {
        _particles = const <_HexaParticle>[];
      });
    });
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _breatheController.dispose();
    _burstController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: widget.isLiked,
      label: widget.isLiked ? 'Hexa beğenisini kaldır' : 'Hexa beğenisi gönder',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          setState(() {
            _pressed = true;
          });
        },
        onTapCancel: () {
          setState(() {
            _pressed = false;
          });
        },
        onTapUp: (_) {
          setState(() {
            _pressed = false;
          });

          _handleTap();
        },
        child: AnimatedScale(
          scale: _pressed ? HexaMotion.pressScale : 1,
          duration: _reduceMotion ? Duration.zero : HexaMotion.fast,
          curve: HexaMotion.elastic,
          child: SizedBox.square(
            dimension: widget.size,
            child: AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[
                _rotationController,
                _breatheController,
                _burstController,
              ]),
              builder: (context, child) {
                return CustomPaint(
                  painter: _HexaLikePainter(
                    rotation: _rotationController.value * math.pi * 2,
                    breathe: _breatheController.value,
                    burst: _burstController.value,
                    isLiked: widget.isLiked,
                    particles: _particles,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HexaLikePainter extends CustomPainter {
  const _HexaLikePainter({
    required this.rotation,
    required this.breathe,
    required this.burst,
    required this.isLiked,
    required this.particles,
  });

  final double rotation;
  final double breathe;
  final double burst;
  final bool isLiked;
  final List<_HexaParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    final outerRadius = size.shortestSide * 0.39;

    final breatheScale = 0.92 + breathe * 0.09;

    final coreRadius = size.shortestSide * 0.205 * breatheScale;

    _drawOuterEnergy(canvas: canvas, center: center, radius: outerRadius);

    _drawCore(canvas: canvas, center: center, radius: coreRadius);

    if (isLiked) {
      _drawSpark(canvas: canvas, center: center, radius: coreRadius * 0.72);
    }

    if (particles.isNotEmpty) {
      _drawParticles(canvas: canvas, center: center, baseRadius: outerRadius);
    }
  }

  void _drawOuterEnergy({
    required Canvas canvas,
    required Offset center,
    required double radius,
  }) {
    final activeColor = isLiked ? HexaColors.hopePink : HexaColors.white;

    final path = _hexagonPath(
      center: center,
      radius: radius,
      rotation: rotation,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = activeColor.withAlpha(isLiked ? 42 : 20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isLiked ? 8 : 5
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = activeColor.withAlpha(isLiked ? 205 : 150)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isLiked ? 1.8 : 1.25
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var index = 0; index < 6; index++) {
      final angle = rotation + index * math.pi / 3;

      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );

      canvas.drawCircle(
        point,
        isLiked ? 1.65 : 1.1,
        Paint()..color = activeColor.withAlpha(isLiked ? 230 : 130),
      );
    }
  }

  void _drawCore({
    required Canvas canvas,
    required Offset center,
    required double radius,
  }) {
    if (isLiked) {
      final glowRect = Rect.fromCircle(center: center, radius: radius * 1.65);

      canvas.drawCircle(
        center,
        radius * 1.65,
        Paint()
          ..shader = const RadialGradient(
            colors: <Color>[
              Color(0x88A42E42),
              Color(0x44FB9BBD),
              HexaColors.transparent,
            ],
          ).createShader(glowRect),
      );

      final coreRect = Rect.fromCircle(center: center, radius: radius);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = const RadialGradient(
            colors: <Color>[
              HexaColors.hopePink,
              HexaColors.error,
              HexaColors.horizon,
            ],
            stops: <double>[0, 0.58, 1],
          ).createShader(coreRect),
      );

      return;
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = HexaColors.white.withAlpha(18)
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = HexaColors.white.withAlpha(190)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  void _drawSpark({
    required Canvas canvas,
    required Offset center,
    required double radius,
  }) {
    final path = Path()
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

    canvas.drawPath(path, Paint()..color = HexaColors.white);
  }

  void _drawParticles({
    required Canvas canvas,
    required Offset center,
    required double baseRadius,
  }) {
    final eased = Curves.easeOutCubic.transform(burst.clamp(0, 1));

    final opacity = (1 - burst).clamp(0, 1);

    for (final particle in particles) {
      final distance =
          baseRadius +
          sizeDistance(baseRadius, eased, particle.distanceMultiplier);

      final point = Offset(
        center.dx + math.cos(particle.angle) * distance,
        center.dy + math.sin(particle.angle) * distance,
      );

      final particleSize = particle.size * (1 - burst * 0.35);

      final color = HexaColors.warning.withAlpha((opacity * 255).round());

      if (particle.isStar) {
        canvas.save();
        canvas.translate(point.dx, point.dy);
        canvas.rotate(particle.rotation + burst * math.pi);

        canvas.drawPath(_miniStarPath(particleSize), Paint()..color = color);

        canvas.restore();
      } else {
        canvas.drawCircle(point, particleSize, Paint()..color = color);
      }
    }
  }

  double sizeDistance(double radius, double progress, double multiplier) {
    return radius * 0.85 * progress * multiplier;
  }

  Path _hexagonPath({
    required Offset center,
    required double radius,
    required double rotation,
  }) {
    final path = Path();

    for (var index = 0; index < 6; index++) {
      final angle = rotation + index * math.pi / 3 - math.pi / 2;

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

  Path _miniStarPath(double radius) {
    return Path()
      ..moveTo(0, -radius)
      ..lineTo(radius * 0.28, -radius * 0.28)
      ..lineTo(radius, 0)
      ..lineTo(radius * 0.28, radius * 0.28)
      ..lineTo(0, radius)
      ..lineTo(-radius * 0.28, radius * 0.28)
      ..lineTo(-radius, 0)
      ..lineTo(-radius * 0.28, -radius * 0.28)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _HexaLikePainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.breathe != breathe ||
        oldDelegate.burst != burst ||
        oldDelegate.isLiked != isLiked ||
        oldDelegate.particles != particles;
  }
}

class _HexaParticle {
  const _HexaParticle({
    required this.angle,
    required this.distanceMultiplier,
    required this.size,
    required this.rotation,
    required this.isStar,
  });

  final double angle;
  final double distanceMultiplier;
  final double size;
  final double rotation;
  final bool isStar;
}
