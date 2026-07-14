import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/hexa_theme.dart';

enum HexaAppMode { original, lite }

enum HexaThemePreference { system, light, dark, green }

@immutable
class AppSettingsState {
  const AppSettingsState({
    this.isLoaded = false,
    this.isBusy = false,
    this.appMode = HexaAppMode.original,
    this.themePreference = HexaThemePreference.system,
  });

  final bool isLoaded;
  final bool isBusy;
  final HexaAppMode appMode;
  final HexaThemePreference themePreference;

  bool get isLite => appMode == HexaAppMode.lite;

  /// Lite modunda komşu videoları hazırlamayacağız.
  bool get preloadAdjacentVideos => !isLite;

  /// Lite modunda ağır Artefakt animasyonları yerine statik içerik gösterilir.
  bool get allowAnimatedArtifacts => !isLite;

  /// Lite modunda lo-fi kütüphanesi ve indirmeleri yüklenmez.
  bool get allowBackgroundMusic => !isLite;

  /// Lite modunda ağır grafik ve gelişmiş analiz sayfaları gizlenir.
  bool get showAdvancedAnalytics => !isLite;

  /// Bu değer sonraki adımda video oynatıcıya bağlanacak.
  int get preferredMobileVideoHeight => isLite ? 540 : 720;

  /// Bu değer sonraki adımda medya önbelleğine bağlanacak.
  int get cacheLimitMb => isLite ? 120 : 500;

  /// Backend işlemleri Lite modunda da çalışmaya devam eder.
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
  }) {
    return AppSettingsState(
      isLoaded: isLoaded ?? this.isLoaded,
      isBusy: isBusy ?? this.isBusy,
      appMode: appMode ?? this.appMode,
      themePreference: themePreference ?? this.themePreference,
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

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      final appMode = _parseAppMode(preferences.getString(_appModeKey));

      final themePreference = _parseThemePreference(
        preferences.getString(_themePreferenceKey),
      );

      state = state.copyWith(
        isLoaded: true,
        appMode: appMode,
        themePreference: themePreference,
      );
    } catch (error, stackTrace) {
      debugPrint('Ayarlar yüklenemedi: $error');
      debugPrintStack(stackTrace: stackTrace);

      state = state.copyWith(isLoaded: true);
    }
  }

  Future<void> setAppMode(HexaAppMode mode) async {
    if (mode == state.appMode || state.isBusy) {
      return;
    }

    state = state.copyWith(isBusy: true);

    try {
      if (mode == HexaAppMode.lite) {
        await _clearTemporaryFilesInternal();
      }

      final preferences = await SharedPreferences.getInstance();

      await preferences.setString(_appModeKey, mode.name);

      state = state.copyWith(appMode: mode, isBusy: false);
    } catch (error, stackTrace) {
      debugPrint('Hexa modu değiştirilemedi: $error');
      debugPrintStack(stackTrace: stackTrace);

      state = state.copyWith(isBusy: false);

      rethrow;
    }
  }

  Future<void> setThemePreference(HexaThemePreference preference) async {
    if (preference == state.themePreference) {
      return;
    }

    state = state.copyWith(themePreference: preference);

    try {
      final preferences = await SharedPreferences.getInstance();

      await preferences.setString(_themePreferenceKey, preference.name);
    } catch (error, stackTrace) {
      debugPrint('Tema tercihi kaydedilemedi: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> clearTemporaryFiles() async {
    if (state.isBusy) {
      return;
    }

    state = state.copyWith(isBusy: true);

    try {
      await _clearTemporaryFilesInternal();
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<void> _clearTemporaryFilesInternal() async {
    try {
      await DefaultCacheManager().emptyCache();

      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (error, stackTrace) {
      debugPrint('Geçici dosyalar temizlenemedi: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
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
    for (final preference in HexaThemePreference.values) {
      if (preference.name == value) {
        return preference;
      }
    }

    return HexaThemePreference.system;
  }
}

extension AppSettingsThemeExtension on AppSettingsState {
  ThemeMode get materialThemeMode {
    switch (themePreference) {
      case HexaThemePreference.system:
        return ThemeMode.system;
      case HexaThemePreference.light:
        return ThemeMode.light;
      case HexaThemePreference.dark:
        return ThemeMode.dark;
      case HexaThemePreference.green:
        return ThemeMode.light;
    }
  }

  ThemeData get lightTheme {
    if (themePreference == HexaThemePreference.green) {
      return hexaGreenTheme;
    }

    return HexaTheme.lightTheme;
  }

  ThemeData get darkTheme {
    if (themePreference == HexaThemePreference.green) {
      return hexaGreenTheme;
    }

    return hexaDarkTheme;
  }
}

final ThemeData hexaDarkTheme = _buildHexaDarkTheme();

final ThemeData hexaGreenTheme = _buildHexaGreenTheme();

ThemeData _buildHexaDarkTheme() {
  final base = HexaTheme.lightTheme;

  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFB15090),
    brightness: Brightness.dark,
  );

  const background = Color(0xFF171115);
  const surface = Color(0xFF241A21);
  const border = Color(0xFF493342);

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    cardColor: surface,
    dividerColor: border,
    textTheme: base.textTheme.apply(
      bodyColor: const Color(0xFFF9EEF4),
      displayColor: const Color(0xFFF9EEF4),
    ),
    iconTheme: const IconThemeData(color: Color(0xFFF5DDE9)),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: Color(0xFFF9EEF4),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: colorScheme.primaryContainer,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: Color(0xFFFB9BBD),
      unselectedItemColor: Color(0xFFBBA5B1),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: surface,
    ),
  );
}

ThemeData _buildHexaGreenTheme() {
  final base = HexaTheme.lightTheme;

  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF4E7A58),
    brightness: Brightness.light,
  );

  const background = Color(0xFFF3F7F0);
  const surface = Color(0xFFFFFFFF);
  const ink = Color(0xFF17261B);
  const border = Color(0xFFD5E1D2);

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    cardColor: surface,
    dividerColor: border,
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    iconTheme: const IconThemeData(color: Color(0xFF355B3E)),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: colorScheme.primaryContainer,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: Color(0xFF355B3E),
      unselectedItemColor: Color(0xFF728177),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: surface,
    ),
  );
}
