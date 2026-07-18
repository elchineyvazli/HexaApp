import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/hexa_theme.dart';
import 'video_upload_limits.dart';

class UploadVideoPreview extends StatefulWidget {
  const UploadVideoPreview({
    required this.videoFile,
    required this.onPickVideo,
    super.key,
  });

  final File? videoFile;
  final VoidCallback onPickVideo;

  @override
  State<UploadVideoPreview> createState() {
    return _UploadVideoPreviewState();
  }
}

class _UploadVideoPreviewState extends State<UploadVideoPreview>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;

  Timer? _playbackSignalTimer;

  bool _isInitializing = false;
  bool _hasInitializationError = false;
  bool _showPlaybackSignal = false;
  bool _resumeAfterLifecycle = false;

  int _controllerGeneration = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    unawaited(_replaceController(widget.videoFile));
  }

  @override
  void didUpdateWidget(covariant UploadVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.videoFile?.path != widget.videoFile?.path) {
      unawaited(_replaceController(widget.videoFile));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        if (_resumeAfterLifecycle) {
          _resumeAfterLifecycle = false;
          unawaited(controller.play());
        }

      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _resumeAfterLifecycle = controller.value.isPlaying;

        if (controller.value.isPlaying) {
          unawaited(controller.pause());
        }
    }
  }

  Future<void> _replaceController(File? file) async {
    final generation = ++_controllerGeneration;
    final previousController = _controller;

    _playbackSignalTimer?.cancel();

    if (mounted) {
      setState(() {
        _controller = null;
        _isInitializing = file != null;
        _hasInitializationError = false;
        _showPlaybackSignal = false;
      });
    }

    if (previousController != null) {
      await previousController.dispose();
    }

    if (file == null || !mounted || generation != _controllerGeneration) {
      return;
    }

    final controller = VideoPlayerController.file(file);

    try {
      await controller.initialize().timeout(
        VideoUploadLimits.metadataReadTimeout,
      );

      if (!mounted || generation != _controllerGeneration) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();

      if (!mounted || generation != _controllerGeneration) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } catch (_) {
      await controller.dispose();

      if (!mounted || generation != _controllerGeneration) {
        return;
      }

      setState(() {
        _isInitializing = false;
        _hasInitializationError = true;
      });
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }

    if (!mounted) {
      return;
    }

    _playbackSignalTimer?.cancel();

    setState(() {
      _showPlaybackSignal = true;
    });

    _playbackSignalTimer = Timer(HexaMotion.breathe, () {
      if (!mounted) {
        return;
      }

      setState(() {
        _showPlaybackSignal = false;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _controllerGeneration++;
    _playbackSignalTimer?.cancel();

    final controller = _controller;
    _controller = null;

    if (controller != null) {
      unawaited(controller.dispose());
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    final screenHeight = MediaQuery.sizeOf(context).height;

    final previewHeight = (screenHeight * 0.48).clamp(300.0, 500.0);

    return RepaintBoundary(
      child: Container(
        height: previewHeight,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: HexaRadius.borderLg,
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: HexaShadows.soft,
        ),
        child: ClipRRect(
          borderRadius: HexaRadius.borderLg,
          child: AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : HexaMotion.normal,
            switchInCurve: HexaMotion.enter,
            switchOutCurve: HexaMotion.exit,
            transitionBuilder: (child, animation) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: HexaMotion.enter,
              );

              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: HexaMotion.pageEnterOffset,
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              );
            },
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.videoFile == null) {
      return _EmptyVideoPreview(
        key: const ValueKey<String>('empty'),
        onTap: widget.onPickVideo,
      );
    }

    if (_hasInitializationError) {
      return _PreviewError(
        key: const ValueKey<String>('error'),
        onTap: widget.onPickVideo,
      );
    }

    final controller = _controller;

    if (_isInitializing ||
        controller == null ||
        !controller.value.isInitialized) {
      return const _PreviewLoading(key: ValueKey<String>('loading'));
    }

    return _SelectedVideoPreview(
      key: ValueKey<String>('selected-${widget.videoFile!.path}'),
      controller: controller,
      showPlaybackSignal: _showPlaybackSignal,
      onTogglePlayback: _togglePlayback,
      onChangeVideo: widget.onPickVideo,
    );
  }
}

class _EmptyVideoPreview extends StatelessWidget {
  const _EmptyVideoPreview({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _PressablePreviewSurface(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              theme.colorScheme.surface,
              HexaColors.surfaceWarm,
              HexaColors.lavenderSoft,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(HexaSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CustomPaint(
                  size: const Size.square(74),
                  painter: _PreviewHexPainter(
                    color: theme.colorScheme.primary,
                    phase: 0.08,
                  ),
                ),
                const SizedBox(height: HexaSpacing.lg),
                Text(
                  'Video seç',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: HexaSpacing.xs),
                Text(
                  'MP4 · MOV · M4V · WebM',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.9,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedVideoPreview extends StatelessWidget {
  const _SelectedVideoPreview({
    required this.controller,
    required this.showPlaybackSignal,
    required this.onTogglePlayback,
    required this.onChangeVideo,
    super.key,
  });

  final VideoPlayerController controller;
  final bool showPlaybackSignal;

  final VoidCallback onTogglePlayback;
  final VoidCallback onChangeVideo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTogglePlayback,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ColoredBox(
            color: HexaColors.earth,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(gradient: HexaGradients.feedScrim),
          ),
          Positioned(
            top: HexaSpacing.sm,
            right: HexaSpacing.sm,
            child: _PreviewAction(
              tooltip: 'Videoyu değiştir',
              icon: Icons.swap_horiz_rounded,
              onTap: onChangeVideo,
            ),
          ),
          Center(
            child: AnimatedOpacity(
              opacity: showPlaybackSignal ? 1 : 0,
              duration: HexaMotion.fast,
              curve: HexaMotion.enter,
              child: AnimatedScale(
                scale: showPlaybackSignal ? 1 : 0.88,
                duration: HexaMotion.fast,
                curve: HexaMotion.elastic,
                child: Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: HexaColors.earth.withAlpha(165),
                    shape: BoxShape.circle,
                    border: Border.all(color: HexaColors.white.withAlpha(52)),
                  ),
                  child: Icon(
                    controller.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: HexaColors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 3,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: VideoProgressColors(
                  playedColor: theme.colorScheme.primary,
                  bufferedColor: HexaColors.white.withAlpha(70),
                  backgroundColor: HexaColors.white.withAlpha(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewLoading extends StatelessWidget {
  const _PreviewLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: const Center(child: _PreviewLoadingSignal()),
    );
  }
}

class _PreviewLoadingSignal extends StatefulWidget {
  const _PreviewLoadingSignal();

  @override
  State<_PreviewLoadingSignal> createState() {
    return _PreviewLoadingSignalState();
  }
}

class _PreviewLoadingSignalState extends State<_PreviewLoadingSignal>
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
    final color = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size.square(74),
          painter: _PreviewHexPainter(color: color, phase: _controller.value),
        );
      },
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _PressablePreviewSurface(
      onTap: onTap,
      child: ColoredBox(
        color: theme.colorScheme.surface,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(HexaSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.broken_image_outlined,
                  color: theme.colorScheme.error,
                  size: 34,
                ),
                const SizedBox(height: HexaSpacing.md),
                Text(
                  'Önizleme açılamadı',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: HexaSpacing.xs),
                Text(
                  'Başka bir video seçmek için dokun',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewAction extends StatefulWidget {
  const _PreviewAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_PreviewAction> createState() {
    return _PreviewActionState();
  }
}

class _PreviewActionState extends State<_PreviewAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    return Tooltip(
      message: widget.tooltip,
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
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? HexaMotion.pressScale : 1,
          duration: reduceMotion ? Duration.zero : HexaMotion.fast,
          curve: HexaMotion.elastic,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HexaColors.earth.withAlpha(150),
              shape: BoxShape.circle,
              border: Border.all(color: HexaColors.white.withAlpha(48)),
            ),
            child: Icon(widget.icon, color: HexaColors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _PressablePreviewSurface extends StatefulWidget {
  const _PressablePreviewSurface({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressablePreviewSurface> createState() {
    return _PressablePreviewSurfaceState();
  }
}

class _PressablePreviewSurfaceState extends State<_PressablePreviewSurface> {
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
        child: widget.child,
      ),
    );
  }
}

class _PreviewHexPainter extends CustomPainter {
  const _PreviewHexPainter({required this.color, required this.phase});

  final Color color;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.34;

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

    final glowPaint = Paint()
      ..color = color.withAlpha(36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawPath(path, glowPaint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(phase * math.pi * 2);
    canvas.translate(-center.dx, -center.dy);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
    canvas.restore();

    canvas.drawCircle(center, 3, Paint()..color = HexaColors.hopePink);
  }

  @override
  bool shouldRepaint(covariant _PreviewHexPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.phase != phase;
  }
}
