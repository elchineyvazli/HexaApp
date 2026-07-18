part of 'video_item.dart';

extension _VideoItemInteractions on _VideoItemState {
  Future<void> _togglePlayback() async {
    final controller = _controller;

    if (!widget.isActive ||
        controller == null ||
        !controller.value.isInitialized ||
        _isCommentSheetOpen ||
        _isActionBarOpen) {
      return;
    }

    try {
      if (controller.value.isPlaying) {
        _watchTimer.setActive(false);

        await controller.pause();

        if (mounted) {
          _showPlaybackIndicator(Icons.pause_rounded);
        }

        return;
      }

      await controller.play();

      if (mounted) {
        _showPlaybackIndicator(Icons.play_arrow_rounded);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Video oynatma işlemi tamamlanamadı.';
      });
    }
  }

  void _showPlaybackIndicator(IconData icon) {
    _playbackIndicatorTimer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _playbackIndicatorIcon = icon;
    });

    _playbackIndicatorTimer = Timer(HexaMotion.breathe, () {
      if (!mounted) {
        return;
      }

      setState(() {
        _playbackIndicatorIcon = null;
      });
    });
  }

  Future<void> _setActionBarOpen(bool value) async {
    if (_isActionBarOpen == value) {
      return;
    }

    final controller = _controller;

    if (value) {
      _resumeAfterActionBar = controller?.value.isPlaying ?? false;

      _isActionBarOpen = true;

      widget.onInteractionStateChanged?.call(true);

      _watchTimer.setActive(false);

      if (controller != null &&
          controller.value.isInitialized &&
          controller.value.isPlaying) {
        try {
          await controller.pause();
        } catch (_) {
          // Panel yine de açılabilir.
        }
      }

      return;
    }

    final shouldResume = _resumeAfterActionBar;

    _resumeAfterActionBar = false;
    _isActionBarOpen = false;

    widget.onInteractionStateChanged?.call(false);

    if (shouldResume && widget.isActive && mounted) {
      await _synchronizePlayback();
    }
  }

  Future<void> _openComments() async {
    if (_isCommentSheetOpen ||
        _isActionBarOpen ||
        !widget.isActive ||
        widget.video.id.trim().isEmpty) {
      return;
    }

    final controller = _controller;

    final shouldResume =
        controller != null &&
        controller.value.isInitialized &&
        controller.value.isPlaying;

    _isCommentSheetOpen = true;

    widget.onInteractionStateChanged?.call(true);

    _watchTimer.setActive(false);

    if (controller != null &&
        controller.value.isInitialized &&
        controller.value.isPlaying) {
      try {
        await controller.pause();
      } catch (_) {
        // Yorum paneli yine de açılır.
      }
    }

    if (!mounted) {
      _isCommentSheetOpen = false;
      widget.onInteractionStateChanged?.call(false);
      return;
    }

    try {
      await showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        useSafeArea: true,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        backgroundColor: HexaColors.transparent,
        barrierColor: HexaColors.earth.withAlpha(150),
        builder: (_) {
          return HexaCommentSheet(videoId: widget.video.id);
        },
      );
    } finally {
      _isCommentSheetOpen = false;

      widget.onInteractionStateChanged?.call(false);

      if (!mounted || !widget.isActive) {
        return;
      }

      if (shouldResume) {
        await _synchronizePlayback();
      } else {
        _watchTimer.setActive(false);
      }
    }
  }

  Future<void> _retry() async {
    _controllerGeneration++;

    _playbackIndicatorTimer?.cancel();

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

    await _prepareController();
  }
}
