import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

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
    final duration = Duration(milliseconds: video.durationMs);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    final originalSizeMb = video.originalFileSizeBytes / (1024 * 1024);
    final finalSizeMb = video.fileSizeBytes / (1024 * 1024);

    return Container(
      padding: const EdgeInsets.all(HexaSpacing.sm),
      decoration: BoxDecoration(
        color: video.wasCompressed ? HexaColors.mintSoft : HexaColors.surface,
        borderRadius: BorderRadius.circular(HexaRadius.lg),
        border: Border.all(
          color: video.wasCompressed ? HexaColors.mint : HexaColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(HexaRadius.md),
            child: Image.memory(
              video.thumbnailBytes,
              width: 84,
              height: 112,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: HexaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      video.wasCompressed
                          ? Icons.compress_rounded
                          : Icons.check_circle_rounded,
                      color: video.wasCompressed
                          ? HexaColors.success
                          : HexaColors.signalStrong,
                      size: 19,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        video.wasCompressed
                            ? 'Video sıkıştırıldı'
                            : 'Video hazır',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: HexaSpacing.sm),
                if (video.wasCompressed)
                  Text(
                    '${originalSizeMb.toStringAsFixed(1)} MB → '
                    '${finalSizeMb.toStringAsFixed(1)} MB',
                    style: const TextStyle(
                      color: HexaColors.success,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else
                  Text(
                    '${finalSizeMb.toStringAsFixed(1)} MB',
                    style: const TextStyle(
                      color: HexaColors.inkMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: HexaSpacing.xs),
                Wrap(
                  spacing: HexaSpacing.xs,
                  runSpacing: HexaSpacing.xs,
                  children: [
                    _VideoMetric(
                      icon: Icons.schedule_rounded,
                      label: '$minutes:${seconds.toString().padLeft(2, '0')}',
                    ),
                    _VideoMetric(
                      icon: Icons.aspect_ratio_rounded,
                      label: '${video.width} × ${video.height}',
                    ),
                    _VideoMetric(
                      icon: Icons.crop_rounded,
                      label: video.aspectRatio.toStringAsFixed(3),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Videoyu kaldır',
            icon: const Icon(Icons.close_rounded, color: HexaColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _VideoMetric extends StatelessWidget {
  const _VideoMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xBFFFFFFF),
        borderRadius: BorderRadius.circular(HexaRadius.pill),
        border: Border.all(color: HexaColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: HexaColors.inkMuted, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: HexaColors.inkMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
