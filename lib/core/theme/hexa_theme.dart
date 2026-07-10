import 'package:flutter/material.dart';

/// Hexa'nın açık, yumuşak ve modern renk sistemi.
abstract final class HexaColors {
  static const Color background = Color(0xFFFAF9F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF2F5F3);
  static const Color surfaceStrong = Color(0xFFE9EEEB);

  static const Color ink = Color(0xFF17202A);
  static const Color inkMuted = Color(0xFF667085);
  static const Color inkSoft = Color(0xFF98A2B3);

  /// Kalp biçimli Signal sisteminin ana rengi.
  static const Color signal = Color(0xFFD83A56);
  static const Color signalSoft = Color(0xFFFFE9ED);
  static const Color signalStrong = Color(0xFFB92543);

  static const Color mint = Color(0xFFBFE8D8);
  static const Color mintSoft = Color(0xFFEAF8F2);
  static const Color lavender = Color(0xFFD8D0F4);
  static const Color lavenderSoft = Color(0xFFF1EEFC);

  static const Color border = Color(0xFFE1E7E4);
  static const Color borderStrong = Color(0xFFCBD5D0);
  static const Color success = Color(0xFF23856D);
  static const Color warning = Color(0xFFB26B13);
  static const Color error = Color(0xFFB42318);
}

abstract final class HexaSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class HexaRadius {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;
}

class HexaTheme {
  HexaTheme._();

  // Eski dosyalardaki kullanımları kırmamak için geriye uyumlu adlar.
  static const Color primaryColor = HexaColors.signal;
  static const Color backgroundColor = HexaColors.background;
  static const Color surfaceColor = HexaColors.surface;
  static const Color textPrimary = HexaColors.ink;
  static const Color textSecondary = HexaColors.inkMuted;
  static const Color accentColor = HexaColors.lavender;

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: HexaColors.signal,
      brightness: Brightness.light,
    ).copyWith(
      primary: HexaColors.signal,
      onPrimary: Colors.white,
      primaryContainer: HexaColors.signalSoft,
      onPrimaryContainer: HexaColors.ink,
      secondary: HexaColors.mint,
      onSecondary: HexaColors.ink,
      secondaryContainer: HexaColors.mintSoft,
      onSecondaryContainer: HexaColors.ink,
      tertiary: HexaColors.lavender,
      onTertiary: HexaColors.ink,
      tertiaryContainer: HexaColors.lavenderSoft,
      onTertiaryContainer: HexaColors.ink,
      surface: HexaColors.surface,
      onSurface: HexaColors.ink,
      error: HexaColors.error,
      onError: Colors.white,
      outline: HexaColors.borderStrong,
      outlineVariant: HexaColors.border,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: HexaColors.background,
      canvasColor: HexaColors.background,
      dividerColor: HexaColors.border,
      disabledColor: HexaColors.inkSoft,
    );

    final textTheme = base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        color: HexaColors.ink,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.4,
      ),
      displayMedium: base.textTheme.displayMedium?.copyWith(
        color: HexaColors.ink,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        color: HexaColors.ink,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        color: HexaColors.ink,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        color: HexaColors.ink,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        color: HexaColors.ink,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        color: HexaColors.ink,
        height: 1.45,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: HexaColors.ink,
        height: 1.42,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        color: HexaColors.inkMuted,
        height: 1.35,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );

    OutlineInputBorder inputBorder(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(HexaRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: HexaColors.background,
        foregroundColor: HexaColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: HexaColors.ink),
        actionsIconTheme: IconThemeData(color: HexaColors.ink),
        titleTextStyle: TextStyle(
          color: HexaColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: HexaColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: HexaColors.signalSoft,
        iconTheme: MaterialStateProperty.resolveWith<IconThemeData>((states) {
          final isSelected = states.contains(MaterialState.selected);
          return IconThemeData(
            color: isSelected ? HexaColors.signal : HexaColors.inkMuted,
            size: isSelected ? 27 : 25,
          );
        }),
        labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>((states) {
          final isSelected = states.contains(MaterialState.selected);
          return TextStyle(
            color: isSelected ? HexaColors.signal : HexaColors.inkMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HexaColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: HexaColors.inkSoft),
        labelStyle: const TextStyle(color: HexaColors.inkMuted),
        floatingLabelStyle: const TextStyle(
          color: HexaColors.signal,
          fontWeight: FontWeight.w700,
        ),
        border: inputBorder(HexaColors.border),
        enabledBorder: inputBorder(HexaColors.border),
        focusedBorder: inputBorder(HexaColors.signal, width: 1.5),
        errorBorder: inputBorder(HexaColors.error),
        focusedErrorBorder: inputBorder(HexaColors.error, width: 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: HexaColors.signal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: HexaColors.surfaceStrong,
          disabledForegroundColor: HexaColors.inkSoft,
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HexaRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          foregroundColor: HexaColors.ink,
          side: const BorderSide(color: HexaColors.borderStrong),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HexaRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: HexaColors.signal,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HexaRadius.sm),
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: HexaColors.inkMuted),
      dividerTheme: const DividerThemeData(
        color: HexaColors.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: HexaColors.signal,
        linearTrackColor: HexaColors.signalSoft,
        circularTrackColor: HexaColors.signalSoft,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: HexaColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        actionTextColor: HexaColors.mint,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HexaRadius.md),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: HexaColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: HexaColors.surface,
        modalBarrierColor: Color(0x660B141B),
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: HexaColors.borderStrong,
      ),
    );
  }

  /// Geçiş sürecinde eski `darkTheme` çağrılarını kırmaz.
  static ThemeData get darkTheme => lightTheme;
}
