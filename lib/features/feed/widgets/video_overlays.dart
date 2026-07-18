import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/hexa_theme.dart';
import '../feed_models.dart';

class VideoPlaybackIndicator extends StatelessWidget {
  const VideoPlaybackIndicator({required this.icon, super.key});

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    return IgnorePointer(
      child: Center(
        child: AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : HexaMotion.normal,
          reverseDuration: reduceMotion ? Duration.zero : HexaMotion.fast,
          switchInCurve: HexaMotion.elastic,
          switchOutCurve: HexaMotion.exit,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.82, end: 1).animate(animation),
                child: child,
              ),
            );
          },
          child: icon == null
              ? const SizedBox.shrink(key: ValueKey<String>('empty'))
              : ClipPath(
                  key: ValueKey<IconData>(icon!),
                  clipper: const _HexagonClipper(),
                  child: Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: HexaColors.earth.withAlpha(185),
                      boxShadow: HexaShadows.signal,
                    ),
                    child: Icon(icon, color: HexaColors.white, size: 32),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Normal Feed görünümünde kullanılmamalıdır.
///
/// Video detay veya uzun basma görünümünde yalnızca içeriğin açıklamasını
/// göstermek için korunur. Profil kimliği özellikle gösterilmez.
class VideoCaptionOverlay extends StatelessWidget {
  const VideoCaptionOverlay({required this.video, super.key});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    final caption = video.caption.trim();

    if (caption.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Positioned(
      left: HexaSpacing.md,
      right: 86,
      bottom: 54,
      child: IgnorePointer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 2,
              height: 34,
              margin: const EdgeInsets.only(top: 2),
              decoration: const BoxDecoration(
                gradient: HexaGradients.navIndicator,
                borderRadius: HexaRadius.borderPill,
              ),
            ),
            const SizedBox(width: HexaSpacing.sm),
            Expanded(
              child: Text(
                caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: HexaColors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  shadows: const <Shadow>[
                    Shadow(color: HexaColors.earth, blurRadius: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eski VideoBottomControls kullanımları için korunan minimal sürüm.
///
/// Feed'in yeni ana görünümünde bu kontrol yalnızca kullanıcı etkileşiminden
/// sonra kısa süreli gösterilmelidir.
class VideoBottomControls extends StatelessWidget {
  const VideoBottomControls({
    required this.controller,
    required this.isMuted,
    required this.onToggleMute,
    super.key,
  });

  final VideoPlayerController controller;
  final bool isMuted;
  final VoidCallback onToggleMute;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: HexaSpacing.sm,
      right: HexaSpacing.sm,
      bottom: HexaSpacing.xs,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Row(
          children: <Widget>[
            _OverlayMuteButton(isMuted: isMuted, onTap: onToggleMute),
            const SizedBox(width: HexaSpacing.sm),
            Expanded(
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: HexaSpacing.sm),
                colors: const VideoProgressColors(
                  playedColor: HexaColors.hopePink,
                  bufferedColor: Color(0x52FFFFFF),
                  backgroundColor: Color(0x24FFFFFF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoLoadingIndicator extends StatefulWidget {
  const VideoLoadingIndicator({this.compact = false, super.key});

  final bool compact;

  @override
  State<VideoLoadingIndicator> createState() {
    return _VideoLoadingIndicatorState();
  }
}

class _VideoLoadingIndicatorState extends State<VideoLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: HexaMotion.breathe * 3,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (HexaMotion.reduceMotionOf(context)) {
      _controller
        ..stop()
        ..value = 0.12;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 44.0 : 62.0;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size.square(size),
            painter: _LoadingHexPainter(
              phase: _controller.value,
              color: HexaColors.hopePink,
            ),
          );
        },
      ),
    );
  }
}

class VideoErrorView extends StatefulWidget {
  const VideoErrorView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  State<VideoErrorView> createState() {
    return _VideoErrorViewState();
  }
}

class _VideoErrorViewState extends State<VideoErrorView> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    return Center(
      child: Semantics(
        button: true,
        label: 'Videoyu tekrar yükle',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            setState(() => _pressed = true);
          },
          onTapCancel: () {
            setState(() => _pressed = false);
          },
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onRetry();
          },
          child: AnimatedScale(
            scale: _pressed ? HexaMotion.pressScale : 1,
            duration: reduceMotion ? Duration.zero : HexaMotion.fast,
            curve: HexaMotion.elastic,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              margin: const EdgeInsets.symmetric(horizontal: HexaSpacing.xl),
              padding: const EdgeInsets.all(HexaSpacing.lg),
              decoration: BoxDecoration(
                color: HexaColors.earth.withAlpha(205),
                borderRadius: HexaRadius.borderLg,
                border: Border.all(color: HexaColors.white.withAlpha(34)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.refresh_rounded,
                    color: HexaColors.hopePink,
                    size: 28,
                  ),
                  const SizedBox(height: HexaSpacing.sm),
                  Text(
                    widget.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: HexaColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: HexaSpacing.xs),
                  Text(
                    'Tekrar denemek için dokun',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: HexaColors.white.withAlpha(155),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VideoReadabilityGradient extends StatelessWidget {
  const VideoReadabilityGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: HexaGradients.feedScrim),
      ),
    );
  }
}

class VideoWatchTimer {
  static const int _maximumTrackedMs = 24 * 60 * 60 * 1000;

  final Stopwatch _stopwatch = Stopwatch();

  int _committedMs = 0;

  bool get isActive => _stopwatch.isRunning;

  int get elapsedMs {
    final runningMs = _stopwatch.isRunning ? _stopwatch.elapsedMilliseconds : 0;

    return (_committedMs + runningMs).clamp(0, _maximumTrackedMs).toInt();
  }

  void setActive(bool active) {
    if (active) {
      if (!_stopwatch.isRunning) {
        _stopwatch.start();
      }

      return;
    }

    _commitRunningTime();
  }

  int snapshot({bool pause = false}) {
    if (pause) {
      _commitRunningTime();
    }

    return elapsedMs;
  }

  void reset() {
    _stopwatch
      ..stop()
      ..reset();

    _committedMs = 0;
  }

  void _commitRunningTime() {
    if (!_stopwatch.isRunning) {
      return;
    }

    _stopwatch.stop();

    _committedMs = (_committedMs + _stopwatch.elapsedMilliseconds)
        .clamp(0, _maximumTrackedMs)
        .toInt();

    _stopwatch.reset();
  }
}

class _OverlayMuteButton extends StatefulWidget {
  const _OverlayMuteButton({required this.isMuted, required this.onTap});

  final bool isMuted;
  final VoidCallback onTap;

  @override
  State<_OverlayMuteButton> createState() {
    return _OverlayMuteButtonState();
  }
}

class _OverlayMuteButtonState extends State<_OverlayMuteButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() => _pressed = true);
      },
      onTapCancel: () {
        setState(() => _pressed = false);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? HexaMotion.pressScale : 1,
        duration: reduceMotion ? Duration.zero : HexaMotion.fast,
        curve: HexaMotion.elastic,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: HexaColors.earth.withAlpha(135),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            color: HexaColors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _HexagonClipper extends CustomClipper<Path> {
  const _HexagonClipper();

  @override
  Path getClip(Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
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
  bool shouldReclip(covariant _HexagonClipper oldClipper) {
    return false;
  }
}

class _LoadingHexPainter extends CustomPainter {
  const _LoadingHexPainter({required this.phase, required this.color});

  final double phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.35;

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

    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = HexaColors.white.withAlpha(28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final metrics = path.computeMetrics().toList();

    if (metrics.isEmpty) {
      return;
    }

    final metric = metrics.first;
    final segmentLength = metric.length * 0.28;
    final start = metric.length * phase;
    final end = start + segmentLength;

    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    if (end <= metric.length) {
      canvas.drawPath(metric.extractPath(start, end), activePaint);
    } else {
      canvas.drawPath(metric.extractPath(start, metric.length), activePaint);
      canvas.drawPath(metric.extractPath(0, end - metric.length), activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LoadingHexPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.color != color;
  }
}
