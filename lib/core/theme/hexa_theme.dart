import 'package:flutter/material.dart';

import '../motion/hexa_motion.dart';
import '../motion/hexa_tokens.dart';

export '../motion/hexa_motion.dart';
export '../motion/hexa_tokens.dart';

/// Hexa'nın Material katmanı.
///
/// Bu dosya yalnızca Flutter theme bileşenlerini birleştirir. Renk, boşluk,
/// radius, gölge ve hareket değerleri ilgili token dosyalarında tutulur.
abstract final class HexaTheme {
  // Eski ekranları kırmamak için korunan adlar.
  static const Color primaryColor = HexaColors.signal;
  static const Color backgroundColor = HexaColors.background;
  static const Color surfaceColor = HexaColors.surface;
  static const Color textPrimary = HexaColors.ink;
  static const Color textSecondary = HexaColors.inkMuted;
  static const Color accentColor = HexaColors.mauve;

  static ThemeData get lightTheme => _build(Brightness.light);

  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final background = HexaColors.backgroundFor(brightness);
    final surface = HexaColors.surfaceFor(brightness);
    final surfaceStrong = HexaColors.surfaceStrongFor(brightness);
    final ink = HexaColors.inkFor(brightness);
    final mutedInk = HexaColors.inkMutedFor(brightness);
    final softInk = HexaColors.inkSoftFor(brightness);
    final border = HexaColors.borderFor(brightness);

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: HexaColors.signal,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? HexaColors.hopePink : HexaColors.signalStrong,
          onPrimary: isDark ? HexaColors.earth : HexaColors.white,
          primaryContainer: isDark
              ? HexaColors.surfaceStrongDark
              : HexaColors.signalSoft,
          onPrimaryContainer: ink,
          secondary: HexaColors.mauve,
          onSecondary: HexaColors.white,
          secondaryContainer: isDark
              ? HexaColors.surfaceMutedDark
              : HexaColors.lavenderSoft,
          onSecondaryContainer: ink,
          tertiary: HexaColors.mint,
          onTertiary: HexaColors.earth,
          tertiaryContainer: isDark
              ? HexaColors.surfaceStrongDark
              : HexaColors.mintSoft,
          onTertiaryContainer: ink,
          surface: surface,
          onSurface: ink,
          error: HexaColors.error,
          onError: HexaColors.white,
          outline: isDark ? HexaColors.borderOnDark : HexaColors.borderStrong,
          outlineVariant: border,
          shadow: HexaColors.earth,
          scrim: HexaColors.scrim,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: border,
      disabledColor: softInk,
      focusColor: HexaColors.focusOverlay,
      hoverColor: HexaColors.pressedOverlay,
      highlightColor: HexaColors.pressedOverlay,
      splashColor: HexaColors.pressedOverlay,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: HexaPageTransitionsBuilder(),
          TargetPlatform.iOS: HexaPageTransitionsBuilder(),
          TargetPlatform.macOS: HexaPageTransitionsBuilder(),
          TargetPlatform.windows: HexaPageTransitionsBuilder(),
          TargetPlatform.linux: HexaPageTransitionsBuilder(),
          TargetPlatform.fuchsia: HexaPageTransitionsBuilder(),
        },
      ),
    );

    final textTheme = HexaTypography.build(
      base: base.textTheme,
      brightness: brightness,
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: _appBarTheme(
        background: background,
        ink: ink,
        textTheme: textTheme,
      ),
      navigationBarTheme: _navigationBarTheme(mutedInk: mutedInk),
      inputDecorationTheme: _inputDecorationTheme(
        surface: surface,
        mutedInk: mutedInk,
        softInk: softInk,
        border: border,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: HexaColors.transparent,
        shadowColor: HexaColors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: HexaRadius.borderLg,
          side: BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: HexaColors.transparent,
        shadowColor: HexaColors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: HexaRadius.borderLg),
      ),
      filledButtonTheme: _filledButtonTheme(textTheme, colorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(
        textTheme: textTheme,
        ink: ink,
        border: border,
      ),
      textButtonTheme: _textButtonTheme(textTheme, colorScheme),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
      ),
      iconTheme: IconThemeData(color: mutedInk, size: 24),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: surfaceStrong,
        circularTrackColor: surfaceStrong,
      ),
      switchTheme: _switchTheme(
        colorScheme: colorScheme,
        surfaceStrong: surfaceStrong,
        softInk: softInk,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? HexaColors.surfaceStrongDark
            : HexaColors.earth,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: HexaColors.inkOnDark,
        ),
        actionTextColor: HexaColors.hopePink,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.all(HexaSpacing.md),
        shape: const RoundedRectangleBorder(borderRadius: HexaRadius.borderMd),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: HexaColors.transparent,
        modalBackgroundColor: surface,
        modalBarrierColor: HexaColors.scrim,
        shadowColor: HexaColors.transparent,
        elevation: 0,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(HexaRadius.lg),
          ),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: HexaColors.signalGlow,
        selectionHandleColor: colorScheme.primary,
      ),
    );
  }

  static AppBarTheme _appBarTheme({
    required Color background,
    required Color ink,
    required TextTheme textTheme,
  }) {
    return AppBarTheme(
      backgroundColor: background,
      foregroundColor: ink,
      surfaceTintColor: HexaColors.transparent,
      shadowColor: HexaColors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: ink),
      actionsIconTheme: IconThemeData(color: ink),
      titleTextStyle: textTheme.titleLarge?.copyWith(color: ink),
    );
  }

  static NavigationBarThemeData _navigationBarTheme({required Color mutedInk}) {
    return NavigationBarThemeData(
      backgroundColor: HexaColors.transparent,
      surfaceTintColor: HexaColors.transparent,
      shadowColor: HexaColors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: HexaColors.signalSoft,
      indicatorShape: const StadiumBorder(),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
        final selected = states.contains(WidgetState.selected);

        return IconThemeData(
          color: selected ? HexaColors.plum : mutedInk,
          size: selected ? 26 : 24,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
        final selected = states.contains(WidgetState.selected);

        return TextStyle(
          color: selected ? HexaColors.plum : mutedInk,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        );
      }),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({
    required Color surface,
    required Color mutedInk,
    required Color softInk,
    required Color border,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: HexaSpacing.md,
        vertical: HexaSpacing.md,
      ),
      hintStyle: TextStyle(color: softInk),
      labelStyle: TextStyle(color: mutedInk),
      floatingLabelStyle: const TextStyle(
        color: HexaColors.signalStrong,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      prefixIconColor: mutedInk,
      suffixIconColor: mutedInk,
      border: _inputBorder(border),
      enabledBorder: _inputBorder(border),
      focusedBorder: _inputBorder(HexaColors.signal, width: 1.5),
      errorBorder: _inputBorder(HexaColors.error),
      focusedErrorBorder: _inputBorder(HexaColors.error, width: 1.5),
      disabledBorder: _inputBorder(border),
      errorStyle: const TextStyle(
        color: HexaColors.error,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: HexaRadius.borderMd,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static FilledButtonThemeData _filledButtonTheme(
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(
          horizontal: HexaSpacing.lg,
          vertical: HexaSpacing.sm,
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        disabledBackgroundColor: colorScheme.surfaceContainerHighest,
        disabledForegroundColor: colorScheme.onSurfaceVariant,
        elevation: 0,
        textStyle: textTheme.labelLarge,
        shape: const StadiumBorder(),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme({
    required TextTheme textTheme,
    required Color ink,
    required Color border,
  }) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(
          horizontal: HexaSpacing.lg,
          vertical: HexaSpacing.sm,
        ),
        foregroundColor: ink,
        side: BorderSide(color: border),
        elevation: 0,
        textStyle: textTheme.labelLarge,
        shape: const StadiumBorder(),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme(
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: HexaSpacing.md,
          vertical: HexaSpacing.sm,
        ),
        textStyle: textTheme.labelLarge,
        shape: const StadiumBorder(),
      ),
    );
  }

  static SwitchThemeData _switchTheme({
    required ColorScheme colorScheme,
    required Color surfaceStrong,
    required Color softInk,
  }) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        return states.contains(WidgetState.selected)
            ? colorScheme.onPrimary
            : softInk;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        return states.contains(WidgetState.selected)
            ? colorScheme.primary
            : surfaceStrong;
      }),
      trackOutlineColor: const WidgetStatePropertyAll<Color?>(
        HexaColors.transparent,
      ),
      overlayColor: const WidgetStatePropertyAll<Color?>(HexaColors.signalGlow),
    );
  }
}
