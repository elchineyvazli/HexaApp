// lib/features/feed/upload_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'upload_video_preview.dart';
import 'upload_form_fields.dart';
import 'upload_service.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  File? _videoFile;
  final _captionController = TextEditingController();
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  final _picker = ImagePicker();

  Future<void> _pickVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null || _captionController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await for (final progress
          in ref
              .read(uploadServiceProvider)
              .uploadVideo(
                videoFile: _videoFile!,
                description: _captionController.text.trim(),
                onUrlReady: (url) => debugPrint("URL hazır: $url"),
              )) {
        setState(() => _uploadProgress = progress);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video siber ağa başarıyla yüklendi! 🚀'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Yeni İçerik Yükle',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _uploadProgress,
                    color: const Color(0xFFFF5E00),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sinyal gönderiliyor: %${(_uploadProgress * 100).toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UploadVideoPreview(
                    videoFile: _videoFile,
                    onPickVideo: _pickVideo,
                  ),
                  const SizedBox(height: 24),
                  UploadFormFields(
                    captionController: _captionController,
                    onSubmit: _uploadVideo,
                    isSubmitEnabled: _videoFile != null,
                  ),
                ],
              ),
            ),
    );
  }
}
