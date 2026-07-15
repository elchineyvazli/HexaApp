import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexa/core/theme/hexa_theme.dart';
import 'package:hexa/features/auth/presentation/widgets/auth_background.dart';
import 'package:image_picker/image_picker.dart';

import 'feed_repository.dart';
import 'upload_form_fields.dart';
import 'upload_service.dart';
import 'upload_video_preview.dart';
import 'video_upload_preparer.dart';
import 'widgets/prepared_video_info.dart';
import 'widgets/upload_layout_widgets.dart';

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

  double? _preparationProgress;
  String _preparationMessage = 'Video hazırlanıyor';

  bool get _isBusy => _isPreparing || _isUploading;

  Future<void> _pickVideo() async {
    if (_isBusy) {
      return;
    }

    final pickedVideo = await _picker.pickVideo(source: ImageSource.gallery);

    if (pickedVideo == null || !mounted) {
      return;
    }

    final previousVideo = _preparedVideo;

    setState(() {
      _isPreparing = true;
      _preparedVideo = null;
      _progress = 0;
      _preparationProgress = null;
      _preparationMessage = 'Video inceleniyor';
    });

    await previousVideo?.deleteTemporaryFile();

    try {
      final prepared = await _preparer.prepare(
        File(pickedVideo.path),
        onProgress: (progress) {
          if (!mounted) {
            return;
          }

          setState(() {
            _preparationProgress = progress.value.clamp(0, 1).toDouble();
            _preparationMessage = progress.message;
          });
        },
      );

      if (!mounted) {
        await prepared.deleteTemporaryFile();
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
          _preparationProgress = null;
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

    var uploadSucceeded = false;

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

      uploadSucceeded = true;
      ref.invalidate(feedControllerProvider);

      await prepared.deleteTemporaryFile();

      if (!mounted) {
        return;
      }

      setState(() {
        _preparedVideo = null;
      });

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

      if (uploadSucceeded) {
        await prepared.deleteTemporaryFile();
      }
    }
  }

  Future<void> _removeVideo() async {
    if (_isBusy) {
      return;
    }

    final prepared = _preparedVideo;

    setState(() {
      _preparedVideo = null;
      _progress = 0;
    });

    await prepared?.deleteTemporaryFile();
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
    unawaited(_preparer.cancelCompression());
    unawaited(_preparedVideo?.deleteTemporaryFile());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPreparing) {
      return BusyUploadView(
        message: _preparationMessage,
        progress: _preparationProgress,
        icon: Icons.video_settings_rounded,
      );
    }

    if (_isUploading) {
      return BusyUploadView(
        message: _progressMessage,
        progress: _progress,
        icon: Icons.cloud_upload_rounded,
      );
    }

    final prepared = _preparedVideo;

    return Scaffold(
      backgroundColor: HexaColors.background,
      body: Stack(
        children: [
          const AuthBackground(),
          SafeArea(
            child: Column(
              children: [
                const UploadHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      HexaSpacing.md,
                      HexaSpacing.sm,
                      HexaSpacing.md,
                      HexaSpacing.xl,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            UploadSection(
                              title: 'Videonu seç',
                              description:
                                  'Çözünürlüğü korunur ve gerekiyorsa yüklemeden önce sıkıştırılır.',
                              icon: Icons.video_library_rounded,
                              child: UploadVideoPreview(
                                videoFile: prepared?.videoFile,
                                onPickVideo: _pickVideo,
                              ),
                            ),
                            if (prepared != null) ...[
                              const SizedBox(height: HexaSpacing.md),
                              PreparedVideoInfo(
                                video: prepared,
                                onRemove: _removeVideo,
                              ),
                            ],
                            const SizedBox(height: HexaSpacing.md),
                            UploadSection(
                              title: 'Videonu anlat',
                              description:
                                  'İnsanlara videonun neden değerli olduğunu kısa ve açık biçimde anlat.',
                              icon: Icons.edit_note_rounded,
                              child: UploadFormFields(
                                captionController: _captionController,
                                onSubmit: _uploadVideo,
                                isSubmitEnabled: prepared != null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
