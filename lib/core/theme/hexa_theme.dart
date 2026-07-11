import 'package:flutter/material.dart';

/// Hexa'nın umut, sıcaklık ve keşif duygusunu taşıyan ana renk sistemi.
///
/// Palet, kullanıcının paylaştığı pembe gökyüzü ve koyu ufuk görselinden
/// türetilmiştir. Koyu renkler okunabilirlik; açık renkler ise ferahlık için
/// kullanılır.
abstract final class HexaColors {
  // Hope palette — ana marka renkleri.
  static const Color hopePink = Color(0xFFFB9BBD);
  static const Color blush = Color(0xFFF5A8CC);
  static const Color mauve = Color(0xFFC575B1);
  static const Color signal = Color(0xFFB15090);
  static const Color plum = Color(0xFF833C69);
  static const Color horizon = Color(0xFF601F24);
  static const Color earth = Color(0xFF2F1713);

  // Açık uygulama yüzeyleri.
  static const Color background = Color(0xFFFFF7FA);
  static const Color surface = Color(0xFFFFFCFD);
  static const Color surfaceMuted = Color(0xFFFCEAF2);
  static const Color surfaceStrong = Color(0xFFF5D9E7);
  static const Color surfaceWarm = Color(0xFFFFEEF5);

  // Metin ve ikonlar.
  static const Color ink = earth;
  static const Color inkMuted = Color(0xFF725766);
  static const Color inkSoft = Color(0xFFA58A98);
  static const Color inkOnDark = Color(0xFFFFF8FB);

  // Signal ve etkileşim durumları.
  static const Color signalSoft = Color(0xFFF9DDEB);
  static const Color signalStrong = plum;
  static const Color signalGlow = Color(0x55FB9BBD);

  // Geriye uyumluluk için korunan yardımcı renkler.
  static const Color mint = Color(0xFFCFE8DF);
  static const Color mintSoft = Color(0xFFEDF8F4);
  static const Color lavender = Color(0xFFE0CFEA);
  static const Color lavenderSoft = Color(0xFFF5ECF8);

  static const Color border = Color(0xFFEBD7E1);
  static const Color borderStrong = Color(0xFFD9BACB);
  static const Color success = Color(0xFF287A64);
  static const Color warning = Color(0xFFA35E18);
  static const Color error = Color(0xFFA42E42);
}

abstract final class HexaGradients {
  static const LinearGradient hope = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [HexaColors.hopePink, HexaColors.blush, HexaColors.mauve],
    stops: [0, 0.52, 1],
  );

  static const LinearGradient signal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [HexaColors.hopePink, HexaColors.signal, HexaColors.plum],
  );

  static const LinearGradient page = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFBFD), HexaColors.background, Color(0xFFFFF1F7)],
  );

  static const LinearGradient horizon = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      HexaColors.blush,
      HexaColors.mauve,
      HexaColors.horizon,
      HexaColors.earth,
    ],
    stops: [0, 0.48, 0.78, 1],
  );

  static const RadialGradient glow = RadialGradient(
    colors: [Color(0x88FB9BBD), Color(0x33C575B1), Color(0x00C575B1)],
  );
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
  static const double xl = 30;
  static const double pill = 999;
}

abstract final class HexaMotion {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 520);

  static const Curve enter = Cubic(0.20, 0.82, 0.28, 1.00);
  static const Curve exit = Cubic(0.40, 0.00, 0.80, 0.20);
  static const Curve emphasized = Cubic(0.16, 1.00, 0.30, 1.00);
}

abstract final class HexaShadows {
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x122F1713), blurRadius: 24, offset: Offset(0, 10)),
  ];

  static const List<BoxShadow> signal = [
    BoxShadow(
      color: Color(0x3DB15090),
      blurRadius: 22,
      spreadRadius: -3,
      offset: Offset(0, 9),
    ),
  ];
}

class HexaTheme {
  HexaTheme._();

  // Eski ekranlardaki kullanımları kırmamak için geriye uyumlu adlar.
  static const Color primaryColor = HexaColors.signal;
  static const Color backgroundColor = HexaColors.background;
  static const Color surfaceColor = HexaColors.surface;
  static const Color textPrimary = HexaColors.ink;
  static const Color textSecondary = HexaColors.inkMuted;
  static const Color accentColor = HexaColors.mauve;

  static ThemeData get lightTheme {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: HexaColors.signal,
          brightness: Brightness.light,
        ).copyWith(
          primary: HexaColors.signalStrong,
          onPrimary: Colors.white,
          primaryContainer: HexaColors.signalSoft,
          onPrimaryContainer: HexaColors.earth,
          secondary: HexaColors.mauve,
          onSecondary: Colors.white,
          secondaryContainer: HexaColors.lavenderSoft,
          onSecondaryContainer: HexaColors.earth,
          tertiary: HexaColors.hopePink,
          onTertiary: HexaColors.earth,
          tertiaryContainer: HexaColors.surfaceWarm,
          onTertiaryContainer: HexaColors.earth,
          surface: HexaColors.surface,
          onSurface: HexaColors.ink,
          error: HexaColors.error,
          onError: Colors.white,
          outline: HexaColors.borderStrong,
          outlineVariant: HexaColors.border,
          shadow: HexaColors.earth,
          scrim: HexaColors.earth,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: HexaColors.background,
      canvasColor: HexaColors.background,
      dividerColor: HexaColors.border,
      disabledColor: HexaColors.inkSoft,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _HexaPageTransitionsBuilder(),
          TargetPlatform.iOS: _HexaPageTransitionsBuilder(),
          TargetPlatform.macOS: _HexaPageTransitionsBuilder(),
          TargetPlatform.windows: _HexaPageTransitionsBuilder(),
          TargetPlatform.linux: _HexaPageTransitionsBuilder(),
        },
      ),
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
        fontWeight: FontWeight.w800,
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
        fontWeight: FontWeight.w800,
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
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: HexaColors.signalSoft,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HexaRadius.md),
        ),
        iconTheme: MaterialStateProperty.resolveWith<IconThemeData>((states) {
          final isSelected = states.contains(MaterialState.selected);
          return IconThemeData(
            color: isSelected ? HexaColors.plum : HexaColors.inkMuted,
            size: isSelected ? 27 : 25,
          );
        }),
        labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>((states) {
          final isSelected = states.contains(MaterialState.selected);
          return TextStyle(
            color: isSelected ? HexaColors.plum : HexaColors.inkMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HexaColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: HexaColors.inkSoft),
        labelStyle: const TextStyle(color: HexaColors.inkMuted),
        floatingLabelStyle: const TextStyle(
          color: HexaColors.signalStrong,
          fontWeight: FontWeight.w700,
        ),
        border: inputBorder(HexaColors.border),
        enabledBorder: inputBorder(HexaColors.border),
        focusedBorder: inputBorder(HexaColors.signal, width: 1.5),
        errorBorder: inputBorder(HexaColors.error),
        focusedErrorBorder: inputBorder(HexaColors.error, width: 1.5),
      ),
      cardTheme: CardThemeData(
        color: HexaColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HexaRadius.lg),
          side: const BorderSide(color: HexaColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: HexaColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HexaRadius.lg),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: HexaColors.surfaceMuted,
        selectedColor: HexaColors.signalSoft,
        disabledColor: HexaColors.surfaceStrong,
        side: const BorderSide(color: HexaColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HexaRadius.pill),
        ),
        labelStyle: const TextStyle(
          color: HexaColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: HexaColors.signalStrong,
          foregroundColor: Colors.white,
          disabledBackgroundColor: HexaColors.surfaceStrong,
          disabledForegroundColor: HexaColors.inkSoft,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HexaRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: HexaColors.signalStrong,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HexaRadius.sm),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: HexaColors.signalStrong,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(HexaRadius.md)),
        ),
      ),
      iconTheme: const IconThemeData(color: HexaColors.inkMuted),
      dividerTheme: const DividerThemeData(
        color: HexaColors.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: HexaColors.signalStrong,
        linearTrackColor: HexaColors.signalSoft,
        circularTrackColor: HexaColors.signalSoft,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          return states.contains(MaterialState.selected)
              ? Colors.white
              : HexaColors.inkSoft;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          return states.contains(MaterialState.selected)
              ? HexaColors.signal
              : HexaColors.surfaceStrong;
        }),
        trackOutlineColor: const MaterialStatePropertyAll(Colors.transparent),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: HexaColors.signalStrong,
        inactiveTrackColor: HexaColors.signalSoft,
        thumbColor: HexaColors.signal,
        overlayColor: HexaColors.signalGlow,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: HexaColors.earth,
        contentTextStyle: const TextStyle(color: HexaColors.inkOnDark),
        actionTextColor: HexaColors.hopePink,
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
        modalBarrierColor: Color(0x662F1713),
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: HexaColors.borderStrong,
      ),
    );
  }

  /// Geçiş sürecinde eski `darkTheme` çağrılarını kırmaz.
  static ThemeData get darkTheme => lightTheme;
}

class _HexaPageTransitionsBuilder extends PageTransitionsBuilder {
  const _HexaPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: HexaMotion.enter,
      reverseCurve: HexaMotion.exit,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(curvedAnimation),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.018),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }
}
