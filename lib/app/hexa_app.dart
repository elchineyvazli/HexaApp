import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/router/hexa_router.dart';
import '../core/theme/hexa_theme.dart';
import '../features/settings/app_settings_controller.dart';

class HexaApp extends ConsumerWidget {
  const HexaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(appSettingsProvider);

    final themeAnimationDuration = settings.reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return MaterialApp.router(
      title: 'HEXA',
      debugShowCheckedModeBanner: false,
      theme: settings.lightTheme,
      darkTheme: settings.darkTheme,
      themeMode: settings.materialThemeMode,
      themeAnimationDuration: themeAnimationDuration,
      themeAnimationCurve: Curves.easeOutCubic,
      scrollBehavior: const _HexaScrollBehavior(),
      routerConfig: router,
      builder: (context, child) {
        final theme = Theme.of(context);
        final mediaQuery = MediaQuery.of(context);

        final reduceMotion =
            settings.reduceMotion ||
            mediaQuery.disableAnimations ||
            mediaQuery.accessibleNavigation;

        return MediaQuery(
          data: mediaQuery.copyWith(disableAnimations: reduceMotion),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: _systemUiStyle(theme),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  SystemUiOverlayStyle _systemUiStyle(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    final iconBrightness = isDark ? Brightness.light : Brightness.dark;

    final navigationBarColor = isDark
        ? HexaColors.backgroundDark
        : theme.scaffoldBackgroundColor;

    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: navigationBarColor,
      systemNavigationBarIconBrightness: iconBrightness,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    );
  }
}

class HexaStartupFailureApp extends StatelessWidget {
  const HexaStartupFailureApp({
    required this.error,
    this.stackTrace,
    super.key,
  });

  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HEXA',
      debugShowCheckedModeBanner: false,
      theme: HexaTheme.darkTheme,
      darkTheme: HexaTheme.darkTheme,
      themeMode: ThemeMode.dark,
      scrollBehavior: const _HexaScrollBehavior(),
      home: _StartupFailureView(error: error, stackTrace: stackTrace),
    );
  }
}

class _StartupFailureView extends StatelessWidget {
  const _StartupFailureView({required this.error, this.stackTrace});

  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: HexaColors.backgroundDark,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: HexaColors.backgroundDark,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFF0A0A0F),
                HexaColors.backgroundDark,
                HexaColors.backgroundDark,
              ],
              stops: <double>[0, 0.38, 1],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 36,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const _StartupFailureMark(),
                      const SizedBox(height: 28),
                      const Text(
                        'HEXA başlatılamadı',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: HexaColors.inkOnDark,
                          fontSize: 24,
                          height: 1.12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.65,
                        ),
                      ),
                      const SizedBox(height: 11),
                      const Text(
                        'Uygulama gerekli bağlantıları kuramadı. İnternet bağlantını ve uygulama yapılandırmasını kontrol edip yeniden aç.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0x80FFFFFF),
                          fontSize: 13.5,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.10,
                        ),
                      ),
                      if (kDebugMode) ...<Widget>[
                        const SizedBox(height: 30),
                        _StartupDebugDetails(
                          error: error,
                          stackTrace: stackTrace,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupFailureMark extends StatelessWidget {
  const _StartupFailureMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'HEXA başlangıç hatası',
      child: Container(
        width: 78,
        height: 78,
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          gradient: HexaGradients.signal,
          borderRadius: BorderRadius.circular(27),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x248B5CF6),
              blurRadius: 30,
              spreadRadius: -8,
            ),
          ],
        ),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: HexaColors.surfaceDark,
            borderRadius: BorderRadius.circular(25.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Icon(
                Icons.hexagon_outlined,
                color: HexaColors.purpleSoft,
                size: 43,
              ),
              Icon(
                Icons.priority_high_rounded,
                color: Colors.white.withOpacity(0.92),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupDebugDetails extends StatelessWidget {
  const _StartupDebugDetails({required this.error, this.stackTrace});

  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    final buffer = StringBuffer()..writeln(error);

    if (stackTrace != null) {
      buffer
        ..writeln()
        ..write(stackTrace);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: HexaColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.code_rounded,
                color: Colors.white.withOpacity(0.52),
                size: 17,
              ),
              const SizedBox(width: 8),
              const Text(
                'Teknik ayrıntılar',
                style: TextStyle(
                  color: Color(0xBFFFFFFF),
                  fontSize: 12,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.06,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: SingleChildScrollView(
              child: SelectableText(
                buffer.toString(),
                style: const TextStyle(
                  color: Color(0x70FFFFFF),
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HexaScrollBehavior extends MaterialScrollBehavior {
  const _HexaScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
