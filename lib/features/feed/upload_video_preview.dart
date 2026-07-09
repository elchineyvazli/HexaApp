// lib/features/feed/upload_video_preview.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class UploadVideoPreview extends StatefulWidget {
  final File? videoFile;
  final VoidCallback onPickVideo;

  const UploadVideoPreview({
    super.key,
    required this.videoFile,
    required this.onPickVideo,
  });

  @override
  State<UploadVideoPreview> createState() => _UploadVideoPreviewState();
}

class _UploadVideoPreviewState extends State<UploadVideoPreview> {
  VideoPlayerController? _controller;

  @override
  void didUpdateWidget(UploadVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoFile != widget.videoFile) {
      _initController();
    }
  }

  void _initController() {
    _controller?.dispose();
    if (widget.videoFile != null) {
      _controller = VideoPlayerController.file(widget.videoFile!)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _controller?.setLooping(true);
            _controller?.play();
          }
        });
    } else {
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPickVideo,
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: widget.videoFile == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_library_rounded,
                      color: Colors.white54,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Galeriden Bir Video Seç',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_controller != null && _controller!.value.isInitialized)
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller!.value.size.width,
                          height: _controller!.value.size.height,
                          child: VideoPlayer(_controller!),
                        ),
                      )
                    else
                      const Center(
                        child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
                      ),
                    // Değiştir İkonu (Sağ Üst Köşe)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}