import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../upload_service.dart';
import '../video_upload_preparer.dart';

final uploadScreenControllerProvider =
    StateNotifierProvider.autoDispose<
      UploadScreenController,
      UploadScreenState
    >((ref) {
      return UploadScreenController(
        picker: ImagePicker(),
        preparer: const VideoUploadPreparer(),
        uploadService: ref.watch(uploadServiceProvider),
      );
    });

enum UploadScreenPhase { idle, preparing, uploading }

@immutable
class UploadScreenState {
  const UploadScreenState({
    this.phase = UploadScreenPhase.idle,
    this.preparedVideo,
    this.progress,
    this.message = '',
    this.errorMessage,
  });

  final UploadScreenPhase phase;
  final PreparedVideoUpload? preparedVideo;
  final double? progress;
  final String message;
  final String? errorMessage;

  bool get isBusy => phase != UploadScreenPhase.idle;

  bool get isPreparing {
    return phase == UploadScreenPhase.preparing;
  }

  bool get isUploading {
    return phase == UploadScreenPhase.uploading;
  }

  bool get canPublish {
    return !isBusy && preparedVideo != null;
  }

  UploadScreenState copyWith({
    UploadScreenPhase? phase,
    PreparedVideoUpload? preparedVideo,
    bool clearPreparedVideo = false,
    double? progress,
    bool clearProgress = false,
    String? message,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UploadScreenState(
      phase: phase ?? this.phase,
      preparedVideo: clearPreparedVideo
          ? null
          : preparedVideo ?? this.preparedVideo,
      progress: clearProgress ? null : progress ?? this.progress,
      message: message ?? this.message,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class UploadScreenController extends StateNotifier<UploadScreenState> {
  UploadScreenController({
    required ImagePicker picker,
    required VideoUploadPreparer preparer,
    required UploadService uploadService,
  }) : _picker = picker,
       _preparer = preparer,
       _uploadService = uploadService,
       super(const UploadScreenState());

  final ImagePicker _picker;
  final VideoUploadPreparer _preparer;
  final UploadService _uploadService;

  int _operationId = 0;
  bool _disposed = false;

  Future<bool> pickVideo() async {
    if (state.isBusy || _disposed) {
      return false;
    }

    XFile? pickedFile;

    try {
      pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    } catch (error) {
      _setError('Video seçici açılamadı: ${_shortError(error)}');
      return false;
    }

    if (pickedFile == null || _disposed) {
      return false;
    }

    final operationId = ++_operationId;
    final previousVideo = state.preparedVideo;

    state = state.copyWith(
      phase: UploadScreenPhase.preparing,
      clearPreparedVideo: true,
      progress: 0.02,
      message: 'Video inceleniyor',
      clearError: true,
    );

    await previousVideo?.deleteTemporaryFile();

    try {
      final preparedVideo = await _preparer.prepare(
        File(pickedFile.path),
        onProgress: (progress) {
          if (!_isCurrent(operationId)) {
            return;
          }

          state = state.copyWith(
            progress: progress.value,
            message: progress.message,
          );
        },
      );

      if (!_isCurrent(operationId)) {
        await preparedVideo.deleteTemporaryFile();
        return false;
      }

      state = state.copyWith(
        phase: UploadScreenPhase.idle,
        preparedVideo: preparedVideo,
        clearProgress: true,
        message: '',
      );

      return true;
    } on VideoPreparationException catch (error) {
      if (!_isCurrent(operationId)) {
        return false;
      }

      state = state.copyWith(
        phase: UploadScreenPhase.idle,
        clearProgress: true,
        message: '',
        errorMessage: error.isCancelled
            ? 'Video hazırlama durduruldu.'
            : error.message,
      );

      return false;
    } catch (error) {
      if (!_isCurrent(operationId)) {
        return false;
      }

      state = state.copyWith(
        phase: UploadScreenPhase.idle,
        clearProgress: true,
        message: '',
        errorMessage: 'Video hazırlanamadı: ${_shortError(error)}',
      );

      return false;
    }
  }

  Future<bool> upload(String caption) async {
    final preparedVideo = state.preparedVideo;

    if (_disposed || state.isBusy) {
      return false;
    }

    if (preparedVideo == null) {
      _setError('Önce bir video seçmelisin.');
      return false;
    }

    final operationId = ++_operationId;

    state = state.copyWith(
      phase: UploadScreenPhase.uploading,
      progress: 0,
      message: 'Yayın hazırlanıyor',
      clearError: true,
    );

    try {
      await for (final event in _uploadService.uploadVideo(
        preparedVideo: preparedVideo,
        caption: caption,
      )) {
        if (!_isCurrent(operationId)) {
          return false;
        }

        state = state.copyWith(progress: event.value, message: event.message);
      }

      if (!_isCurrent(operationId)) {
        return false;
      }

      await preparedVideo.deleteTemporaryFile();

      if (!_isCurrent(operationId)) {
        return false;
      }

      state = state.copyWith(
        phase: UploadScreenPhase.idle,
        clearPreparedVideo: true,
        clearProgress: true,
        message: '',
      );

      return true;
    } on VideoUploadException catch (error) {
      if (!_isCurrent(operationId)) {
        return false;
      }

      state = state.copyWith(
        phase: UploadScreenPhase.idle,
        clearProgress: true,
        message: '',
        errorMessage: error.isCancelled
            ? 'Video yükleme durduruldu.'
            : error.message,
      );

      return false;
    } catch (error) {
      if (!_isCurrent(operationId)) {
        return false;
      }

      state = state.copyWith(
        phase: UploadScreenPhase.idle,
        clearProgress: true,
        message: '',
        errorMessage: 'Video yüklenemedi: ${_shortError(error)}',
      );

      return false;
    }
  }

  Future<void> removeVideo() async {
    if (state.isBusy || _disposed) {
      return;
    }

    _operationId++;

    final preparedVideo = state.preparedVideo;

    state = state.copyWith(
      clearPreparedVideo: true,
      clearProgress: true,
      message: '',
      clearError: true,
    );

    await preparedVideo?.deleteTemporaryFile();
  }

  Future<void> cancelActiveOperation() async {
    if (!state.isBusy || _disposed) {
      return;
    }

    final activePhase = state.phase;

    _operationId++;

    state = state.copyWith(
      phase: UploadScreenPhase.idle,
      clearProgress: true,
      message: '',
    );

    if (activePhase == UploadScreenPhase.preparing) {
      await _preparer.cancelCompression();
      return;
    }

    if (activePhase == UploadScreenPhase.uploading) {
      await _uploadService.cancelActiveUpload();
    }
  }

  void clearError() {
    if (state.errorMessage == null) {
      return;
    }

    state = state.copyWith(clearError: true);
  }

  void _setError(String message) {
    if (_disposed) {
      return;
    }

    state = state.copyWith(errorMessage: message);
  }

  bool _isCurrent(int operationId) {
    return !_disposed && operationId == _operationId;
  }

  String _shortError(Object error) {
    final value = error.toString().trim();

    return value.length <= 130 ? value : '${value.substring(0, 130)}…';
  }

  @override
  void dispose() {
    _disposed = true;
    _operationId++;

    unawaited(_preparer.cancelCompression());
    unawaited(_uploadService.cancelActiveUpload());
    unawaited(state.preparedVideo?.deleteTemporaryFile());

    super.dispose();
  }
}
