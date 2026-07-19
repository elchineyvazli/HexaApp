import 'package:flutter/material.dart';

import '../motion/hexa_motion.dart';
import '../motion/hexa_tokens.dart';

export '../motion/hexa_motion.dart';
export '../motion/hexa_tokens.dart';

/// HEXA'nın Material katmanı.
///
/// Bu dosya Flutter bileşenlerinin ortak görünümünü birleştirir.
/// Ekrana özel ayrıntılar ilgili feature dosyalarında kalır.
abstract final class HexaTheme {
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _purpleStrong = Color(0xFF7C3AED);
  static const Color _cyan = Color(0xFF06B6D4);

  static const Color _darkBackground = Color(0xFF050507);
  static const Color _darkSurface = Color(0xFF111116);
  static const Color _darkSurfaceStrong = Color(0xFF191920);
  static const Color _darkSurfaceMuted = Color(0xFF23232B);

  static const Color _darkInk = Color(0xFFF5F5F7);
  static const Color _darkMutedInk = Color(0xFFA0A0AD);
  static const Color _darkSoftInk = Color(0xFF6F6F7B);

  static const Color _darkBorder = Color(0xFF292930);
  static const Color _darkBorderStrong = Color(0xFF3A3A44);

  static const Color _lightBackground = Color(0xFFF7F7FA);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceStrong = Color(0xFFEFEFF4);
  static const Color _lightSurfaceMuted = Color(0xFFE6E6ED);

  static const Color _lightInk = Color(0xFF16161B);
  static const Color _lightMutedInk = Color(0xFF666672);
  static const Color _lightSoftInk = Color(0xFF9696A3);

  static const Color _lightBorder = Color(0xFFE3E3E9);
  static const Color _lightBorderStrong = Color(0xFFD2D2DA);

  static const Color _error = Color(0xFFFF6673);

  // Eski ekranları kırmamak için korunan adlar.
  static const Color primaryColor = _purple;
  static const Color backgroundColor = _darkBackground;
  static const Color surfaceColor = _darkSurface;
  static const Color textPrimary = _darkInk;
  static const Color textSecondary = _darkMutedInk;
  static const Color accentColor = _cyan;

  static ThemeData get lightTheme {
    return _build(Brightness.light);
  }

  static ThemeData get darkTheme {
    return _build(Brightness.dark);
  }

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final background = isDark ? _darkBackground : _lightBackground;

    final surface = isDark ? _darkSurface : _lightSurface;

    final surfaceStrong = isDark ? _darkSurfaceStrong : _lightSurfaceStrong;

    final surfaceMuted = isDark ? _darkSurfaceMuted : _lightSurfaceMuted;

    final ink = isDark ? _darkInk : _lightInk;

    final mutedInk = isDark ? _darkMutedInk : _lightMutedInk;

    final softInk = isDark ? _darkSoftInk : _lightSoftInk;

    final border = isDark ? _darkBorder : _lightBorder;

    final borderStrong = isDark ? _darkBorderStrong : _lightBorderStrong;

    final pressedOverlay = isDark
        ? const Color(0x14FFFFFF)
        : const Color(0x0F000000);

    final focusOverlay = isDark
        ? const Color(0x268B5CF6)
        : const Color(0x1F8B5CF6);

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _purple,
          brightness: brightness,
        ).copyWith(
          primary: _purple,
          onPrimary: Colors.white,
          primaryContainer: isDark
              ? const Color(0xFF2A1E43)
              : const Color(0xFFEDE5FF),
          onPrimaryContainer: isDark
              ? const Color(0xFFEDE5FF)
              : const Color(0xFF27153E),

          secondary: _cyan,
          onSecondary: const Color(0xFF031114),
          secondaryContainer: isDark
              ? const Color(0xFF103038)
              : const Color(0xFFD9F8FC),
          onSecondaryContainer: isDark
              ? const Color(0xFFD9F8FC)
              : const Color(0xFF062D35),

          tertiary: isDark ? const Color(0xFFA78BFA) : _purpleStrong,
          onTertiary: Colors.white,
          tertiaryContainer: isDark
              ? const Color(0xFF30274A)
              : const Color(0xFFE9E2FF),
          onTertiaryContainer: ink,

          error: _error,
          onError: Colors.white,
          errorContainer: isDark
              ? const Color(0xFF3A1D22)
              : const Color(0xFFFFE6E8),
          onErrorContainer: isDark
              ? const Color(0xFFFFDADD)
              : const Color(0xFF4A1118),

          surface: surface,
          onSurface: ink,
          onSurfaceVariant: mutedInk,

          surfaceContainerLowest: background,
          surfaceContainerLow: surface,
          surfaceContainer: surfaceStrong,
          surfaceContainerHigh: surfaceMuted,
          surfaceContainerHighest: isDark
              ? const Color(0xFF2B2B34)
              : const Color(0xFFDDDDE5),

          outline: borderStrong,
          outlineVariant: border,

          shadow: Colors.black,
          scrim: const Color(0xB8050507),

          inverseSurface: isDark
              ? const Color(0xFFF2F2F5)
              : const Color(0xFF202027),
          onInverseSurface: isDark
              ? const Color(0xFF18181D)
              : const Color(0xFFF4F4F7),
          inversePrimary: isDark ? _purpleStrong : const Color(0xFFA78BFA),
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: border,
      disabledColor: softInk,
      focusColor: focusOverlay,
      hoverColor: pressedOverlay,
      highlightColor: pressedOverlay,
      splashColor: pressedOverlay,
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
    ).apply(bodyColor: ink, displayColor: ink, decorationColor: ink);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      appBarTheme: _appBarTheme(
        background: background,
        ink: ink,
        mutedInk: mutedInk,
        textTheme: textTheme,
      ),

      navigationBarTheme: _navigationBarTheme(
        isDark: isDark,
        mutedInk: mutedInk,
        surface: surface,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: _purple,
        unselectedItemColor: mutedInk,
        selectedIconTheme: const IconThemeData(color: _purple, size: 25),
        unselectedIconTheme: IconThemeData(color: mutedInk, size: 24),
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      inputDecorationTheme: _inputDecorationTheme(
        surface: surfaceStrong,
        mutedInk: mutedInk,
        softInk: softInk,
        border: border,
      ),

      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x66000000),
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: ink,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.35,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: mutedInk,
          height: 1.45,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),

      filledButtonTheme: _filledButtonTheme(
        textTheme: textTheme,
        colorScheme: colorScheme,
      ),

      outlinedButtonTheme: _outlinedButtonTheme(
        textTheme: textTheme,
        ink: ink,
        border: borderStrong,
        pressedOverlay: pressedOverlay,
      ),

      textButtonTheme: _textButtonTheme(
        textTheme: textTheme,
        colorScheme: colorScheme,
      ),

      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return softInk;
            }

            return ink;
          }),
          overlayColor: WidgetStatePropertyAll<Color?>(pressedOverlay),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(CircleBorder()),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      iconTheme: IconThemeData(color: mutedInk, size: 24),

      primaryIconTheme: IconThemeData(color: ink, size: 24),

      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _purple,
        linearTrackColor: surfaceStrong,
        circularTrackColor: surfaceStrong,
        refreshBackgroundColor: surface,
      ),

      switchTheme: _switchTheme(
        colorScheme: colorScheme,
        surfaceStrong: surfaceStrong,
        softInk: softInk,
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return _purple;
          }

          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll<Color>(Colors.white),
        side: BorderSide(color: borderStrong, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return _purple;
          }

          return mutedInk;
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? const Color(0xF216161B)
            : const Color(0xFF202027),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: const Color(0xFFA78BFA),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0x14FFFFFF)),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        modalBarrierColor: const Color(0xB8050507),
        shadowColor: const Color(0x99000000),
        elevation: 0,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: surfaceStrong,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x66000000),
        elevation: 0,
        textStyle: textTheme.bodyMedium?.copyWith(color: ink),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xF21A1A20) : const Color(0xF2202027),
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        waitDuration: const Duration(milliseconds: 500),
        showDuration: const Duration(milliseconds: 1800),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: mutedInk,
        textColor: ink,
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          color: ink,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(color: mutedInk),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: _purple,
        selectionColor: Color(0x4D8B5CF6),
        selectionHandleColor: _purple,
      ),
    );
  }

  static AppBarTheme _appBarTheme({
    required Color background,
    required Color ink,
    required Color mutedInk,
    required TextTheme textTheme,
  }) {
    return AppBarTheme(
      backgroundColor: background,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: ink, size: 23),
      actionsIconTheme: IconThemeData(color: mutedInk, size: 23),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: ink,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.45,
      ),
    );
  }

  static NavigationBarThemeData _navigationBarTheme({
    required bool isDark,
    required Color mutedInk,
    required Color surface,
  }) {
    return NavigationBarThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      height: 66,
      indicatorColor: isDark
          ? const Color(0x268B5CF6)
          : const Color(0x1F8B5CF6),
      indicatorShape: const StadiumBorder(),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
        final selected = states.contains(WidgetState.selected);

        return IconThemeData(
          color: selected ? _purple : mutedInk,
          size: selected ? 25 : 24,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
        final selected = states.contains(WidgetState.selected);

        return TextStyle(
          color: selected ? _purple : mutedInk,
          fontSize: 10,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          letterSpacing: -0.05,
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
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      hintStyle: TextStyle(
        color: softInk,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelStyle: TextStyle(color: mutedInk, fontWeight: FontWeight.w500),
      floatingLabelStyle: const TextStyle(
        color: _purple,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: mutedInk,
      suffixIconColor: mutedInk,
      border: _inputBorder(border),
      enabledBorder: _inputBorder(border),
      focusedBorder: _inputBorder(_purple, width: 1.35),
      errorBorder: _inputBorder(_error),
      focusedErrorBorder: _inputBorder(_error, width: 1.35),
      disabledBorder: _inputBorder(border),
      errorStyle: const TextStyle(color: _error, fontWeight: FontWeight.w500),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static FilledButtonThemeData _filledButtonTheme({
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    return FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 48)),
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        ),
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.surfaceContainerHighest;
          }

          return _purple;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurfaceVariant;
          }

          return Colors.white;
        }),
        overlayColor: const WidgetStatePropertyAll<Color?>(Color(0x1FFFFFFF)),
        elevation: const WidgetStatePropertyAll<double>(0),
        textStyle: WidgetStatePropertyAll<TextStyle?>(
          textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.10,
          ),
        ),
        shape: const WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder()),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme({
    required TextTheme textTheme,
    required Color ink,
    required Color border,
    required Color pressedOverlay,
  }) {
    return OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 48)),
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        ),
        foregroundColor: WidgetStatePropertyAll<Color>(ink),
        backgroundColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
        overlayColor: WidgetStatePropertyAll<Color?>(pressedOverlay),
        elevation: const WidgetStatePropertyAll<double>(0),
        side: WidgetStatePropertyAll<BorderSide>(BorderSide(color: border)),
        textStyle: WidgetStatePropertyAll<TextStyle?>(
          textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.10,
          ),
        ),
        shape: const WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder()),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme({
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    return TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll<Color>(_purple),
        overlayColor: const WidgetStatePropertyAll<Color?>(Color(0x1F8B5CF6)),
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        textStyle: WidgetStatePropertyAll<TextStyle?>(
          textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        shape: WidgetStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
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
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }

        return softInk;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return _purple;
        }

        return surfaceStrong;
      }),
      trackOutlineColor: const WidgetStatePropertyAll<Color?>(
        Colors.transparent,
      ),
      overlayColor: const WidgetStatePropertyAll<Color?>(Color(0x268B5CF6)),
    );
  }
}
