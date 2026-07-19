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

  static const Color _videoBackground = Color(0xFF050507);

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

    final normalizedThumbnailUrl = thumbnailUrl.trim();

    final mediaKey = showVideo
        ? 'video-${currentController.dataSource}'
        : 'thumbnail-$normalizedThumbnailUrl';

    return RepaintBoundary(
      child: ColoredBox(
        color: _videoBackground,
        child: ClipRect(
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
            child: SizedBox.expand(
              key: ValueKey<String>(mediaKey),
              child: showVideo
                  ? _buildVideo(currentController)
                  : _buildThumbnail(
                      reduceMotion: reduceMotion,
                      normalizedUrl: normalizedThumbnailUrl,
                    ),
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

  Widget _buildThumbnail({
    required bool reduceMotion,
    required String normalizedUrl,
  }) {
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
      fadeInDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 220),
      fadeOutDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 120),
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

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({this.hasError = false});

  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF050507),
      child: hasError
          ? Center(
              child: Semantics(
                label: 'Video önizlemesi yüklenemedi',
                child: Icon(
                  Icons.videocam_off_outlined,
                  color: const Color(0x4DFFFFFF),
                  size: 30,
                ),
              ),
            )
          : const SizedBox.expand(),
    );
  }
}
