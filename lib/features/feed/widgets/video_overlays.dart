import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';
import 'package:video_player/video_player.dart';

import '../feed_models.dart';

class VideoPlaybackIndicator extends StatelessWidget {
  const VideoPlaybackIndicator({super.key, required this.icon});

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: icon == null
              ? const SizedBox.shrink(key: ValueKey('empty'))
              : Container(
                  key: ValueKey(icon),
                  width: 74,
                  height: 74,
                  decoration: const BoxDecoration(
                    color: Color(0xCC141C21),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 38),
                ),
        ),
      ),
    );
  }
}

class VideoCaptionOverlay extends StatelessWidget {
  const VideoCaptionOverlay({super.key, required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    final displayName = video.uploaderDisplayName.trim();
    final username = video.username.trim();
    final showBoth = displayName.isNotEmpty && displayName != username;

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
                  showBoth ? displayName : username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: Color(0xAA000000), blurRadius: 8),
                    ],
                  ),
                ),
              ),
              if (showBoth) ...[
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    username,
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
          if (video.caption.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              video.caption,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
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

class VideoBottomControls extends StatelessWidget {
  const VideoBottomControls({
    super.key,
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

class VideoLoadingIndicator extends StatelessWidget {
  const VideoLoadingIndicator({super.key, this.compact = false});

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
      ),
      child: const CircularProgressIndicator(
        strokeWidth: 2.4,
        color: Colors.white,
      ),
    );
  }
}

class VideoErrorView extends StatelessWidget {
  const VideoErrorView({
    super.key,
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

class VideoReadabilityGradient extends StatelessWidget {
  const VideoReadabilityGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.22, 0.56, 1],
            colors: [
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


class VideoWatchTimer {
  final Stopwatch _stopwatch = Stopwatch();
  int _committedMs = 0;

  int get elapsedMs {
    final running = _stopwatch.isRunning ? _stopwatch.elapsedMilliseconds : 0;
    return (_committedMs + running).clamp(0, 24 * 60 * 60 * 1000).toInt();
  }

  void setActive(bool active) {
    if (active) {
      if (!_stopwatch.isRunning) _stopwatch.start();
      return;
    }

    if (!_stopwatch.isRunning) return;
    _stopwatch.stop();
    _committedMs += _stopwatch.elapsedMilliseconds;
    _stopwatch.reset();
  }

  void reset() {
    _stopwatch
      ..stop()
      ..reset();
    _committedMs = 0;
  }
}
