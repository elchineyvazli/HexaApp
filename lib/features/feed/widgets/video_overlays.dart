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
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 220),
          reverseDuration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 160),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.86, end: 1).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            );
          },
          child: icon == null
              ? const SizedBox.shrink(
                  key: ValueKey<String>('empty-playback-indicator'),
                )
              : Container(
                  key: ValueKey<IconData>(icon!),
                  width: 66,
                  height: 66,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0x99050507),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x52000000),
                        blurRadius: 22,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white.withValues(alpha: 0.94),
                    size: 30,
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

    return Positioned(
      left: 16,
      right: 82,
      bottom: MediaQuery.paddingOf(context).bottom + 18,
      child: IgnorePointer(
        child: Text(
          caption,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xF2FFFFFF),
            fontSize: 14,
            height: 1.38,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.14,
            shadows: <Shadow>[
              Shadow(
                color: Color(0xE6000000),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Eski VideoBottomControls kullanımları için korunan minimal sürüm.
///
/// Feed'in ana görünümünde yalnızca kullanıcı etkileşiminden sonra kısa
/// süreli gösterilmelidir.
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
      left: 12,
      right: 12,
      bottom: 5,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Row(
          children: <Widget>[
            _OverlayMuteButton(isMuted: isMuted, onTap: onToggleMute),
            const SizedBox(width: 10),
            Expanded(
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 12),
                colors: const VideoProgressColors(
                  playedColor: Color(0xFF8B5CF6),
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

  bool _reduceMotion = false;

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

    final nextReduceMotion = HexaMotion.reduceMotionOf(context);

    if (_reduceMotion == nextReduceMotion &&
        (_controller.isAnimating || nextReduceMotion)) {
      return;
    }

    _reduceMotion = nextReduceMotion;

    if (_reduceMotion) {
      _controller
        ..stop()
        ..value = 0.18;
    } else {
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
    final size = widget.compact ? 28.0 : 42.0;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size.square(size),
            painter: _LoadingArcPainter(
              phase: _controller.value,
              strokeWidth: widget.compact ? 2 : 2.4,
            ),
          );
        },
      ),
    );
  }
}

class VideoErrorView extends StatelessWidget {
  const VideoErrorView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    return ColoredBox(
      color: const Color(0xB8050507),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 38),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.videocam_off_outlined,
                color: Colors.white.withValues(alpha: 0.62),
                size: 31,
              ),
              const SizedBox(height: 14),
              Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xDFFFFFFF),
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.12,
                ),
              ),
              const SizedBox(height: 17),
              Semantics(
                button: true,
                label: 'Videoyu tekrar yükle',
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.07),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 11,
                    ),
                    shape: const StadiumBorder(),
                    animationDuration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 160),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Tekrar dene',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.08,
                    ),
                  ),
                ),
              ),
            ],
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0x52050507),
              Color(0x00050507),
              Color(0x00050507),
              Color(0x8F050507),
            ],
            stops: <double>[0, 0.18, 0.66, 1],
          ),
        ),
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

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    return Semantics(
      button: true,
      label: widget.isMuted ? 'Videonun sesini aç' : 'Videonun sesini kapat',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          _setPressed(true);
        },
        onTapCancel: () {
          _setPressed(false);
        },
        onTapUp: (_) {
          _setPressed(false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.88 : 1,
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x8F050507),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Icon(
              widget.isMuted
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
              color: Colors.white.withValues(alpha: 0.86),
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingArcPainter extends CustomPainter {
  const _LoadingArcPainter({required this.phase, required this.strokeWidth});

  final double phase;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    final radius = (size.shortestSide - strokeWidth) / 2;

    final bounds = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    final startAngle = -math.pi / 2 + math.pi * 2 * phase;

    const sweepAngle = math.pi * 1.35;

    final activePaint = Paint()
      ..shader = const SweepGradient(
        colors: <Color>[
          Color(0xFF8B5CF6),
          Color(0xFF06B6D4),
          Color(0xFF8B5CF6),
        ],
      ).createShader(bounds)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(bounds, startAngle, sweepAngle, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant _LoadingArcPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.strokeWidth != strokeWidth;
  }
}
