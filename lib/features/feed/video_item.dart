import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/hexa_theme.dart';
import 'feed_models.dart';
import 'hexa_comment_sheet.dart';
import 'services/video_view_service.dart';
import 'widgets/video_interaction_overlay.dart';
import 'widgets/video_overlays.dart';
import 'widgets/video_surface.dart';

part 'video_item_interactions.dart';
part 'video_item_playback.dart';

class VideoItem extends ConsumerStatefulWidget {
  const VideoItem({
    required this.video,
    required this.isActive,
    required this.shouldPreload,
    this.dismissInteractionToken = 0,
    this.onInteractionStateChanged,
    super.key,
  });

  final VideoModel video;
  final bool isActive;
  final bool shouldPreload;
  final int dismissInteractionToken;
  final ValueChanged<bool>? onInteractionStateChanged;

  @override
  ConsumerState<VideoItem> createState() {
    return _VideoItemState();
  }
}

class _VideoItemState extends ConsumerState<VideoItem> {
  final VideoWatchTimer _watchTimer = VideoWatchTimer();

  VideoPlayerController? _controller;
  Timer? _playbackIndicatorTimer;

  bool _isInitialized = false;
  bool _isLoading = false;

  bool _isCommentSheetOpen = false;
  bool _isActionBarOpen = false;
  bool _resumeAfterActionBar = false;

  bool _viewRecorded = false;
  bool _viewRequestInProgress = false;

  IconData? _playbackIndicatorIcon;
  String? _errorMessage;

  int _controllerGeneration = 0;

  bool get _shouldPrepare {
    return widget.isActive || widget.shouldPreload;
  }

  bool get _canInteract {
    return widget.isActive &&
        _isInitialized &&
        _errorMessage == null;
  }

  @override
  void initState() {
    super.initState();

    if (_shouldPrepare) {
      unawaited(_prepareController());
    }
  }

  @override
  void didUpdateWidget(
    covariant VideoItem oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final sourceChanged =
        oldWidget.video.id != widget.video.id ||
        oldWidget.video.playbackUrl !=
            widget.video.playbackUrl;

    if (sourceChanged) {
      unawaited(_replaceVideo());
      return;
    }

    if (oldWidget.dismissInteractionToken !=
        widget.dismissInteractionToken) {
      if (_isActionBarOpen) {
        unawaited(_setActionBarOpen(false));
      }

      if (_isCommentSheetOpen) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) {
            if (mounted && _isCommentSheetOpen) {
              Navigator.of(
                context,
                rootNavigator: true,
              ).maybePop();
            }
          },
        );
      }
    }

    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        unawaited(
          _prepareAndSynchronizePlayback(),
        );
      } else {
        unawaited(_pauseAndRecordView());
      }
    }

    if (oldWidget.shouldPreload !=
        widget.shouldPreload) {
      if (_shouldPrepare) {
        unawaited(_prepareController());
      } else if (!widget.isActive) {
        unawaited(_releaseController());
      }
    }
  }

  @override
  void dispose() {
    _playbackIndicatorTimer?.cancel();

    _watchTimer.setActive(false);

    unawaited(_recordViewIfQualified());
    unawaited(_disposeCurrentController());

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        HexaMotion.reduceMotionOf(context);

    final errorMessage = _errorMessage;
    final showLoading =
        _isLoading && errorMessage == null;

    return TickerMode(
      enabled:
          widget.isActive || widget.shouldPreload,
      child: ColoredBox(
        color: HexaColors.earth,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            VideoSurface(
              controller: _controller,
              isInitialized: _isInitialized,
              thumbnailUrl:
                  widget.video.thumbnailUrl,
              metadataAspectRatio:
                  widget.video.aspectRatio,
            ),

            AnimatedOpacity(
              opacity: _canInteract ? 1 : 0,
              duration: reduceMotion
                  ? Duration.zero
                  : HexaMotion.normal,
              curve: HexaMotion.enter,
              child: IgnorePointer(
                ignoring: !_canInteract,
                child: VideoInteractionOverlay(
                  video: widget.video,
                  enabled: _canInteract,
                  dismissToken:
                      widget.dismissInteractionToken,
                  onTogglePlayback:
                      _togglePlayback,
                  onOpenComments: _openComments,
                  onActionBarVisibilityChanged:
                      (value) {
                    if (!widget.isActive && value) {
                      return;
                    }

                    unawaited(
                      _setActionBarOpen(value),
                    );
                  },
                ),
              ),
            ),

            VideoPlaybackIndicator(
              icon: _playbackIndicatorIcon,
            ),

            IgnorePointer(
              child: AnimatedOpacity(
                opacity: showLoading ? 1 : 0,
                duration: reduceMotion
                    ? Duration.zero
                    : HexaMotion.fast,
                curve: HexaMotion.enter,
                child: const Center(
                  child: VideoLoadingIndicator(),
                ),
              ),
            ),

            AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : HexaMotion.normal,
              switchInCurve: HexaMotion.enter,
              switchOutCurve: HexaMotion.exit,
              transitionBuilder: (
                child,
                animation,
              ) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin:
                          HexaMotion.pageEnterOffset,
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: errorMessage == null
                  ? const SizedBox.shrink(
                      key: ValueKey<String>(
                        'no-video-error',
                      ),
                    )
                  : VideoErrorView(
                      key: ValueKey<String>(
                        errorMessage,
                      ),
                      message: errorMessage,
                      onRetry: _retry,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}