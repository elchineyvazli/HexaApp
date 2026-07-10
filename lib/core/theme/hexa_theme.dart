  import 'package:flutter/material.dart';

  class HexaTheme {
    HexaTheme._();

    static const Color primaryColor = Color(0xFFFF5E00);
    static const Color backgroundColor = Color(0xFF0D0E15);
    static const Color surfaceColor = Color(0xFF181926);
    static const Color textPrimary = Color(0xFFFFFFFF);
    static const Color textSecondary = Color(0xFF8E92B2);
    static const Color accentColor = Color(0xFF6C5CE7);

    static ThemeData get darkTheme {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundColor,
        primaryColor: primaryColor,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          secondary: accentColor,
          surface: surfaceColor,
          background: backgroundColor,
          onPrimary: textPrimary,
          onSecondary: textPrimary,
          onSurface: textPrimary,
          onBackground: textSecondary,
        ),
      );
    }
  }
