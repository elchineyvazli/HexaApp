import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/hexa_theme.dart';

class UploadHeader extends StatelessWidget {
  const UploadHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: reduceMotion ? 1 : 0, end: 1),
      duration: reduceMotion ? Duration.zero : HexaMotion.normal,
      curve: HexaMotion.enter,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HexaSpacing.xs,
          vertical: HexaSpacing.xs,
        ),
        child: Row(
          children: <Widget>[
            IconButton(
              tooltip: 'Geri dön',
              onPressed: () {
                Navigator.of(context).maybePop();
              },
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surface.withAlpha(180),
                foregroundColor: theme.colorScheme.onSurface,
              ),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: HexaSpacing.sm),
            Expanded(
              child: Text(
                'Yeni içerik',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Container(
              width: 54,
              height: 2,
              decoration: const BoxDecoration(
                gradient: HexaGradients.navIndicator,
                borderRadius: HexaRadius.borderPill,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UploadSection extends StatelessWidget {
  const UploadSection({
    required this.title,
    required this.description,
    required this.icon,
    required this.child,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: reduceMotion ? 1 : 0, end: 1),
      duration: reduceMotion ? Duration.zero : HexaMotion.slow,
      curve: HexaMotion.listEnter,
      builder: (context, value, content) {
        final visible = value.clamp(0, 1).toDouble();

        return Opacity(
          opacity: visible,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - visible)),
            child: content,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: HexaSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, size: 18, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: HexaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (description.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: HexaSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class BusyUploadView extends StatefulWidget {
  const BusyUploadView({
    required this.message,
    required this.icon,
    this.progress,
    super.key,
  });

  final String message;
  final IconData icon;
  final double? progress;

  @override
  State<BusyUploadView> createState() {
    return _BusyUploadViewState();
  }
}

class _BusyUploadViewState extends State<BusyUploadView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _energyController;

  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();

    _energyController = AnimationController(
      vsync: this,
      duration: HexaMotion.breathe * 3,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final reduceMotion = HexaMotion.reduceMotionOf(context);

    if (reduceMotion == _reduceMotion &&
        (_energyController.isAnimating || reduceMotion)) {
      return;
    }

    _reduceMotion = reduceMotion;

    if (_reduceMotion) {
      _energyController
        ..stop()
        ..value = 0.15;
    } else {
      _energyController.repeat();
    }
  }

  @override
  void dispose() {
    _energyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final normalizedProgress = widget.progress?.clamp(0, 1).toDouble();

    final percentage = normalizedProgress == null
        ? null
        : (normalizedProgress * 100).round();

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: HexaGradients.pageFor(theme.brightness),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: HexaSpacing.pageInsets,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AnimatedBuilder(
                      animation: _energyController,
                      builder: (context, child) {
                        return SizedBox.square(
                          dimension: 132,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              CustomPaint(
                                size: const Size.square(132),
                                painter: _UploadOrbitPainter(
                                  phase: _energyController.value,
                                  progress: normalizedProgress,
                                  activeColor: theme.colorScheme.primary,
                                  inactiveColor:
                                      theme.colorScheme.outlineVariant,
                                ),
                              ),
                              Icon(
                                widget.icon,
                                size: 30,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: HexaSpacing.xl),
                    AnimatedSwitcher(
                      duration: _reduceMotion
                          ? Duration.zero
                          : HexaMotion.normal,
                      switchInCurve: HexaMotion.enter,
                      switchOutCurve: HexaMotion.exit,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: HexaMotion.pageEnterOffset,
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        widget.message,
                        key: ValueKey<String>(widget.message),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: HexaSpacing.sm),
                    Text(
                      percentage == null
                          ? 'İçerik güvenli biçimde hazırlanıyor'
                          : '%$percentage',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: percentage == null
                            ? FontWeight.w500
                            : FontWeight.w800,
                        letterSpacing: percentage == null ? 0.1 : 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadOrbitPainter extends CustomPainter {
  const _UploadOrbitPainter({
    required this.phase,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  final double phase;
  final double? progress;
  final Color activeColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.37;

    final path = _hexagonPath(center: center, radius: radius);

    final glowPaint = Paint()
      ..color = activeColor.withAlpha(34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, glowPaint);

    final basePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, basePaint);

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final metrics = path.computeMetrics().toList();

    if (metrics.isEmpty) {
      return;
    }

    final metric = metrics.first;

    if (progress != null) {
      final length = metric.length * progress!.clamp(0, 1);

      canvas.drawPath(metric.extractPath(0, length), activePaint);
    } else {
      final segment = metric.extractPath(0, metric.length * 0.24);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(phase * math.pi * 2);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawPath(segment, activePaint);
      canvas.restore();
    }
  }

  Path _hexagonPath({required Offset center, required double radius}) {
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
  bool shouldRepaint(covariant _UploadOrbitPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
