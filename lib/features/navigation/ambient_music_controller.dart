import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ambient_wave_generator.dart';

final ambientMusicControllerProvider =
    StateNotifierProvider<AmbientMusicController, AmbientMusicState>((ref) {
      return AmbientMusicController();
    });

@immutable
class AmbientMusicState {
  const AmbientMusicState({
    this.enabled = true,
    this.isReady = false,
    this.isPlaying = false,
    this.isSuppressed = true,
    this.hasError = false,
    this.visualIntensity = 0.0, // 🎨 Dalga animasyonu için
  });

  final bool enabled;
  final bool isReady;
  final bool isPlaying;
  final bool isSuppressed;
  final bool hasError;
  final double visualIntensity; // 0.0 = sessiz/gizli, 1.0 = tam akış

  AmbientMusicState copyWith({
    bool? enabled,
    bool? isReady,
    bool? isPlaying,
    bool? isSuppressed,
    bool? hasError,
    double? visualIntensity,
  }) {
    return AmbientMusicState(
      enabled: enabled ?? this.enabled,
      isReady: isReady ?? this.isReady,
      isPlaying: isPlaying ?? this.isPlaying,
      isSuppressed: isSuppressed ?? this.isSuppressed,
      hasError: hasError ?? this.hasError,
      visualIntensity: visualIntensity ?? this.visualIntensity,
    );
  }
}

class AmbientMusicController extends StateNotifier<AmbientMusicState> {
  AmbientMusicController() : super(const AmbientMusicState()) {
    unawaited(_initialize());
  }

  static const String preferenceKey = 'hexa_ambient_music_enabled';
  static const double _targetVolume = 0.16;

  final AudioPlayer _player = AudioPlayer();
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  bool _isApplicationActive = true;
  bool _hasActiveMediaSound = true;
  bool _isDisposed = false;

  int _fadeGeneration = 0;

  Future<void> _initialize() async {
    try {
      final enabled =
          await _preferences.getBool(preferenceKey) ?? state.enabled;

      if (_isDisposed) {
        return;
      }

      state = state.copyWith(enabled: enabled, hasError: false);

      final wavBytes = await Isolate.run<Uint8List>(buildHopeLofiWav);

      if (_isDisposed) {
        return;
      }

      final file = File(
        '${Directory.systemTemp.path}/hexa_hope_ambient_v1.wav',
      );

      await file.writeAsBytes(wavBytes, flush: true);

      if (_isDisposed) {
        return;
      }

      await _player.setFilePath(file.path);
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(0);

      if (_isDisposed) {
        return;
      }

      state = state.copyWith(isReady: true, hasError: false);

      await _reconcilePlayback();
    } catch (_) {
      if (_isDisposed) {
        return;
      }

      state = state.copyWith(isReady: false, isPlaying: false, hasError: true);
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (state.enabled == enabled) {
      return;
    }

    state = state.copyWith(enabled: enabled);

    await _preferences.setBool(preferenceKey, enabled);

    await _reconcilePlayback();
  }

  Future<void> toggle() {
    return setEnabled(!state.enabled);
  }

  Future<void> setMediaSoundActive(bool isActive) async {
    if (_hasActiveMediaSound == isActive) {
      return;
    }

    _hasActiveMediaSound = isActive;

    state = state.copyWith(isSuppressed: isActive);

    await _reconcilePlayback();
  }

  Future<void> setApplicationActive(bool isActive) async {
    if (_isApplicationActive == isActive) {
      return;
    }

    _isApplicationActive = isActive;

    await _reconcilePlayback();
  }

  Future<void> retry() async {
    if (state.isReady || _isDisposed) {
      return;
    }

    state = state.copyWith(hasError: false);

    await _initialize();
  }

  bool get _shouldPlay {
    return state.enabled &&
        state.isReady &&
        _isApplicationActive &&
        !_hasActiveMediaSound;
  }

  Future<void> _reconcilePlayback() async {
    if (_isDisposed || !state.isReady) {
      return;
    }

    // 🎨 Görsel yoğunluğu hedefe göre anında güncelle
    final targetVisual = _shouldPlay ? 1.0 : 0.0;
    if (state.visualIntensity != targetVisual) {
      state = state.copyWith(visualIntensity: targetVisual);
    }

    if (_shouldPlay) {
      await _fadeTo(_targetVolume, pauseAtEnd: false);
    } else {
      await _fadeTo(0, pauseAtEnd: true);
    }
  }

  Future<void> _fadeTo(double target, {required bool pauseAtEnd}) async {
    final generation = ++_fadeGeneration;
    final start = _player.volume;

    const steps = 14;
    const stepDuration = Duration(milliseconds: 28);

    if (target > 0 && !_player.playing) {
      unawaited(_player.play());

      if (!_isDisposed) {
        state = state.copyWith(isPlaying: true);
      }
    }

    for (var step = 1; step <= steps; step++) {
      if (_isDisposed || generation != _fadeGeneration) {
        return;
      }

      final progress = step / steps;
      final eased = Curves.easeInOutCubic.transform(progress);
      final volume = start + ((target - start) * eased);

      await _player.setVolume(volume.clamp(0, 1).toDouble());

      await Future<void>.delayed(stepDuration);
    }

    if (_isDisposed || generation != _fadeGeneration) {
      return;
    }

    if (pauseAtEnd && target == 0) {
      await _player.pause();

      if (!_isDisposed) {
        state = state.copyWith(isPlaying: false);
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _fadeGeneration++;

    unawaited(_player.dispose());

    super.dispose();
  }
}
