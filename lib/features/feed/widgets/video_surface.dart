import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoSurface extends StatelessWidget {
  const VideoSurface({
    super.key,
    required this.controller,
    required this.isInitialized,
    required this.thumbnailUrl,
    required this.metadataAspectRatio,
  });

  final VideoPlayerController? controller;
  final bool isInitialized;
  final String thumbnailUrl;
  final double? metadataAspectRatio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = _viewportSize(constraints);
        final aspectRatio = _resolveAspectRatio();
        final videoDisplaySize = _fitInsideViewport(
          viewport: viewportSize,
          aspectRatio: aspectRatio,
        );

        final fillsViewport =
            (videoDisplaySize.width - viewportSize.width).abs() < 1 &&
            (videoDisplaySize.height - viewportSize.height).abs() < 1;

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _VideoBackdrop(thumbnailUrl: thumbnailUrl),
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: videoDisplaySize.width,
                  height: videoDisplaySize.height,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F1713),
                    borderRadius: BorderRadius.circular(fillsViewport ? 0 : 18),
                  ),
                  child: _buildMedia(aspectRatio),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedia(double aspectRatio) {
    final currentController = controller;

    if (isInitialized &&
        currentController != null &&
        currentController.value.isInitialized) {
      return AspectRatio(
        aspectRatio: aspectRatio,
        child: VideoPlayer(currentController),
      );
    }

    final normalizedThumbnailUrl = thumbnailUrl.trim();

    if (normalizedThumbnailUrl.isNotEmpty) {
      return Image.network(
        normalizedThumbnailUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return const _VideoPlaceholder();
        },
      );
    }

    return const _VideoPlaceholder();
  }

  double _resolveAspectRatio() {
    final currentController = controller;

    if (isInitialized && currentController != null) {
      final videoSize = currentController.value.size;

      if (videoSize.width > 0 && videoSize.height > 0) {
        final runtimeRatio = videoSize.width / videoSize.height;

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

  Size _viewportSize(BoxConstraints constraints) {
    final width = constraints.hasBoundedWidth && constraints.maxWidth > 0
        ? constraints.maxWidth
        : 360.0;

    final height = constraints.hasBoundedHeight && constraints.maxHeight > 0
        ? constraints.maxHeight
        : 640.0;

    return Size(width, height);
  }

  Size _fitInsideViewport({
    required Size viewport,
    required double aspectRatio,
  }) {
    final heightWhenUsingFullWidth = viewport.width / aspectRatio;

    if (heightWhenUsingFullWidth <= viewport.height) {
      return Size(viewport.width, heightWhenUsingFullWidth);
    }

    final widthWhenUsingFullHeight = viewport.height * aspectRatio;

    return Size(widthWhenUsingFullHeight, viewport.height);
  }

  bool _isValidAspectRatio(double value) {
    return value.isFinite && value >= 0.2 && value <= 5;
  }
}

class _VideoBackdrop extends StatelessWidget {
  const _VideoBackdrop({required this.thumbnailUrl});

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
              colors: [
                Color(0xFFFB9BBD),
                Color(0xFFB15090),
                Color(0xFF601F24),
                Color(0xFF2F1713),
              ],
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
                errorBuilder: (_, __, ___) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        const ColoredBox(color: Color(0x331A1010)),
      ],
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFB9BBD),
            Color(0xFFC575B1),
            Color(0xFF833C69),
            Color(0xFF601F24),
          ],
        ),
      ),
      child: Center(
        child: Icon(Icons.favorite_rounded, color: Color(0xD9FFFFFF), size: 42),
      ),
    );
  }
}
