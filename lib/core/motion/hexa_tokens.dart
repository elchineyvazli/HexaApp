import 'package:flutter/material.dart';

/// HEXA 2029 tasarım sisteminin ortak sabitleri.
///
/// Feature dosyalarında doğrudan renk, boşluk, radius veya gölge
/// oluşturmak yerine mümkün olduğunca bu token'lar kullanılmalıdır.
abstract final class HexaColors {
  // ---------------------------------------------------------------------------
  // HEXA 2029 — Temel marka renkleri
  // ---------------------------------------------------------------------------

  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleStrong = Color(0xFF7C3AED);
  static const Color purpleSoft = Color(0xFFA78BFA);

  static const Color cyan = Color(0xFF06B6D4);
  static const Color cyanSoft = Color(0xFF67E8F9);
  static const Color cyanMuted = Color(0xFF164E63);

  // ---------------------------------------------------------------------------
  // Eski ekranları kırmamak için korunan marka adları
  // ---------------------------------------------------------------------------

  static const Color hopePink = purpleSoft;
  static const Color blush = Color(0xFFC4B5FD);
  static const Color mauve = purple;
  static const Color signal = purple;
  static const Color plum = purpleStrong;
  static const Color horizon = Color(0xFF4F46E5);
  static const Color earth = Color(0xFF050507);
  static const Color mint = cyanSoft;

  // ---------------------------------------------------------------------------
  // Temel nötr renkler
  // ---------------------------------------------------------------------------

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // ---------------------------------------------------------------------------
  // Açık tema yüzeyleri
  // ---------------------------------------------------------------------------

  static const Color background = Color(0xFFF7F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F1F5);
  static const Color surfaceStrong = Color(0xFFE7E7EE);
  static const Color surfaceWarm = Color(0xFFF3F0FF);

  // ---------------------------------------------------------------------------
  // Koyu tema yüzeyleri
  // ---------------------------------------------------------------------------

  static const Color backgroundDark = Color(0xFF050507);
  static const Color surfaceDark = Color(0xFF111116);
  static const Color surfaceMutedDark = Color(0xFF191920);
  static const Color surfaceStrongDark = Color(0xFF23232B);

  static const Color surfaceElevatedDark = Color(0xFF2B2B34);
  static const Color surfaceOverlayDark = Color(0xF216161B);

  // ---------------------------------------------------------------------------
  // Metin ve içerik renkleri
  // ---------------------------------------------------------------------------

  static const Color ink = Color(0xFF16161B);
  static const Color inkMuted = Color(0xFF666672);
  static const Color inkSoft = Color(0xFF9696A3);

  static const Color inkOnDark = Color(0xFFF5F5F7);
  static const Color inkMutedOnDark = Color(0xFFA0A0AD);
  static const Color inkSoftOnDark = Color(0xFF6F6F7B);

  // ---------------------------------------------------------------------------
  // Etkileşim renkleri
  // ---------------------------------------------------------------------------

  static const Color signalSoft = Color(0xFFEDE5FF);
  static const Color signalStrong = purpleStrong;

  static const Color signalGlow = Color(0x558B5CF6);
  static const Color signalGlowStrong = Color(0x778B5CF6);

  static const Color cyanGlow = Color(0x4406B6D4);

  static const Color pressedOverlay = Color(0x1F8B5CF6);
  static const Color focusOverlay = Color(0x338B5CF6);

  static const Color neutralPressedOverlay = Color(0x14FFFFFF);
  static const Color neutralHoverOverlay = Color(0x0FFFFFFF);

  // ---------------------------------------------------------------------------
  // Destekleyici renkler
  // ---------------------------------------------------------------------------

  static const Color mintSoft = Color(0xFFDFF9FC);
  static const Color lavender = Color(0xFFC4B5FD);
  static const Color lavenderSoft = Color(0xFFF1ECFF);

  // ---------------------------------------------------------------------------
  // Border ve durum renkleri
  // ---------------------------------------------------------------------------

  static const Color border = Color(0xFFE3E3E9);
  static const Color borderStrong = Color(0xFFD2D2DA);

  static const Color borderOnDark = Color(0xFF292930);
  static const Color borderStrongOnDark = Color(0xFF3A3A44);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFFF6673);

  static const Color scrim = Color(0xB8050507);
  static const Color scrimSoft = Color(0x8F050507);

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

  static Color borderStrongFor(Brightness brightness) {
    return brightness == Brightness.dark ? borderStrongOnDark : borderStrong;
  }
}

abstract final class HexaGradients {
  /// Kontrollü marka gradienti.
  ///
  /// Büyük arka planlarda değil; avatar halkası, aktif durum veya küçük
  /// marka detaylarında kullanılmalıdır.
  static const LinearGradient hope = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[HexaColors.purpleSoft, HexaColors.purple],
  );

  /// HEXA'nın mor–cyan vurgu gradienti.
  static const LinearGradient signal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[HexaColors.purple, HexaColors.cyan],
  );

  /// Açık tema için nötr sayfa arka planı.
  static const LinearGradient page = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color(0xFFFAFAFC),
      HexaColors.background,
      Color(0xFFF4F2FA),
    ],
    stops: <double>[0, 0.60, 1],
  );

  /// Koyu tema sayfalarında renkli bir neon arka plan yerine kullanılan
  /// neredeyse düz ve kontrollü geçiş.
  static const LinearGradient pageDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color(0xFF09090D),
      HexaColors.backgroundDark,
      Color(0xFF050507),
    ],
    stops: <double>[0, 0.44, 1],
  );

  /// Eski kullanımlar için korunan koyu marka geçişi.
  static const LinearGradient horizon = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      HexaColors.purple,
      Color(0xFF4F46E5),
      HexaColors.backgroundDark,
    ],
    stops: <double>[0, 0.42, 1],
  );

  /// Yalnızca küçük vurgu ve animasyonlarda kullanılmalıdır.
  static const RadialGradient glow = RadialGradient(
    colors: <Color>[Color(0x668B5CF6), Color(0x2206B6D4), Color(0x0006B6D4)],
  );

  static const LinearGradient navIndicator = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[HexaColors.purple, HexaColors.cyan],
  );

  /// Açık arayüzlerde kullanılan hafif cam yüzey.
  static const LinearGradient glass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xF2FFFFFF), Color(0xD9FFFFFF)],
  );

  /// Koyu cam paneller için kontrollü yüzey.
  static const LinearGradient glassDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xF21A1A20), Color(0xE6111116)],
  );

  /// Video okunabilirliği için nötr siyah katman.
  static const LinearGradient feedScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color(0x52050507),
      Color(0x00050507),
      Color(0x00050507),
      Color(0x8F050507),
    ],
    stops: <double>[0, 0.18, 0.66, 1],
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

  static const EdgeInsets pageHorizontalInsets = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
  );
}

abstract final class HexaRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double pill = 999;

  static const BorderRadius borderXs = BorderRadius.all(Radius.circular(xs));

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

  /// Nötr kart ve küçük yüzey gölgesi.
  static const List<BoxShadow> soft = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 10)),
  ];

  /// Aktif marka bileşenleri için kontrollü mor gölge.
  static const List<BoxShadow> signal = <BoxShadow>[
    BoxShadow(
      color: Color(0x3D8B5CF6),
      blurRadius: 22,
      spreadRadius: -5,
      offset: Offset(0, 8),
    ),
  ];

  /// Sadece animasyon ve küçük marka vurgularında kullanılmalıdır.
  static const List<BoxShadow> glowSignal = <BoxShadow>[
    BoxShadow(color: Color(0x338B5CF6), blurRadius: 26, spreadRadius: 1),
    BoxShadow(color: Color(0x1F06B6D4), blurRadius: 34, spreadRadius: -2),
  ];

  /// Modal, action sheet ve yüzen yüzeyler.
  static const List<BoxShadow> floating = <BoxShadow>[
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 38,
      spreadRadius: -10,
      offset: Offset(0, 18),
    ),
  ];

  /// Koyu arayüzde alt panel ve modal gölgesi.
  static const List<BoxShadow> floatingDark = <BoxShadow>[
    BoxShadow(
      color: Color(0x99000000),
      blurRadius: 42,
      spreadRadius: -12,
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

    final seeded = base.apply(
      bodyColor: ink,
      displayColor: ink,
      decorationColor: ink,
    );

    return seeded.copyWith(
      displayLarge: seeded.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.35,
        height: 1,
      ),
      displayMedium: seeded.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        height: 1.02,
      ),
      displaySmall: seeded.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.72,
        height: 1.05,
      ),
      headlineLarge: seeded.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.65,
        height: 1.08,
      ),
      headlineMedium: seeded.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.52,
        height: 1.1,
      ),
      headlineSmall: seeded.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.42,
        height: 1.12,
      ),
      titleLarge: seeded.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.42,
        height: 1.18,
      ),
      titleMedium: seeded.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.28,
        height: 1.2,
      ),
      titleSmall: seeded.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.18,
        height: 1.22,
      ),
      bodyLarge: seeded.bodyLarge?.copyWith(
        fontWeight: FontWeight.w400,
        letterSpacing: -0.18,
        height: 1.45,
      ),
      bodyMedium: seeded.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        letterSpacing: -0.12,
        height: 1.42,
      ),
      bodySmall: seeded.bodySmall?.copyWith(
        color: muted,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.05,
        height: 1.38,
      ),
      labelLarge: seeded.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.10,
        height: 1.2,
      ),
      labelMedium: seeded.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.05,
        height: 1.2,
      ),
      labelSmall: seeded.labelSmall?.copyWith(
        color: muted,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.2,
      ),
    );
  }
}
