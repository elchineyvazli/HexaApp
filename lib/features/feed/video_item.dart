import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import 'feed_models.dart';
import 'video_action_buttons.dart';
import 'widgets/video_overlays.dart';
import 'widgets/video_surface.dart';
import 'services/video_view_service.dart';

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
  Timer? _iconTimer;

  bool _initialized = false;
  bool _loading = false;
  bool _buffering = false;
  bool _userPaused = false;
  bool _appActive = true;

  bool _viewHandled = false;
  bool _viewRecording = false;
  DateTime? _viewRetryAfter;

  String? _error;
  IconData? _centerIcon;
  int _loadToken = 0;

  final VideoWatchTimer _watchTimer = VideoWatchTimer();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    if (widget.shouldPreload) {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    final videoChanged =
        oldWidget.video.id != widget.video.id ||
        oldWidget.video.playbackUrl != widget.video.playbackUrl;

    if (videoChanged) {
      _release(notify: false);

      _userPaused = false;
      _viewHandled = false;
      _viewRecording = false;
      _viewRetryAfter = null;

      _watchTimer.reset();

      if (widget.shouldPreload) {
        _load();
      }

      return;
    }

    if (oldWidget.shouldPreload != widget.shouldPreload) {
      if (widget.shouldPreload) {
        _load();
      } else {
        _release();
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
    _appActive = state == AppLifecycleState.resumed;
    _syncPlayback();
  }

  Future<void> _load() async {
    if (_controller != null || !widget.shouldPreload) {
      return;
    }

    final uri = Uri.tryParse(widget.video.playbackUrl.trim());

    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        setState(() {
          _error = 'Video bağlantısı geçerli değil.';
        });
      }

      return;
    }

    final token = ++_loadToken;

    final controller = VideoPlayerController.networkUrl(uri);

    _controller = controller;
    controller.addListener(_onPlayerChanged);

    if (mounted) {
      setState(() {
        _loading = true;
        _initialized = false;
        _error = null;
      });
    }

    try {
      await controller.initialize();

      await Future.wait<void>([
        controller.setLooping(true),
        controller.setVolume(ref.read(feedMutedProvider) ? 0 : 1),
      ]);

      if (!_isCurrent(controller, token)) {
        controller.removeListener(_onPlayerChanged);
        await controller.dispose();
        return;
      }

      setState(() {
        _loading = false;
        _initialized = true;
        _buffering = controller.value.isBuffering;
      });

      _syncPlayback();
    } catch (_) {
      if (!_isCurrent(controller, token)) {
        return;
      }

      controller.removeListener(_onPlayerChanged);
      await controller.dispose();

      if (_controller == controller) {
        _controller = null;
      }

      setState(() {
        _loading = false;
        _initialized = false;
        _buffering = false;
        _error = 'Video şu anda yüklenemiyor.';
      });

      _watchTimer.setActive(false);
    }
  }

  bool _isCurrent(VideoPlayerController controller, int token) {
    return mounted && token == _loadToken && _controller == controller;
  }

  void _release({bool notify = true}) {
    ++_loadToken;

    _iconTimer?.cancel();
    _watchTimer.setActive(false);

    final controller = _controller;
    _controller = null;

    if (controller != null) {
      controller.removeListener(_onPlayerChanged);
      controller.pause();
      controller.dispose();
    }

    _initialized = false;
    _loading = false;
    _buffering = false;
    _error = null;
    _centerIcon = null;

    if (notify && mounted) {
      setState(() {});
    }
  }

  void _onPlayerChanged() {
    final controller = _controller;

    if (!mounted || controller == null) {
      return;
    }

    final value = controller.value;

    final nextError = value.hasError
        ? 'Video oynatılırken bir sorun oluştu.'
        : null;

    if (_buffering != value.isBuffering || _error != nextError) {
      setState(() {
        _buffering = value.isBuffering;

        if (nextError != null) {
          _error = nextError;
        }
      });
    }

    final activelyWatching =
        widget.isActive &&
        _appActive &&
        value.isPlaying &&
        !value.isBuffering &&
        !value.hasError;

    _watchTimer.setActive(activelyWatching);

    if (activelyWatching) {
      _maybeRecordQualifiedView(value);
    }
  }

  void _maybeRecordQualifiedView(VideoPlayerValue value) {
    if (_viewHandled || _viewRecording) {
      return;
    }

    final retryAfter = _viewRetryAfter;

    if (retryAfter != null && DateTime.now().isBefore(retryAfter)) {
      return;
    }

    final durationMs = value.duration.inMilliseconds > 0
        ? value.duration.inMilliseconds
        : widget.video.durationMs;

    final watchedMs = _watchTimer.elapsedMs;

    if (!VideoViewService.isQualified(
      watchedMs: watchedMs,
      durationMs: durationMs,
    )) {
      return;
    }

    _viewRecording = true;

    final videoId = widget.video.id;

    unawaited(
      _recordQualifiedView(
        videoId: videoId,
        watchedMs: watchedMs,
        durationMs: durationMs,
      ),
    );
  }

  Future<void> _recordQualifiedView({
    required String videoId,
    required int watchedMs,
    required int durationMs,
  }) async {
    try {
      final handled = await ref
          .read(videoViewServiceProvider)
          .ensureQualifiedViewRecorded(
            videoId: videoId,
            uploaderId: widget.video.uploaderId,
            watchedMs: watchedMs,
            durationMs: durationMs,
          );

      if (!mounted || widget.video.id != videoId) {
        return;
      }

      if (handled) {
        _viewHandled = true;
      }
    } catch (error, stackTrace) {
      debugPrint('Video görüntülenmesi kaydedilemedi: $error');

      debugPrintStack(stackTrace: stackTrace);

      if (mounted && widget.video.id == videoId) {
        _viewRetryAfter = DateTime.now().add(const Duration(seconds: 10));
      }
    } finally {
      if (mounted && widget.video.id == videoId) {
        _viewRecording = false;
      }
    }
  }

  void _syncPlayback() {
    final controller = _controller;

    if (controller == null || !_initialized) {
      _watchTimer.setActive(false);
      return;
    }

    final shouldPlay =
        widget.isActive && _appActive && !_userPaused && _error == null;

    if (shouldPlay && !controller.value.isPlaying) {
      controller.play();
    } else if (!shouldPlay && controller.value.isPlaying) {
      controller.pause();
      _watchTimer.setActive(false);
    }
  }

  void _togglePlayback() {
    if (!_initialized || _controller == null) {
      if (_error != null) {
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

    _iconTimer?.cancel();

    _iconTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _centerIcon = null;
        });
      }
    });
  }

  void _toggleMute() {
    final notifier = ref.read(feedMutedProvider.notifier);

    notifier.state = !notifier.state;

    HapticFeedback.selectionClick();
  }

  void _retry() {
    _release();
    _load();
  }

  int _qualifiedWatchMs() {
    return _watchTimer.elapsedMs;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _iconTimer?.cancel();
    _release(notify: false);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final muted = ref.watch(feedMutedProvider);

    ref.listen<bool>(feedMutedProvider, (_, next) {
      _controller?.setVolume(next ? 0 : 1);
    });

    return Semantics(
      label: '${widget.video.creatorName} tarafından paylaşılan video',
      hint: 'Oynatmak veya durdurmak için bir kez dokun',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _togglePlayback,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoSurface(
              controller: _controller,
              isInitialized: _initialized,
              thumbnailUrl: widget.video.thumbnailUrl,
              metadataAspectRatio: widget.video.aspectRatio,
            ),
            const VideoReadabilityGradient(),
            if (_loading && !_initialized)
              const Center(child: VideoLoadingIndicator()),
            if (_buffering && _initialized && widget.isActive)
              const Center(child: VideoLoadingIndicator(compact: true)),
            if (_error != null && !_initialized)
              VideoErrorView(message: _error!, onRetry: _retry),
            VideoPlaybackIndicator(icon: _centerIcon),
            VideoCaptionOverlay(video: widget.video),
            VideoActionButtons(
              video: widget.video,
              qualifiedWatchMsProvider: _qualifiedWatchMs,
            ),
            if (_initialized && _controller != null)
              VideoBottomControls(
                controller: _controller!,
                isMuted: muted,
                onToggleMute: _toggleMute,
              ),
          ],
        ),
      ),
    );
  }
}
