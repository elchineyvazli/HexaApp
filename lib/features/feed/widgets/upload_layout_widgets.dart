import 'package:flutter/material.dart';

import '../../../core/theme/hexa_theme.dart';

class UploadHeader extends StatelessWidget {
  const UploadHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Text(
            'Yeni video',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: HexaColors.inkOnDark,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.40,
            ),
          ),
          Positioned(
            left: 8,
            child: Semantics(
              button: true,
              label: 'Geri dön',
              child: IconButton(
                tooltip: 'Geri dön',
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();

                  Navigator.of(context).maybePop();
                },
                style: IconButton.styleFrom(
                  foregroundColor: Colors.white.withOpacity(0.88),
                  backgroundColor: Colors.white.withOpacity(0.055),
                  minimumSize: const Size(42, 42),
                  maximumSize: const Size(42, 42),
                  side: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                icon: Icon(Icons.arrow_back_rounded, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UploadSection extends StatelessWidget {
  const UploadSection({
    required this.title,
    required this.description,
    required this.icon,
    required this.child,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final normalizedDescription = description.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: HexaColors.purple, size: 18),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: HexaColors.inkOnDark,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.24,
                ),
              ),
            ),
          ],
        ),
        if (normalizedDescription.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 27),
            child: Text(
              normalizedDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HexaColors.inkMutedOnDark,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.06,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

class BusyUploadView extends StatelessWidget {
  const BusyUploadView({
    required this.message,
    required this.icon,
    this.progress,
    super.key,
  });

  final String message;
  final IconData icon;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    final normalizedProgress = progress?.clamp(0.0, 1.0).toDouble();

    final indicatorProgress =
        normalizedProgress ?? (reduceMotion ? 0.28 : null);

    final percentage = normalizedProgress == null
        ? null
        : (normalizedProgress * 100).round();

    return Scaffold(
      backgroundColor: HexaColors.backgroundDark,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF09090D),
              HexaColors.backgroundDark,
              HexaColors.backgroundDark,
            ],
            stops: <double>[0, 0.32, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox.square(
                      dimension: 78,
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          SizedBox.square(
                            dimension: 78,
                            child: CircularProgressIndicator(
                              value: indicatorProgress,
                              strokeWidth: 2.6,
                              color: HexaColors.purple,
                              backgroundColor: Colors.white.withOpacity(0.09),
                            ),
                          ),
                          Container(
                            width: 58,
                            height: 58,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: HexaColors.surfaceDark,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.07),
                              ),
                            ),
                            child: Icon(
                              icon,
                              size: 25,
                              color: Colors.white.withOpacity(0.88),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    AnimatedSwitcher(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: Text(
                        message,
                        key: ValueKey<String>(message),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: HexaColors.inkOnDark,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      percentage == null
                          ? 'Video cihazında hazırlanıyor'
                          : '%$percentage',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: percentage == null
                            ? Colors.white.withOpacity(0.46)
                            : HexaColors.purpleSoft,
                        fontSize: percentage == null ? 13 : 15,
                        height: 1.3,
                        fontWeight: percentage == null
                            ? FontWeight.w400
                            : FontWeight.w600,
                        letterSpacing: percentage == null ? -0.06 : -0.16,
                      ),
                    ),
                    if (normalizedProgress != null) ...[
                      const SizedBox(height: 21),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: normalizedProgress,
                          minHeight: 3,
                          color: HexaColors.purple,
                          backgroundColor: Colors.white.withOpacity(0.09),
                        ),
                      ),
                    ],
                    const SizedBox(height: 17),
                    Text(
                      'İşlem tamamlanana kadar bu ekranı açık tut.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.30),
                        fontSize: 11.5,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.04,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
