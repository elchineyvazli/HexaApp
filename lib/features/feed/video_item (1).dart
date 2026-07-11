// lib/features/feed/video_item.dart

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexa/core/theme/hexa_theme.dart';
import 'package:video_player/video_player.dart';

import 'feed_models.dart';
import 'video_action_buttons.dart';

final feedMutedProvider = StateProvider<bool>((ref) => false);

class VideoItem extends ConsumerStatefulWidget {
  const VideoItem({
    super.key,
    required this.video,
    required this.isActive,
    this.shouldPreload = true,
  });

  final VideoModel video;
  final bool isActive;
  final bool shouldPreload;

  @override
  ConsumerState<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends ConsumerState<VideoItem>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  Timer? _centerIconTimer;

  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isBuffering = false;
  bool _userPaused = false;
  bool _appIsActive = true;
  String? _errorMessage;
  IconData? _centerIcon;
  int _loadToken = 0;

  final Stopwatch _watchStopwatch = Stopwatch();
  int _committedWatchMs = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.shouldPreload) {
      _ensureController();
    }
  }

  @override
  void didUpdateWidget(covariant VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.video.playbackUrl != widget.video.playbackUrl) {
      _releaseController(notify: false);
      _userPaused = false;
      _committedWatchMs = 0;
      if (widget.shouldPreload) {
        _ensureController();
      }
      return;
    }

    if (oldWidget.shouldPreload != widget.shouldPreload) {
      if (widget.shouldPreload) {
        _ensureController();
      } else {
        _releaseController();
      }
    }

    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _userPaused = false;
      }
      _syncPlayback();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appIsActive = state == AppLifecycleState.resumed;
    _syncPlayback();
  }

  Future<void> _ensureController() async {
    if (_controller != null || !widget.shouldPreload) {
      return;
    }

    final source = widget.video.playbackUrl.trim();
    final uri = Uri.tryParse(source);
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialized = false;
          _errorMessage = 'Video bağlantısı geçerli değil.';
        });
      }
      return;
    }

    final token = ++_loadToken;
    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;
    controller.addListener(_handleControllerValue);

    if (mounted) {
      setState(() {
        _isLoading = true;
        _isInitialized = false;
        _errorMessage = null;
      });
    }

    try {
      await controller.initialize();
      if (!mounted || token != _loadToken || _controller != controller) {
        controller.removeListener(_handleControllerValue);
        await controller.dispose();
        return;
      }

      await controller.setLooping(true);
      await controller.setVolume(ref.read(feedMutedProvider) ? 0 : 1);
      if (!mounted || token != _loadToken || _controller != controller) {
        controller.removeListener(_handleControllerValue);
        await controller.dispose();
        return;
      }

      setState(() {
        _isLoading = false;
        _isInitialized = true;
        _isBuffering = controller.value.isBuffering;
      });
      _syncPlayback();
    } catch (_) {
      if (!mounted || token != _loadToken) {
        return;
      }

      controller.removeListener(_handleControllerValue);
      await controller.dispose();
      if (_controller == controller) {
        _controller = null;
      }

      setState(() {
        _isLoading = false;
        _isInitialized = false;
        _isBuffering = false;
        _errorMessage = 'Video şu anda yüklenemiyor.';
      });
      _updateWatchTracking(false);
    }
  }

  void _releaseController({bool notify = true}) {
    ++_loadToken;
    _centerIconTimer?.cancel();
    _updateWatchTracking(false);

    final controller = _controller;
    _controller = null;
    if (controller != null) {
      controller.removeListener(_handleControllerValue);
      controller.pause();
      controller.dispose();
    }

    _isInitialized = false;
    _isLoading = false;
    _isBuffering = false;
    _errorMessage = null;
    _centerIcon = null;

    if (notify && mounted) {
      setState(() {});
    }
  }

  void _handleControllerValue() {
    final controller = _controller;
    if (!mounted || controller == null) {
      return;
    }

    final value = controller.value;
    final nextBuffering = value.isBuffering;
    final nextError = value.hasError
        ? 'Video oynatılırken bir sorun oluştu.'
        : null;

    if (nextBuffering != _isBuffering || nextError != _errorMessage) {
      setState(() {
        _isBuffering = nextBuffering;
        if (nextError != null) {
          _errorMessage = nextError;
        }
      });
    }

    _updateWatchTracking(
      widget.isActive &&
          _appIsActive &&
          value.isPlaying &&
          !value.isBuffering &&
          !value.hasError,
    );
  }

  void _syncPlayback() {
    final controller = _controller;
    if (controller == null || !_isInitialized) {
      _updateWatchTracking(false);
      return;
    }

    final shouldPlay =
        widget.isActive && _appIsActive && !_userPaused && _errorMessage == null;

    if (shouldPlay) {
      if (!controller.value.isPlaying) {
        controller.play();
      }
    } else {
      if (controller.value.isPlaying) {
        controller.pause();
      }
      _updateWatchTracking(false);
    }
  }

  void _togglePlayback() {
    if (!_isInitialized || _controller == null) {
      if (_errorMessage != null) {
        _retry();
      }
      return;
    }

    _userPaused = !_userPaused;
    _syncPlayback();
    HapticFeedback.selectionClick();

    setState(() {
      _centerIcon = _userPaused
          ? Icons.play_arrow_rounded
          : Icons.pause_rounded;
    });

    _centerIconTimer?.cancel();
    _centerIconTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _centerIcon = null);
      }
    });
  }

  void _toggleMute() {
    final notifier = ref.read(feedMutedProvider.notifier);
    notifier.state = !notifier.state;
    HapticFeedback.selectionClick();
  }

  void _retry() {
    _releaseController();
    _ensureController();
  }

  void _updateWatchTracking(bool shouldTrack) {
    if (shouldTrack) {
      if (!_watchStopwatch.isRunning) {
        _watchStopwatch.start();
      }
      return;
    }

    if (_watchStopwatch.isRunning) {
      _watchStopwatch.stop();
      _committedWatchMs += _watchStopwatch.elapsedMilliseconds;
      _watchStopwatch.reset();
    }
  }

  int _qualifiedWatchMs() {
    final total = _committedWatchMs + _watchStopwatch.elapsedMilliseconds;
    return total.clamp(0, 24 * 60 * 60 * 1000).toInt();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _centerIconTimer?.cancel();
    _releaseController(notify: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMuted = ref.watch(feedMutedProvider);

    ref.listen<bool>(feedMutedProvider, (previous, next) {
      _controller?.setVolume(next ? 0 : 1);
    });

    return Semantics(
      label: '${widget.video.creatorName} tarafından paylaşılan video',
      hint: 'Oynatmak veya durdurmak için iki kez değil, bir kez dokun',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _togglePlayback,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildVideoSurface(),
            const _ReadabilityGradient(),
            if (_isLoading && !_isInitialized)
              const Center(child: _VideoLoadingIndicator()),
            if (_isBuffering && _isInitialized && widget.isActive)
              const Center(child: _VideoLoadingIndicator(compact: true)),
            if (_errorMessage != null && !_isInitialized)
              _VideoErrorView(
                message: _errorMessage!,
                onRetry: _retry,
              ),
            _buildCenterPlaybackIcon(),
            _buildCaption(),
            VideoActionButtons(
              video: widget.video,
              qualifiedWatchMsProvider: _qualifiedWatchMs,
            ),
            if (_isInitialized && _controller != null)
              _VideoBottomControls(
                controller: _controller!,
                isMuted: isMuted,
                onToggleMute: _toggleMute,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSurface() {
    final controller = _controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final runtimeAspectRatio = _controllerAspectRatio(controller);
        final aspectRatio =
            runtimeAspectRatio ?? widget.video.aspectRatio ?? (9 / 16);
        final geometry = _VideoSurfaceGeometry.resolve(
          constraints: constraints,
          aspectRatio: aspectRatio,
        );

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _HopeVideoBackdrop(
                thumbnailUrl: widget.video.thumbnailUrl,
              ),
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  width: geometry.width,
                  height: geometry.height,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F1713),
                    borderRadius: BorderRadius.circular(geometry.borderRadius),
                    border: geometry.isFullBleed
                        ? null
                        : Border.all(
                            color: const Color(0x40FFFFFF),
                            width: 0.8,
                          ),
                    boxShadow: geometry.isFullBleed
                        ? const <BoxShadow>[]
                        : const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 34,
                              spreadRadius: 2,
                              offset: Offset(0, 14),
                            ),
                          ],
                  ),
                  child: _buildForegroundMedia(controller),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildForegroundMedia(VideoPlayerController? controller) {
    if (_isInitialized && controller != null) {
      final size = controller.value.size;
      if (size.width > 0 && size.height > 0) {
        return FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: VideoPlayer(controller),
          ),
        );
      }
    }

    final thumbnailUrl = widget.video.thumbnailUrl.trim();
    if (thumbnailUrl.isNotEmpty) {
      return Image.network(
        thumbnailUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const _HopeVideoPlaceholder();
        },
      );
    }

    return const _HopeVideoPlaceholder();
  }

  double? _controllerAspectRatio(VideoPlayerController? controller) {
    if (!_isInitialized || controller == null) {
      return null;
    }

    final size = controller.value.size;
    if (size.width <= 0 || size.height <= 0) {
      return null;
    }

    final ratio = size.width / size.height;
    if (!ratio.isFinite || ratio < 0.2 || ratio > 5) {
      return null;
    }

    return ratio;
  }

  Widget _buildCenterPlaybackIcon() {
    return IgnorePointer(
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: _centerIcon == null
              ? const SizedBox.shrink(key: ValueKey<String>('empty'))
              : Container(
                  key: ValueKey<IconData>(_centerIcon!),
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: const Color(0xCC141C21),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x33FFFFFF)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Icon(
                    _centerIcon,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCaption() {
    final showDisplayName = widget.video.uploaderDisplayName.trim().isNotEmpty &&
        widget.video.uploaderDisplayName.trim() != widget.video.username.trim();

    return Positioned(
      left: 16,
      right: 92,
      bottom: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  showDisplayName
                      ? widget.video.uploaderDisplayName
                      : widget.video.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    shadows: [
                      Shadow(color: Color(0xAA000000), blurRadius: 8),
                    ],
                  ),
                ),
              ),
              if (showDisplayName) ...[
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    widget.video.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xD9FFFFFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (widget.video.caption.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              widget.video.caption,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.35,
                shadows: [
                  Shadow(color: Color(0xCC000000), blurRadius: 8),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}


class _VideoSurfaceGeometry {
  const _VideoSurfaceGeometry({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.isFullBleed,
  });

  final double width;
  final double height;
  final double borderRadius;
  final bool isFullBleed;

  factory _VideoSurfaceGeometry.resolve({
    required BoxConstraints constraints,
    required double aspectRatio,
  }) {
    final viewportWidth =
        constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 360.0;
    final viewportHeight =
        constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : 640.0;

    final safeRatio =
        aspectRatio.isFinite && aspectRatio >= 0.2 && aspectRatio <= 5
            ? aspectRatio
            : (9 / 16);

    var width = viewportWidth;
    var height = width / safeRatio;

    if (height > viewportHeight) {
      height = viewportHeight;
      width = height * safeRatio;
    }

    width = width.clamp(1.0, viewportWidth).toDouble();
    height = height.clamp(1.0, viewportHeight).toDouble();

    final widthCoverage = width / viewportWidth;
    final heightCoverage = height / viewportHeight;
    final isFullBleed = widthCoverage >= 0.995 && heightCoverage >= 0.995;

    final borderRadius = isFullBleed
        ? 0.0
        : safeRatio >= 1
            ? 24.0
            : 20.0;

    return _VideoSurfaceGeometry(
      width: width,
      height: height,
      borderRadius: borderRadius,
      isFullBleed: isFullBleed,
    );
  }
}

class _HopeVideoBackdrop extends StatelessWidget {
  const _HopeVideoBackdrop({
    required this.thumbnailUrl,
  });

  final String thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    final normalizedThumbnailUrl = thumbnailUrl.trim();

    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFFFB9BBD),
                Color(0xFFB15090),
                Color(0xFF601F24),
                Color(0xFF2F1713),
              ],
              stops: <double>[0, 0.38, 0.72, 1],
            ),
          ),
        ),
        if (normalizedThumbnailUrl.isNotEmpty)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Transform.scale(
              scale: 1.16,
              child: Image.network(
                normalizedThumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0x35FB9BBD),
                Color(0x59451C2C),
                Color(0xB31A1010),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HopeVideoPlaceholder extends StatelessWidget {
  const _HopeVideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFB9BBD),
            Color(0xFFC575B1),
            Color(0xFF833C69),
            Color(0xFF601F24),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.favorite_rounded,
          color: Color(0xD9FFFFFF),
          size: 42,
        ),
      ),
    );
  }
}

class _ReadabilityGradient extends StatelessWidget {
  const _ReadabilityGradient();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: <double>[0, 0.22, 0.56, 1],
            colors: <Color>[
              Color(0x80000000),
              Color(0x16000000),
              Color(0x12000000),
              Color(0xD9000000),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoBottomControls extends StatelessWidget {
  const _VideoBottomControls({
    required this.controller,
    required this.isMuted,
    required this.onToggleMute,
  });

  final VideoPlayerController controller;
  final bool isMuted;
  final VoidCallback onToggleMute;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 7,
      child: Row(
        children: [
          Material(
            color: const Color(0x99141C21),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onToggleMute,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(vertical: 12),
              colors: const VideoProgressColors(
                playedColor: HexaColors.signal,
                bufferedColor: Color(0x66FFFFFF),
                backgroundColor: Color(0x33FFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoLoadingIndicator extends StatelessWidget {
  const _VideoLoadingIndicator({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 42.0 : 58.0;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(compact ? 11 : 15),
      decoration: BoxDecoration(
        color: const Color(0xB3141C21),
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: const CircularProgressIndicator(
        strokeWidth: 2.4,
        color: Colors.white,
      ),
    );
  }
}

class _VideoErrorView extends StatelessWidget {
  const _VideoErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 30),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xE6141C21),
          borderRadius: BorderRadius.circular(HexaRadius.lg),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.play_disabled_rounded,
              color: Colors.white,
              size: 34,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}
