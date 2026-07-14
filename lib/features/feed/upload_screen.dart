import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'feed_repository.dart';
import 'upload_form_fields.dart';
import 'upload_service.dart';
import 'upload_video_preview.dart';
import 'video_upload_preparer.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() {
    return _UploadScreenState();
  }
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final TextEditingController _captionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  final VideoUploadPreparer _preparer = const VideoUploadPreparer();

  PreparedVideoUpload? _preparedVideo;

  bool _isPreparing = false;
  bool _isUploading = false;

  double _progress = 0;
  String _progressMessage = 'Video yükleniyor';

  bool get _isBusy => _isPreparing || _isUploading;

  Future<void> _pickVideo() async {
    if (_isBusy) {
      return;
    }

    final pickedVideo = await _picker.pickVideo(source: ImageSource.gallery);

    if (pickedVideo == null || !mounted) {
      return;
    }

    setState(() {
      _isPreparing = true;
      _preparedVideo = null;
      _progress = 0;
    });

    try {
      final prepared = await _preparer.prepare(File(pickedVideo.path));

      if (!mounted) {
        return;
      }

      setState(() {
        _preparedVideo = prepared;
      });
    } on VideoPreparationException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Video hazırlanamadı: ${_shortError(error)}');
    } finally {
      if (mounted) {
        setState(() {
          _isPreparing = false;
        });
      }
    }
  }

  Future<void> _uploadVideo() async {
    final prepared = _preparedVideo;
    final caption = _captionController.text.trim();

    if (_isBusy) {
      return;
    }

    if (prepared == null) {
      _showMessage('Önce bir video seçmelisin.');
      return;
    }

    if (caption.isEmpty) {
      _showMessage('Video açıklaması boş bırakılamaz.');
      return;
    }

    setState(() {
      _isUploading = true;
      _progress = 0;
      _progressMessage = 'Video yükleniyor';
    });

    try {
      await for (final event
          in ref
              .read(uploadServiceProvider)
              .uploadVideo(preparedVideo: prepared, caption: caption)) {
        if (!mounted) {
          return;
        }

        setState(() {
          _progress = event.value.clamp(0, 1).toDouble();
          _progressMessage = event.message;
        });
      }

      ref.invalidate(feedControllerProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video başarıyla yayınlandı.')),
      );

      Navigator.of(context).pop(true);
    } on VideoUploadException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Video yüklenemedi: ${_shortError(error)}');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _removeVideo() {
    if (_isBusy) {
      return;
    }

    setState(() {
      _preparedVideo = null;
      _progress = 0;
    });
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _shortError(Object error) {
    final text = error.toString().trim();

    if (text.length <= 140) {
      return text;
    }

    return '${text.substring(0, 140)}...';
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPreparing) {
      return const _BusyUploadView(message: 'Video hazırlanıyor');
    }

    if (_isUploading) {
      return _BusyUploadView(message: _progressMessage, progress: _progress);
    }

    final prepared = _preparedVideo;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Yeni video'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UploadVideoPreview(
              videoFile: prepared?.videoFile,
              onPickVideo: _pickVideo,
            ),
            if (prepared != null) ...[
              const SizedBox(height: 16),
              _PreparedVideoInfo(video: prepared, onRemove: _removeVideo),
            ],
            const SizedBox(height: 24),
            UploadFormFields(
              captionController: _captionController,
              onSubmit: _uploadVideo,
              isSubmitEnabled: prepared != null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreparedVideoInfo extends StatelessWidget {
  const _PreparedVideoInfo({required this.video, required this.onRemove});

  final PreparedVideoUpload video;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: video.durationMs);

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    final sizeMb = video.fileSizeBytes / (1024 * 1024);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              video.thumbnailBytes,
              width: 84,
              height: 112,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Video hazır',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text('${sizeMb.toStringAsFixed(1)} MB', style: _metadataStyle),
                Text(
                  '$minutes:${seconds.toString().padLeft(2, '0')}',
                  style: _metadataStyle,
                ),
                Text('${video.width} × ${video.height}', style: _metadataStyle),
                Text(
                  'Oran: ${video.aspectRatio.toStringAsFixed(3)}',
                  style: _metadataStyle,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Videoyu kaldır',
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  static const TextStyle _metadataStyle = TextStyle(
    color: Color(0xB3FFFFFF),
    fontSize: 12,
    height: 1.55,
  );
}

class _BusyUploadView extends StatelessWidget {
  const _BusyUploadView({required this.message, this.progress});

  final String message;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final percentage = progress == null ? null : (progress! * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              value: progress,
              color: const Color(0xFFFB9BBD),
            ),
            const SizedBox(height: 18),
            Text(
              percentage == null ? message : '$message: %$percentage',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
