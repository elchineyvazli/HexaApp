import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/hexa_theme.dart';

class VideoSurface extends StatelessWidget {
  const VideoSurface({
    required this.controller,
    required this.isInitialized,
    required this.thumbnailUrl,
    required this.metadataAspectRatio,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    super.key,
  });

  final VideoPlayerController? controller;
  final bool isInitialized;
  final String thumbnailUrl;
  final double? metadataAspectRatio;

  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = HexaMotion.reduceMotionOf(context);
    final currentController = controller;

    final showVideo =
        isInitialized &&
        currentController != null &&
        currentController.value.isInitialized;

    final mediaKey = showVideo
        ? 'video-${currentController.dataSource}'
        : 'thumbnail-${thumbnailUrl.trim()}';

    return RepaintBoundary(
      child: ColoredBox(
        color: HexaColors.earth,
        child: ClipRect(
          child: AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : HexaMotion.normal,
            reverseDuration: reduceMotion ? Duration.zero : HexaMotion.fast,
            switchInCurve: HexaMotion.enter,
            switchOutCurve: HexaMotion.exit,
            transitionBuilder: (child, animation) {
              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: HexaMotion.enter,
                reverseCurve: HexaMotion.exit,
              );

              return FadeTransition(
                opacity: curvedAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.008),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                ),
              );
            },
            child: SizedBox.expand(
              key: ValueKey<String>(mediaKey),
              child: showVideo
                  ? _buildVideo(currentController)
                  : _buildThumbnail(context, reduceMotion: reduceMotion),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideo(VideoPlayerController currentController) {
    final mediaSize = _resolveMediaSize(currentController);

    return FittedBox(
      fit: fit,
      alignment: alignment,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: mediaSize.width,
        height: mediaSize.height,
        child: VideoPlayer(currentController),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, {required bool reduceMotion}) {
    final normalizedUrl = thumbnailUrl.trim();

    if (normalizedUrl.isEmpty) {
      return const _VideoPlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: normalizedUrl,
      width: double.infinity,
      height: double.infinity,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.medium,
      fadeInDuration: reduceMotion ? Duration.zero : HexaMotion.normal,
      fadeOutDuration: reduceMotion ? Duration.zero : HexaMotion.fast,
      placeholder: (_, __) {
        return const _VideoPlaceholder();
      },
      errorWidget: (_, __, ___) {
        return const _VideoPlaceholder(hasError: true);
      },
    );
  }

  Size _resolveMediaSize(VideoPlayerController currentController) {
    final runtimeSize = currentController.value.size;

    if (runtimeSize.width > 0 && runtimeSize.height > 0) {
      return runtimeSize;
    }

    const fallbackHeight = 1000.0;

    return Size(fallbackHeight * _resolveAspectRatio(), fallbackHeight);
  }

  double _resolveAspectRatio() {
    final currentController = controller;

    if (isInitialized && currentController != null) {
      final runtimeSize = currentController.value.size;

      if (runtimeSize.width > 0 && runtimeSize.height > 0) {
        final runtimeRatio = runtimeSize.width / runtimeSize.height;

        if (_isValidAspectRatio(runtimeRatio)) {
          return runtimeRatio;
        }
      }
    }

    final storedRatio = metadataAspectRatio;

    if (storedRatio != null && _isValidAspectRatio(storedRatio)) {
      return storedRatio;
    }

    return 9 / 16;
  }

  bool _isValidAspectRatio(double value) {
    return value.isFinite && value >= 0.2 && value <= 5;
  }
}

class _VideoPlaceholder extends StatefulWidget {
  const _VideoPlaceholder({this.hasError = false});

  final bool hasError;

  @override
  State<_VideoPlaceholder> createState() {
    return _VideoPlaceholderState();
  }
}

class _VideoPlaceholderState extends State<_VideoPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: HexaMotion.breathe * 4,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (HexaMotion.reduceMotionOf(context) || widget.hasError) {
      _controller
        ..stop()
        ..value = 0.12;
      return;
    }

    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _VideoPlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.hasError != widget.hasError) {
      if (widget.hasError) {
        _controller
          ..stop()
          ..value = 0.12;
      } else if (!HexaMotion.reduceMotionOf(context)) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: HexaColors.earth,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: const Size.square(72),
              painter: _MediaPlaceholderPainter(
                phase: _controller.value,
                hasError: widget.hasError,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MediaPlaceholderPainter extends CustomPainter {
  const _MediaPlaceholderPainter({required this.phase, required this.hasError});

  final double phase;
  final bool hasError;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.31;

    final glowPaint = Paint()
      ..color = (hasError ? HexaColors.error : HexaColors.signal).withAlpha(34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    final path = _hexagonPath(center: center, radius: radius);

    canvas.drawPath(path, glowPaint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(phase * math.pi * 2);
    canvas.translate(-center.dx, -center.dy);

    final linePaint = Paint()
      ..color = (hasError ? HexaColors.error : HexaColors.hopePink).withAlpha(
        hasError ? 170 : 115,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
    canvas.restore();

    canvas.drawCircle(
      center,
      2.8,
      Paint()..color = hasError ? HexaColors.error : HexaColors.hopePink,
    );
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
  bool shouldRepaint(covariant _MediaPlaceholderPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.hasError != hasError;
  }
}
