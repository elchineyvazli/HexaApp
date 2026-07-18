import 'package:flutter/material.dart';

/// Hexa'nın bütün ekranlarında kullanılan sabit tasarım değerleri.
///
/// Ekran dosyalarında doğrudan renk, boşluk, radius veya gölge üretmek yerine
/// bu sınıflardaki token'lar kullanılmalıdır.
abstract final class HexaColors {
  // Brand.
  static const Color hopePink = Color(0xFFFB9BBD);
  static const Color blush = Color(0xFFF5A8CC);
  static const Color mauve = Color(0xFFC575B1);
  static const Color signal = Color(0xFFB15090);
  static const Color plum = Color(0xFF833C69);
  static const Color horizon = Color(0xFF601F24);
  static const Color earth = Color(0xFF2F1713);
  static const Color mint = Color(0xFFCFE8DF);

  // Neutrals.
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);

  // Light surfaces.
  static const Color background = Color(0xFFFFF7FA);
  static const Color surface = Color(0xFFFFFCFD);
  static const Color surfaceMuted = Color(0xFFFCEAF2);
  static const Color surfaceStrong = Color(0xFFF5D9E7);
  static const Color surfaceWarm = Color(0xFFFFEEF5);

  // Dark surfaces.
  static const Color backgroundDark = Color(0xFF140C11);
  static const Color surfaceDark = Color(0xFF211219);
  static const Color surfaceMutedDark = Color(0xFF2C1822);
  static const Color surfaceStrongDark = Color(0xFF3A2030);

  // Content.
  static const Color ink = earth;
  static const Color inkMuted = Color(0xFF725766);
  static const Color inkSoft = Color(0xFFA58A98);
  static const Color inkOnDark = Color(0xFFFFF8FB);
  static const Color inkMutedOnDark = Color(0xFFD9C2CE);
  static const Color inkSoftOnDark = Color(0xFFAA919E);

  // Interaction.
  static const Color signalSoft = Color(0xFFF9DDEB);
  static const Color signalStrong = plum;
  static const Color signalGlow = Color(0x55FB9BBD);
  static const Color signalGlowStrong = Color(0x77B15090);
  static const Color pressedOverlay = Color(0x14B15090);
  static const Color focusOverlay = Color(0x22FB9BBD);

  // Supporting colors.
  static const Color mintSoft = Color(0xFFEDF8F4);
  static const Color lavender = Color(0xFFE0CFEA);
  static const Color lavenderSoft = Color(0xFFF5ECF8);

  // Borders and states.
  static const Color border = Color(0xFFEBD7E1);
  static const Color borderStrong = Color(0xFFD9BACB);
  static const Color borderOnDark = Color(0xFF4B2B3A);
  static const Color success = Color(0xFF287A64);
  static const Color warning = Color(0xFFA35E18);
  static const Color error = Color(0xFFA42E42);
  static const Color scrim = Color(0x992F1713);

  static Color backgroundFor(Brightness brightness) {
    return brightness == Brightness.dark ? backgroundDark : background;
  }

  static Color surfaceFor(Brightness brightness) {
    return brightness == Brightness.dark ? surfaceDark : surface;
  }

  static Color surfaceMutedFor(Brightness brightness) {
    return brightness == Brightness.dark ? surfaceMutedDark : surfaceMuted;
  }

  static Color surfaceStrongFor(Brightness brightness) {
    return brightness == Brightness.dark ? surfaceStrongDark : surfaceStrong;
  }

  static Color inkFor(Brightness brightness) {
    return brightness == Brightness.dark ? inkOnDark : ink;
  }

  static Color inkMutedFor(Brightness brightness) {
    return brightness == Brightness.dark ? inkMutedOnDark : inkMuted;
  }

  static Color inkSoftFor(Brightness brightness) {
    return brightness == Brightness.dark ? inkSoftOnDark : inkSoft;
  }

  static Color borderFor(Brightness brightness) {
    return brightness == Brightness.dark ? borderOnDark : border;
  }
}

abstract final class HexaGradients {
  static const LinearGradient hope = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[HexaColors.hopePink, HexaColors.blush, HexaColors.mauve],
    stops: <double>[0, 0.52, 1],
  );

  static const LinearGradient signal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[HexaColors.hopePink, HexaColors.signal, HexaColors.plum],
  );

  /// Bütün açık tema sayfalarının temel arka planı.
  static const LinearGradient page = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color(0xFFFFFBFD),
      HexaColors.background,
      Color(0xFFFFF1F7),
    ],
    stops: <double>[0, 0.54, 1],
  );

  static const LinearGradient pageDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color(0xFF1E1018),
      HexaColors.backgroundDark,
      Color(0xFF0E090C),
    ],
    stops: <double>[0, 0.58, 1],
  );

  static const LinearGradient horizon = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      HexaColors.blush,
      HexaColors.mauve,
      HexaColors.horizon,
      HexaColors.earth,
    ],
    stops: <double>[0, 0.48, 0.78, 1],
  );

  static const RadialGradient glow = RadialGradient(
    colors: <Color>[Color(0x88FB9BBD), Color(0x33C575B1), Color(0x00C575B1)],
  );

  static const LinearGradient navIndicator = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[HexaColors.hopePink, HexaColors.signal, HexaColors.plum],
    stops: <double>[0, 0.5, 1],
  );

  static const LinearGradient glass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xD9FFFCFD), Color(0xBFFCEAF2)],
  );

  static const LinearGradient feedScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0x00000000), Color(0x0D000000), Color(0x8A000000)],
    stops: <double>[0, 0.58, 1],
  );

  static LinearGradient pageFor(Brightness brightness) {
    return brightness == Brightness.dark ? pageDark : page;
  }
}

abstract final class HexaSpacing {
  static const double none = 0;
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double huge = 64;

  static const double pageHorizontal = 20;
  static const double pageVertical = 16;

  static const EdgeInsets pageInsets = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
    vertical: pageVertical,
  );
}

abstract final class HexaRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double pill = 999;

  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));

  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));

  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));

  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));

  static const BorderRadius borderPill = BorderRadius.all(
    Radius.circular(pill),
  );
}

abstract final class HexaShadows {
  static const List<BoxShadow> none = <BoxShadow>[];

  static const List<BoxShadow> soft = <BoxShadow>[
    BoxShadow(color: Color(0x122F1713), blurRadius: 24, offset: Offset(0, 10)),
  ];

  static const List<BoxShadow> signal = <BoxShadow>[
    BoxShadow(
      color: Color(0x3DB15090),
      blurRadius: 22,
      spreadRadius: -3,
      offset: Offset(0, 9),
    ),
  ];

  static const List<BoxShadow> glowSignal = <BoxShadow>[
    BoxShadow(color: Color(0x33FB9BBD), blurRadius: 28, spreadRadius: 2),
  ];

  static const List<BoxShadow> floating = <BoxShadow>[
    BoxShadow(
      color: Color(0x1F2F1713),
      blurRadius: 38,
      spreadRadius: -10,
      offset: Offset(0, 18),
    ),
  ];
}

abstract final class HexaTypography {
  static TextTheme build({
    required TextTheme base,
    required Brightness brightness,
  }) {
    final ink = HexaColors.inkFor(brightness);
    final muted = HexaColors.inkMutedFor(brightness);

    final seeded = base.apply(bodyColor: ink, displayColor: ink);

    return seeded.copyWith(
      displayLarge: seeded.displayLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -1,
        height: 0.98,
      ),
      displayMedium: seeded.displayMedium?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.6,
        height: 1,
      ),
      displaySmall: seeded.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.25,
        height: 1.04,
      ),
      headlineLarge: seeded.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.05,
        height: 1.08,
      ),
      headlineMedium: seeded.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.1,
        height: 1.1,
      ),
      headlineSmall: seeded.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.14,
        height: 1.12,
      ),
      titleLarge: seeded.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
      titleMedium: seeded.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.24,
      ),
      titleSmall: seeded.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
      bodyLarge: seeded.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.05,
        height: 1.42,
      ),
      bodyMedium: seeded.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.08,
        height: 1.4,
      ),
      bodySmall: seeded.bodySmall?.copyWith(
        color: muted,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.12,
        height: 1.36,
      ),
      labelLarge: seeded.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.55,
      ),
      labelMedium: seeded.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.65,
      ),
      labelSmall: seeded.labelSmall?.copyWith(
        color: muted,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.75,
      ),
    );
  }
}
