part of 'video_item.dart';

extension _VideoItemPlayback on _VideoItemState {
  static const Duration _initializationTimeout = Duration(seconds: 24);

  Future<void> _replaceVideo() async {
    _watchTimer.setActive(false);

    await _recordViewIfQualified();

    _controllerGeneration++;
    _watchTimer.reset();

    _viewRecorded = false;
    _viewRequestInProgress = false;

    _isActionBarOpen = false;
    _isCommentSheetOpen = false;
    _resumeAfterActionBar = false;

    widget.onInteractionStateChanged?.call(false);

    await _disposeCurrentController();

    if (!mounted) {
      return;
    }

    setState(() {
      _isInitialized = false;
      _isLoading = false;
      _errorMessage = null;
      _playbackIndicatorIcon = null;
    });

    if (_shouldPrepare) {
      await _prepareController();
    }
  }

  Future<void> _prepareAndSynchronizePlayback() async {
    await _prepareController();

    if (mounted) {
      await _synchronizePlayback();
    }
  }

  Future<void> _prepareController() async {
    final existingController = _controller;

    if (existingController != null && existingController.value.isInitialized) {
      await _synchronizePlayback();
      return;
    }

    if (_isLoading) {
      return;
    }

    final rawUrl = widget.video.playbackUrl.trim();
    final uri = Uri.tryParse(rawUrl);

    final supportedScheme =
        uri != null && (uri.scheme == 'https' || uri.scheme == 'http');

    if (rawUrl.isEmpty || !supportedScheme) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Video bağlantısı geçersiz.';
        });
      }

      return;
    }

    final generation = ++_controllerGeneration;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final controller = VideoPlayerController.networkUrl(
      uri,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
    );

    _controller = controller;

    controller.addListener(_handleControllerValueChanged);

    try {
      await controller.initialize().timeout(_initializationTimeout);

      if (!mounted ||
          generation != _controllerGeneration ||
          !identical(controller, _controller)) {
        controller.removeListener(_handleControllerValueChanged);

        await controller.dispose();
        return;
      }

      await controller.setLooping(true);
      await controller.setVolume(1);

      if (!mounted || !identical(controller, _controller)) {
        return;
      }

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

      await _synchronizePlayback();
    } on TimeoutException {
      await _handleInitializationFailure(
        controller: controller,
        generation: generation,
        message: 'Video bağlantısı zamanında yanıt vermedi.',
      );
    } catch (_) {
      await _handleInitializationFailure(
        controller: controller,
        generation: generation,
        message: 'Video şu anda oynatılamıyor.',
      );
    }
  }

  Future<void> _handleInitializationFailure({
    required VideoPlayerController controller,
    required int generation,
    required String message,
  }) async {
    controller.removeListener(_handleControllerValueChanged);

    if (identical(controller, _controller)) {
      _controller = null;
    }

    try {
      await controller.dispose();
    } catch (_) {
      // Asıl hata korunur.
    }

    if (!mounted || generation != _controllerGeneration) {
      return;
    }

    setState(() {
      _isInitialized = false;
      _isLoading = false;
      _errorMessage = message;
    });
  }

  void _handleControllerValueChanged() {
    final controller = _controller;

    if (!mounted || controller == null) {
      return;
    }

    final value = controller.value;

    if (value.hasError) {
      _watchTimer.setActive(false);

      final message = value.errorDescription?.trim();

      final resolvedMessage = message == null || message.isEmpty
          ? 'Video oynatma hatası oluştu.'
          : message;

      if (_errorMessage != resolvedMessage) {
        setState(() {
          _isLoading = false;
          _errorMessage = resolvedMessage;
        });
      }

      return;
    }

    if (!_isInitialized) {
      return;
    }

    final shouldTrackWatchTime =
        widget.isActive &&
        !_isCommentSheetOpen &&
        !_isActionBarOpen &&
        value.isPlaying &&
        !value.isBuffering;

    _watchTimer.setActive(shouldTrackWatchTime);

    final shouldShowLoading = widget.isActive && value.isBuffering;

    if (_isLoading != shouldShowLoading) {
      setState(() {
        _isLoading = shouldShowLoading;
      });
    }
  }

  Future<void> _synchronizePlayback() async {
    final controller = _controller;

    if (!mounted || controller == null || !controller.value.isInitialized) {
      return;
    }

    final shouldPlay =
        widget.isActive && !_isCommentSheetOpen && !_isActionBarOpen;

    try {
      if (shouldPlay) {
        if (!controller.value.isPlaying) {
          await controller.play();
        }

        return;
      }

      _watchTimer.setActive(false);

      if (controller.value.isPlaying) {
        await controller.pause();
      }

      if (!widget.isActive) {
        unawaited(_recordViewIfQualified());
      }
    } catch (_) {
      _watchTimer.setActive(false);

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Video oynatma işlemi tamamlanamadı.';
      });
    }
  }

  Future<void> _pauseAndRecordView() async {
    _watchTimer.setActive(false);

    _isActionBarOpen = false;
    _resumeAfterActionBar = false;

    widget.onInteractionStateChanged?.call(false);

    final controller = _controller;

    if (controller != null &&
        controller.value.isInitialized &&
        controller.value.isPlaying) {
      try {
        await controller.pause();
      } catch (_) {
        // Controller kapanıyor olabilir.
      }
    }

    await _recordViewIfQualified();
  }

  Future<void> _releaseController() async {
    _watchTimer.setActive(false);

    await _recordViewIfQualified();
    await _disposeCurrentController();

    if (!mounted) {
      return;
    }

    setState(() {
      _isInitialized = false;
      _isLoading = false;
      _errorMessage = null;
    });
  }

  Future<void> _disposeCurrentController() async {
    final controller = _controller;

    if (controller == null) {
      return;
    }

    _controller = null;

    controller.removeListener(_handleControllerValueChanged);

    try {
      if (controller.value.isInitialized && controller.value.isPlaying) {
        await controller.pause();
      }
    } catch (_) {
      // Dispose devam eder.
    }

    try {
      await controller.dispose();
    } catch (_) {
      // Kaynak temizleme hatası kullanıcıya gösterilmez.
    }
  }

  Future<void> _recordViewIfQualified() async {
    if (_viewRecorded || _viewRequestInProgress) {
      return;
    }

    final watchedMs = _watchTimer.snapshot(pause: true);

    if (watchedMs <= 0) {
      return;
    }

    final runtimeDuration = _controller?.value.duration.inMilliseconds ?? 0;

    final durationMs = runtimeDuration > 0
        ? runtimeDuration
        : widget.video.durationMs;

    if (!VideoViewService.isQualified(
      watchedMs: watchedMs,
      durationMs: durationMs,
    )) {
      return;
    }

    _viewRequestInProgress = true;

    try {
      final recorded = await ref
          .read(videoViewServiceProvider)
          .ensureQualifiedViewRecorded(
            videoId: widget.video.id,
            uploaderId: widget.video.uploaderId,
            watchedMs: watchedMs,
            durationMs: durationMs,
          );

      if (recorded) {
        _viewRecorded = true;
      }
    } catch (_) {
      // View kaydı oynatmayı engellemez.
    } finally {
      _viewRequestInProgress = false;
    }
  }
}
