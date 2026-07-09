// lib/features/feed/video_item.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'feed_models.dart';
import '../navigation/main_scaffold.dart';
import 'video_action_buttons.dart';
import 'widgets/video_player_controls.dart'; // YENİ: Kontrol çubuğu importu!

class VideoItem extends ConsumerStatefulWidget {
  final VideoModel video;
  final bool isActive;

  const VideoItem({super.key, required this.video, required this.isActive});

  @override
  ConsumerState<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends ConsumerState<VideoItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = true;
  bool _isMuted = false;
  bool _showCenterIcon = false; // Ekrana dokununca ortada parlayan oynat/durdur ikonu için

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.setLooping(true);
          _updatePlaybackState();
        }
      });
  }

  void _updatePlaybackState() {
    if (!_isInitialized || !mounted) return;

    final currentTabIndex = ref.read(currentTabIndexProvider);
    final shouldPlay = widget.isActive && (currentTabIndex == 0) && _isPlaying;

    if (shouldPlay) {
      _controller.play();
    } else {
      _controller.pause();
    }
  }

  // ⚡ EKRANA TIKLAYINCA OYNAT / DURDUR ⚡
  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      _showCenterIcon = true;
    });
    _updatePlaybackState();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showCenterIcon = false);
    });
  }

  // ⚡ SOL ALTTA SESSİZE AL / AÇ ⚡
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  // ⚡ 10 SANİYE İLERİ SAR ⚡
  void _seekForward() {
    final currentPosition = _controller.value.position;
    final targetPosition = currentPosition + const Duration(seconds: 10);
    _controller.seekTo(targetPosition);
  }

  // ⚡ 10 SANİYE GERİ SAR ⚡
  void _seekBackward() {
    final currentPosition = _controller.value.position;
    final targetPosition = currentPosition - const Duration(seconds: 10);
    _controller.seekTo(targetPosition > Duration.zero ? targetPosition : Duration.zero);
  }

  @override
  void didUpdateWidget(VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.videoUrl != widget.video.videoUrl) {
      _controller.dispose();
      _isInitialized = false;
      _initVideo();
    } else if (_isInitialized && oldWidget.isActive != widget.isActive) {
      _updatePlaybackState();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(currentTabIndexProvider, (previous, next) {
      _updatePlaybackState();
    });

    return GestureDetector(
      onTap: _togglePlayPause, // Tek dokunuşla oynat/durdur
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: Container(
              color: const Color(0xFF0F172A),
              child: _isInitialized
                  ? Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _controller.value.size.width,
                              height: _controller.value.size.height,
                              child: VideoPlayer(_controller),
                            ),
                          ),
                        ),
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                          child: Container(
                            color: const Color(0xFF0F172A).withOpacity(0.65),
                          ),
                        ),
                        Center(
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
                    ),
            ),
          ),

          // Okunabilirlik İçin Koyu Modern Karartma Katmanı
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black38,
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black87,
                ],
              ),
            ),
          ),

          // ⚡ TIKLANDIĞINDA ORTADA BELİREN SİBERPUNK İKON ⚡
          if (_showCenterIcon)
            Center(
              child: AnimatedOpacity(
                opacity: _showCenterIcon ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0E15).withOpacity(0.8),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFF5E00), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5E00).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),

          // Sol Alt Metin ve Açıklama Alanı (Biraz yukarı taşıdık ki Range Bar'la çakışmasın)
          Positioned(
            left: 16,
            bottom: 60,
            right: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.video.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.video.caption,
                  style: const TextStyle(
                    color: Color(0xFF8E92B2),
                    fontSize: 14,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Sağ Aksiyon Butonları Modülü
          VideoActionButtons(video: widget.video),

          // ⚡ EN ALTTA: Sessize Alma Butonu, Neon Range Bar ve İleri/Geri Sarma Okları ⚡
          if (_isInitialized)
            VideoPlayerControls(
              controller: _controller,
              isMuted: _isMuted,
              onToggleMute: _toggleMute,
              onSeekForward: _seekForward,
              onSeekBackward: _seekBackward,
            ),
        ],
      ),
    );
  }
}