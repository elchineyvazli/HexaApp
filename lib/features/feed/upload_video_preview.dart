import 'dart:async';
import 'dart:io';

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

    _playbackSignalTimer = Timer(const Duration(milliseconds: 620), () {
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
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    final screenHeight = MediaQuery.sizeOf(context).height;

    final previewHeight = (screenHeight * 0.47).clamp(300.0, 520.0).toDouble();

    final borderRadius = BorderRadius.circular(24);

    return RepaintBoundary(
      child: Container(
        height: previewHeight,
        decoration: BoxDecoration(
          color: HexaColors.surfaceDark,
          borderRadius: borderRadius,
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 220),
            reverseDuration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 140),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
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
        key: const ValueKey<String>('empty-video-preview'),
        onTap: widget.onPickVideo,
      );
    }

    if (_hasInitializationError) {
      return _PreviewError(
        key: const ValueKey<String>('video-preview-error'),
        onTap: widget.onPickVideo,
      );
    }

    final controller = _controller;

    if (_isInitializing ||
        controller == null ||
        !controller.value.isInitialized) {
      return const _PreviewLoading(
        key: ValueKey<String>('video-preview-loading'),
      );
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
    return _PressablePreviewSurface(
      onTap: onTap,
      semanticLabel: 'Galeriden video seç',
      child: ColoredBox(
        color: HexaColors.surfaceDark,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: HexaColors.purple.withOpacity(0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: HexaColors.purple.withOpacity(0.24),
                    ),
                  ),
                  child: Icon(
                    Icons.video_library_outlined,
                    color: HexaColors.purpleSoft,
                    size: 27,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Galeriden video seç',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xF2FFFFFF),
                    fontSize: 17,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.30,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'MP4, MOV, M4V veya WebM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0x70FFFFFF),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.04,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: const Text(
                    'Video seç',
                    style: TextStyle(
                      color: Color(0xDFFFFFFF),
                      fontSize: 12,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.06,
                    ),
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
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTogglePlayback,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ColoredBox(
            color: HexaColors.backgroundDark,
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0x52050507),
                    Color(0x00050507),
                    Color(0x00050507),
                    Color(0x73050507),
                  ],
                  stops: <double>[0, 0.20, 0.72, 1],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: _PreviewAction(
              tooltip: 'Videoyu değiştir',
              icon: Icons.swap_horiz_rounded,
              onTap: onChangeVideo,
            ),
          ),
          IgnorePointer(
            child: Center(
              child: AnimatedOpacity(
                opacity: showPlaybackSignal ? 1 : 0,
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                child: AnimatedScale(
                  scale: showPlaybackSignal ? 1 : 0.88,
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xA6050507),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Icon(
                      controller.value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white.withOpacity(0.94),
                      size: 29,
                    ),
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
                  playedColor: HexaColors.purple,
                  bufferedColor: Colors.white.withOpacity(0.26),
                  backgroundColor: Colors.white.withOpacity(0.10),
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
    return ColoredBox(
      color: HexaColors.backgroundDark,
      child: Center(
        child: Semantics(
          label: 'Video önizlemesi hazırlanıyor',
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.1,
                  color: HexaColors.purple,
                  backgroundColor: Color(0x1AFFFFFF),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Önizleme hazırlanıyor',
                style: TextStyle(
                  color: Color(0x70FFFFFF),
                  fontSize: 12.5,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.06,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressablePreviewSurface(
      onTap: onTap,
      semanticLabel: 'Önizleme açılamadı. Başka video seç.',
      child: ColoredBox(
        color: HexaColors.backgroundDark,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.videocam_off_outlined,
                  color: Colors.white.withOpacity(0.34),
                  size: 31,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Önizleme açılamadı',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xEFFFFFFF),
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.26,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Başka bir video seçmek için dokun.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0x70FFFFFF),
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.06,
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
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
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
                : const Duration(milliseconds: 130),
            curve: Curves.easeOutCubic,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0x99050507),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.11)),
              ),
              child: Icon(
                widget.icon,
                color: Colors.white.withOpacity(0.90),
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PressablePreviewSurface extends StatefulWidget {
  const _PressablePreviewSurface({
    required this.onTap,
    required this.semanticLabel,
    required this.child,
  });

  final VoidCallback onTap;
  final String semanticLabel;
  final Widget child;

  @override
  State<_PressablePreviewSurface> createState() {
    return _PressablePreviewSurfaceState();
  }
}

class _PressablePreviewSurfaceState extends State<_PressablePreviewSurface> {
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
      label: widget.semanticLabel,
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
          scale: _pressed ? 0.985 : 1,
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 130),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}
