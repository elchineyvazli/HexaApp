import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/hexa_theme.dart';

enum HexaAppMode { original, lite }

/// `green`, eski kayıtları ve mevcut ekran referanslarını geçici olarak
/// kırmamak için tutulur. Yeni Settings ekranında gösterilmeyecektir.
enum HexaThemePreference { system, light, dark, green }

@immutable
class AppSettingsState {
  const AppSettingsState({
    this.isLoaded = false,
    this.isBusy = false,
    this.appMode = HexaAppMode.original,
    this.themePreference = HexaThemePreference.system,
    this.ambientMusicEnabled = true,
    this.reduceMotion = false,
    this.errorMessage,
  });

  final bool isLoaded;
  final bool isBusy;

  final HexaAppMode appMode;
  final HexaThemePreference themePreference;

  final bool ambientMusicEnabled;
  final bool reduceMotion;

  final String? errorMessage;

  bool get isLite => appMode == HexaAppMode.lite;

  /// Lite modunda komşu videolar belleğe hazırlanmaz.
  bool get preloadAdjacentVideos => !isLite;

  /// Hem Lite modu hem erişilebilirlik tercihi ağır hareketleri kapatabilir.
  bool get allowAnimatedArtifacts => !isLite && !reduceMotion;

  /// Ambient ses; Lite modu veya kullanıcı tercihiyle kapanabilir.
  bool get allowBackgroundMusic {
    return !isLite && ambientMusicEnabled;
  }

  bool get showAdvancedAnalytics => !isLite;

  int get preferredMobileVideoHeight => isLite ? 540 : 720;

  int get cacheLimitMb => isLite ? 120 : 500;

  bool get processSignals => true;
  bool get processComments => true;
  bool get processFollows => true;
  bool get processViews => true;
  bool get processNotifications => true;

  AppSettingsState copyWith({
    bool? isLoaded,
    bool? isBusy,
    HexaAppMode? appMode,
    HexaThemePreference? themePreference,
    bool? ambientMusicEnabled,
    bool? reduceMotion,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppSettingsState(
      isLoaded: isLoaded ?? this.isLoaded,
      isBusy: isBusy ?? this.isBusy,
      appMode: appMode ?? this.appMode,
      themePreference: themePreference ?? this.themePreference,
      ambientMusicEnabled: ambientMusicEnabled ?? this.ambientMusicEnabled,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsController, AppSettingsState>((ref) {
      final controller = AppSettingsController();

      unawaited(controller.load());

      return controller;
    });

class AppSettingsController extends StateNotifier<AppSettingsState> {
  AppSettingsController() : super(const AppSettingsState());

  static const String _appModeKey = 'hexa_app_mode';
  static const String _themePreferenceKey = 'hexa_theme_preference';
  static const String _ambientMusicEnabledKey = 'hexa_ambient_music_enabled';
  static const String _reduceMotionKey = 'hexa_reduce_motion';

  SharedPreferences? _preferences;
  Future<void>? _loadOperation;

  Future<void> load() {
    return _loadOperation ??= _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final preferences = await _getPreferences();

      final appMode = _parseAppMode(preferences.getString(_appModeKey));

      final themePreference = _parseThemePreference(
        preferences.getString(_themePreferenceKey),
      );

      final ambientMusicEnabled =
          preferences.getBool(_ambientMusicEnabledKey) ?? true;

      final reduceMotion = preferences.getBool(_reduceMotionKey) ?? false;

      state = state.copyWith(
        isLoaded: true,
        appMode: appMode,
        themePreference: themePreference,
        ambientMusicEnabled: ambientMusicEnabled,
        reduceMotion: reduceMotion,
        clearError: true,
      );
    } catch (error, stackTrace) {
      _logFailure(
        message: 'Ayarlar yüklenemedi.',
        error: error,
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        isLoaded: true,
        errorMessage: 'Ayarların bir bölümü yüklenemedi.',
      );
    }
  }

  Future<void> setAppMode(HexaAppMode mode) async {
    if (mode == state.appMode || state.isBusy) {
      return;
    }

    state = state.copyWith(isBusy: true, clearError: true);

    try {
      if (mode == HexaAppMode.lite) {
        await _clearTemporaryFilesInternal();
      }

      final preferences = await _getPreferences();

      await preferences.setString(_appModeKey, mode.name);

      state = state.copyWith(appMode: mode, isBusy: false);
    } catch (error, stackTrace) {
      _logFailure(
        message: 'Hexa modu değiştirilemedi.',
        error: error,
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Hexa modu şu anda değiştirilemiyor.',
      );
    }
  }

  Future<void> setThemePreference(HexaThemePreference preference) async {
    if (preference == state.themePreference) {
      return;
    }

    final previousPreference = state.themePreference;

    state = state.copyWith(themePreference: preference, clearError: true);

    try {
      final preferences = await _getPreferences();

      await preferences.setString(_themePreferenceKey, preference.name);
    } catch (error, stackTrace) {
      _logFailure(
        message: 'Tema tercihi kaydedilemedi.',
        error: error,
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        themePreference: previousPreference,
        errorMessage: 'Tema tercihi kaydedilemedi.',
      );
    }
  }

  Future<void> setAmbientMusicEnabled(bool enabled) async {
    if (enabled == state.ambientMusicEnabled) {
      return;
    }

    final previousValue = state.ambientMusicEnabled;

    state = state.copyWith(ambientMusicEnabled: enabled, clearError: true);

    try {
      final preferences = await _getPreferences();

      await preferences.setBool(_ambientMusicEnabledKey, enabled);
    } catch (error, stackTrace) {
      _logFailure(
        message: 'Ambient müzik tercihi kaydedilemedi.',
        error: error,
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        ambientMusicEnabled: previousValue,
        errorMessage: 'Müzik tercihi kaydedilemedi.',
      );
    }
  }

  Future<void> setReduceMotion(bool enabled) async {
    if (enabled == state.reduceMotion) {
      return;
    }

    final previousValue = state.reduceMotion;

    state = state.copyWith(reduceMotion: enabled, clearError: true);

    try {
      final preferences = await _getPreferences();

      await preferences.setBool(_reduceMotionKey, enabled);
    } catch (error, stackTrace) {
      _logFailure(
        message: 'Hareket tercihi kaydedilemedi.',
        error: error,
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        reduceMotion: previousValue,
        errorMessage: 'Hareket tercihi kaydedilemedi.',
      );
    }
  }

  Future<void> clearTemporaryFiles() async {
    if (state.isBusy) {
      return;
    }

    state = state.copyWith(isBusy: true, clearError: true);

    try {
      await _clearTemporaryFilesInternal();

      state = state.copyWith(isBusy: false);
    } catch (error, stackTrace) {
      _logFailure(
        message: 'Geçici dosyalar temizlenemedi.',
        error: error,
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Geçici dosyalar temizlenemedi.',
      );
    }
  }

  void clearError() {
    if (state.errorMessage == null) {
      return;
    }

    state = state.copyWith(clearError: true);
  }

  Future<SharedPreferences> _getPreferences() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<void> _clearTemporaryFilesInternal() async {
    await DefaultCacheManager().emptyCache();

    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  HexaAppMode _parseAppMode(String? value) {
    for (final mode in HexaAppMode.values) {
      if (mode.name == value) {
        return mode;
      }
    }

    return HexaAppMode.original;
  }

  HexaThemePreference _parseThemePreference(String? value) {
    // Eski yeşil tema kaydı yeni açık temaya taşınır.
    if (value == HexaThemePreference.green.name) {
      return HexaThemePreference.light;
    }

    for (final preference in HexaThemePreference.values) {
      if (preference.name == value) {
        return preference;
      }
    }

    return HexaThemePreference.system;
  }

  void _logFailure({
    required String message,
    required Object error,
    required StackTrace stackTrace,
  }) {
    debugPrint('$message $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

extension AppSettingsThemeExtension on AppSettingsState {
  ThemeMode get materialThemeMode {
    switch (themePreference) {
      case HexaThemePreference.system:
        return ThemeMode.system;

      case HexaThemePreference.light:
      case HexaThemePreference.green:
        return ThemeMode.light;

      case HexaThemePreference.dark:
        return ThemeMode.dark;
    }
  }

  ThemeData get lightTheme => HexaTheme.lightTheme;

  ThemeData get darkTheme => HexaTheme.darkTheme;
}
