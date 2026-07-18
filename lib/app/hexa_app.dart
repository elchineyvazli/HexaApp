import 'dart:math' as math;

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
        : HexaMotion.normal;

    return MaterialApp.router(
      title: 'Hexa',
      debugShowCheckedModeBanner: false,
      theme: settings.lightTheme,
      darkTheme: settings.darkTheme,
      themeMode: settings.materialThemeMode,
      themeAnimationDuration: themeAnimationDuration,
      themeAnimationCurve: HexaMotion.emphasized,
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

    return SystemUiOverlayStyle(
      statusBarColor: HexaColors.transparent,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: theme.scaffoldBackgroundColor,
      systemNavigationBarIconBrightness: iconBrightness,
      systemNavigationBarDividerColor: HexaColors.transparent,
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
      title: 'Hexa',
      debugShowCheckedModeBanner: false,
      theme: HexaTheme.lightTheme,
      darkTheme: HexaTheme.darkTheme,
      home: _StartupFailureView(error: error, stackTrace: stackTrace),
    );
  }
}

class _StartupFailureView extends StatefulWidget {
  const _StartupFailureView({required this.error, this.stackTrace});

  final Object error;
  final StackTrace? stackTrace;

  @override
  State<_StartupFailureView> createState() {
    return _StartupFailureViewState();
  }
}

class _StartupFailureViewState extends State<_StartupFailureView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _energyController;

  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();

    _energyController = AnimationController(
      vsync: this,
      duration: HexaMotion.ambient,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final shouldReduce = HexaMotion.reduceMotionOf(context);

    if (shouldReduce == _reduceMotion && _energyController.isAnimating) {
      return;
    }

    _reduceMotion = shouldReduce;

    if (_reduceMotion) {
      _energyController
        ..stop()
        ..value = 0.18;
    } else if (!_energyController.isAnimating) {
      _energyController.repeat();
    }
  }

  @override
  void dispose() {
    _energyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: HexaGradients.pageFor(theme.brightness),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: HexaSpacing.pageInsets,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildEnergyMark(theme),
                    const SizedBox(height: HexaSpacing.xl),
                    Text(
                      'Başlangıç sinyali kurulamadı',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: HexaSpacing.sm),
                    Text(
                      'Hexa çekirdeği Firebase bağlantısını '
                      'tamamlayamadı. Uygulama yapılandırmasını '
                      'kontrol edip yeniden aç.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: HexaSpacing.xl),
                      _buildDebugDetails(theme),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnergyMark(ThemeData theme) {
    return Semantics(
      label: 'Hexa başlangıç hatası',
      child: AnimatedBuilder(
        animation: _energyController,
        builder: (context, child) {
          final progress = _energyController.value;

          final pulse = _reduceMotion
              ? 1.0
              : 0.985 + math.sin(progress * math.pi * 2) * 0.015;

          return Transform.scale(
            scale: pulse,
            child: SizedBox.square(
              dimension: 124,
              child: CustomPaint(
                painter: _StartupHexagonPainter(
                  progress: progress,
                  signalColor: theme.colorScheme.primary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDebugDetails(ThemeData theme) {
    final buffer = StringBuffer()..writeln(widget.error);

    if (widget.stackTrace != null) {
      buffer
        ..writeln()
        ..write(widget.stackTrace);
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 180),
      padding: const EdgeInsets.all(HexaSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: HexaRadius.borderMd,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          buffer.toString(),
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _StartupHexagonPainter extends CustomPainter {
  const _StartupHexagonPainter({
    required this.progress,
    required this.signalColor,
  });

  final double progress;
  final Color signalColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.31;

    final glowRect = Rect.fromCircle(center: center, radius: radius * 1.65);

    final glowPaint = Paint()
      ..shader = const RadialGradient(
        colors: <Color>[HexaColors.signalGlow, HexaColors.transparent],
      ).createShader(glowRect);

    canvas.drawCircle(center, radius * 1.65, glowPaint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * math.pi * 2);
    canvas.translate(-center.dx, -center.dy);

    final outerPaint = Paint()
      ..color = signalColor.withAlpha(92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      _hexagonPath(center: center, radius: radius * 1.35),
      outerPaint,
    );

    canvas.restore();

    final corePaint = Paint()
      ..color = signalColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(_hexagonPath(center: center, radius: radius), corePaint);

    final centerPaint = Paint()..color = HexaColors.hopePink;

    canvas.drawCircle(center, 4, centerPaint);
  }

  Path _hexagonPath({required Offset center, required double radius}) {
    final path = Path();

    for (var index = 0; index < 6; index++) {
      final angle = -math.pi / 2 + index * math.pi / 3;

      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );

      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    return path..close();
  }

  @override
  bool shouldRepaint(covariant _StartupHexagonPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.signalColor != signalColor;
  }
}
