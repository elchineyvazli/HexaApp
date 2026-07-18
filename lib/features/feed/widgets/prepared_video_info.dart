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
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    return TweenAnimationBuilder<double>(
      key: ValueKey<String>(video.videoFile.path),
      tween: Tween<double>(begin: reduceMotion ? 1 : 0, end: 1),
      duration: reduceMotion ? Duration.zero : HexaMotion.slow,
      curve: HexaMotion.listEnter,
      builder: (context, value, child) {
        final double safeValue = value.clamp(0.0, 1.03).toDouble();

        final double opacity = value.clamp(0.0, 1.0).toDouble();

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, 12.0 * (1.0 - safeValue)),
            child: Transform.scale(
              scale: 0.97 + (safeValue * 0.03),
              child: child,
            ),
          ),
        );
      },
      child: _PreparedVideoSurface(video: video, onRemove: onRemove),
    );
  }
}

class _PreparedVideoSurface extends StatelessWidget {
  const _PreparedVideoSurface({required this.video, required this.onRemove});

  final PreparedVideoUpload video;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final accent = video.wasCompressed
        ? HexaColors.success
        : theme.colorScheme.primary;

    final tintedSurface = Color.alphaBlend(
      accent.withAlpha(theme.brightness == Brightness.dark ? 24 : 14),
      theme.colorScheme.surface,
    );

    return Semantics(
      container: true,
      label: video.wasCompressed ? 'Video optimize edildi' : 'Video hazır',
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[theme.colorScheme.surface, tintedSurface],
          ),
          borderRadius: HexaRadius.borderLg,
          border: Border.all(color: accent.withAlpha(52)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(HexaSpacing.sm),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: HexaRadius.borderMd,
                child: Image.memory(
                  video.thumbnailBytes,
                  width: 66,
                  height: 88,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              const SizedBox(width: HexaSpacing.sm),
              Expanded(
                child: _VideoSummary(video: video, accent: accent),
              ),
              const SizedBox(width: HexaSpacing.xs),
              _RemoveVideoButton(onPressed: onRemove),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoSummary extends StatelessWidget {
  const _VideoSummary({required this.video, required this.accent});

  final PreparedVideoUpload video;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final duration = _formatDuration(video.durationMs);
    final size = _formatBytes(video.fileSizeBytes);
    final resolution = '${video.width}×${video.height}';

    final savedPercent = (video.savedFraction * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(color: accent.withAlpha(90), blurRadius: 10),
                ],
              ),
            ),
            const SizedBox(width: HexaSpacing.xs),
            Expanded(
              child: Text(
                video.wasCompressed ? 'Optimize edildi' : 'Hazır',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: HexaSpacing.xs),
        Text(
          '$duration  ·  $resolution',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          video.wasCompressed && savedPercent > 0
              ? '$size · %$savedPercent daha hafif'
              : size,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: accent,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  String _formatDuration(int durationMs) {
    final duration = Duration(milliseconds: durationMs);

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes) {
    const bytesPerMb = 1024 * 1024;

    if (bytes < bytesPerMb) {
      final kilobytes = bytes / 1024;

      return '${kilobytes.toStringAsFixed(0)} KB';
    }

    final megabytes = bytes / bytesPerMb;

    return '${megabytes.toStringAsFixed(1)} MB';
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

  @override
  Widget build(BuildContext context) {
    final reduceMotion = HexaMotion.reduceMotionOf(context);
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Videoyu kaldır',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          setState(() => _pressed = true);
        },
        onTapCancel: () {
          setState(() => _pressed = false);
        },
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _pressed ? HexaMotion.pressScale : 1,
          duration: reduceMotion ? Duration.zero : HexaMotion.fast,
          curve: HexaMotion.elastic,
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withAlpha(190),
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Icon(
              Icons.close_rounded,
              size: 19,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
