// lib/features/feed/widgets/video_player_controls.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerControls extends StatefulWidget {
  final VideoPlayerController controller;
  final bool isMuted;
  final VoidCallback onToggleMute;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;

  const VideoPlayerControls({
    super.key,
    required this.controller,
    required this.isMuted,
    required this.onToggleMute,
    required this.onSeekForward,
    required this.onSeekBackward,
  });

  @override
  State<VideoPlayerControls> createState() => _VideoPlayerControlsState();
}

class _VideoPlayerControlsState extends State<VideoPlayerControls> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. KATMAN: İleri / Geri Sarma Okları (Yanlarda Gizli Güç)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: widget.onSeekBackward,
                icon: const Icon(Icons.replay_10, color: Colors.white70, size: 28),
                tooltip: '10sn Geri',
              ),
              IconButton(
                onPressed: widget.onSeekForward,
                icon: const Icon(Icons.forward_10, color: Colors.white70, size: 28),
                tooltip: '10sn İleri',
              ),
            ],
          ),
          const SizedBox(height: 4),

          // 2. KATMAN: Sol Altta Ses İkonu & Sağında Neon Range Bar
          Row(
            children: [
              // Sessize Alma / Açma Butonu
              GestureDetector(
                onTap: widget.onToggleMute,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181926).withOpacity(0.8),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFF5E00), width: 1.5),
                  ),
                  child: Icon(
                    widget.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: widget.isMuted ? const Color(0xFFEF4444) : const Color(0xFFFF5E00),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Neon İlerleme Çubuğu (Range Bar)
              Expanded(
                child: VideoProgressIndicator(
                  widget.controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: const Color(0xFFFF5E00),
                    bufferedColor: const Color(0xFF9D4EDD).withOpacity(0.3),
                    backgroundColor: Colors.white24,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}