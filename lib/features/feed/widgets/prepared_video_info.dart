import 'package:flutter/material.dart';

import '../../../core/theme/hexa_theme.dart';
import '../video_upload_preparer.dart';

class PreparedVideoInfo extends StatelessWidget {
  const PreparedVideoInfo({
    required this.video,
    required this.onRemove,
    super.key,
  });

  final PreparedVideoUpload video;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _PreparedVideoSurface(
      key: ValueKey<String>(video.videoFile.path),
      video: video,
      onRemove: onRemove,
    );
  }
}

class _PreparedVideoSurface extends StatelessWidget {
  const _PreparedVideoSurface({
    required this.video,
    required this.onRemove,
    super.key,
  });

  final PreparedVideoUpload video;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final accentColor = video.wasCompressed
        ? HexaColors.cyan
        : HexaColors.purpleSoft;

    return Semantics(
      container: true,
      label: video.wasCompressed
          ? 'Video optimize edildi ve yüklemeye hazır'
          : 'Video yüklemeye hazır',
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: HexaColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                video.thumbnailBytes,
                width: 62,
                height: 82,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) {
                  return const _ThumbnailFallback();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _VideoSummary(video: video, accentColor: accentColor),
            ),
            const SizedBox(width: 8),
            _RemoveVideoButton(onPressed: onRemove),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailFallback extends StatelessWidget {
  const _ThumbnailFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 82,
      alignment: Alignment.center,
      color: HexaColors.surfaceMutedDark,
      child: Icon(
        Icons.videocam_outlined,
        color: Colors.white.withOpacity(0.30),
        size: 24,
      ),
    );
  }
}

class _VideoSummary extends StatelessWidget {
  const _VideoSummary({required this.video, required this.accentColor});

  final PreparedVideoUpload video;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final duration = _formatDuration(video.durationMs);

    final size = _formatBytes(video.fileSizeBytes);

    final resolution = '${video.width} × ${video.height}';

    final savedPercent = (video.savedFraction * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 21,
              height: 21,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: accentColor, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                video.wasCompressed ? 'Video optimize edildi' : 'Video hazır',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xEFFFFFFF),
                  fontSize: 13.5,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          '$duration  ·  $resolution',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0x80FFFFFF),
            fontSize: 11.5,
            height: 1.2,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.05,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: <Widget>[
            Flexible(
              child: Text(
                size,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.58),
                  fontSize: 11.5,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.05,
                ),
              ),
            ),
            if (video.wasCompressed && savedPercent > 0) ...<Widget>[
              Container(
                width: 3,
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 7),
                decoration: const BoxDecoration(
                  color: Color(0x4DFFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
              Flexible(
                child: Text(
                  '%$savedPercent küçültüldü',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accentColor.withOpacity(0.90),
                    fontSize: 11.5,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.05,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _formatDuration(int durationMs) {
    final duration = Duration(milliseconds: durationMs);

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '$minutes:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes) {
    const bytesPerKilobyte = 1024;
    const bytesPerMegabyte = bytesPerKilobyte * 1024;
    const bytesPerGigabyte = bytesPerMegabyte * 1024;

    if (bytes >= bytesPerGigabyte) {
      final gigabytes = bytes / bytesPerGigabyte;

      return '${gigabytes.toStringAsFixed(2)} GB';
    }

    if (bytes >= bytesPerMegabyte) {
      final megabytes = bytes / bytesPerMegabyte;

      return '${megabytes.toStringAsFixed(1)} MB';
    }

    final kilobytes = bytes / bytesPerKilobyte;

    return '${kilobytes.toStringAsFixed(0)} KB';
  }
}

class _RemoveVideoButton extends StatefulWidget {
  const _RemoveVideoButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_RemoveVideoButton> createState() {
    return _RemoveVideoButtonState();
  }
}

class _RemoveVideoButtonState extends State<_RemoveVideoButton> {
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
      label: 'Videoyu kaldır',
      child: Tooltip(
        message: 'Videoyu kaldır',
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
            widget.onPressed();
          },
          child: AnimatedScale(
            scale: _pressed ? 0.88 : 1,
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 130),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 130),
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _pressed
                    ? Colors.white.withOpacity(0.10)
                    : Colors.white.withOpacity(0.055),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 19,
                color: Colors.white.withOpacity(0.62),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
