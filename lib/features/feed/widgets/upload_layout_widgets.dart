import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';
import 'package:hexa/features/auth/presentation/widgets/auth_background.dart';

class UploadHeader extends StatelessWidget {
  const UploadHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HexaSpacing.xs,
        HexaSpacing.xs,
        HexaSpacing.md,
        HexaSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Geri dön',
            onPressed: () {
              Navigator.of(context).maybePop();
            },
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: HexaSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yeni video',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  'Topluluğa değer katacak bir şey paylaş',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: HexaColors.inkMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: HexaColors.signalSoft,
              borderRadius: BorderRadius.circular(HexaRadius.pill),
              border: Border.all(color: HexaColors.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: HexaColors.signalStrong,
                  size: 14,
                ),
                SizedBox(width: 5),
                Text(
                  'PAYLAŞ',
                  style: TextStyle(
                    color: HexaColors.signalStrong,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
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
    return Container(
      padding: const EdgeInsets.all(HexaSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xF7FFFFFF),
        borderRadius: BorderRadius.circular(HexaRadius.lg),
        border: Border.all(color: HexaColors.border),
        boxShadow: HexaShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: HexaColors.lavenderSoft,
                  borderRadius: BorderRadius.circular(HexaRadius.md),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: HexaColors.signalStrong, size: 22),
              ),
              const SizedBox(width: HexaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HexaColors.inkMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: HexaSpacing.md),
          child,
        ],
      ),
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
    final normalizedProgress = progress?.clamp(0, 1).toDouble();
    final percentage = normalizedProgress == null
        ? null
        : (normalizedProgress * 100).round();

    return Scaffold(
      backgroundColor: HexaColors.background,
      body: Stack(
        children: [
          const AuthBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(HexaSpacing.lg),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 380),
                  padding: const EdgeInsets.all(HexaSpacing.lg),
                  decoration: BoxDecoration(
                    color: const Color(0xF7FFFFFF),
                    borderRadius: BorderRadius.circular(HexaRadius.lg),
                    border: Border.all(color: HexaColors.border),
                    boxShadow: HexaShadows.soft,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          color: HexaColors.signalSoft,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          icon,
                          color: HexaColors.signalStrong,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: HexaSpacing.lg),
                      SizedBox(
                        width: 46,
                        height: 46,
                        child: CircularProgressIndicator(
                          value: normalizedProgress,
                          strokeWidth: 4,
                        ),
                      ),
                      const SizedBox(height: HexaSpacing.md),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: HexaSpacing.xs),
                      Text(
                        percentage == null
                            ? 'Video hazırlanırken uygulamayı kapatma.'
                            : '%$percentage tamamlandı',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HexaColors.inkMuted,
                        ),
                      ),
                      if (normalizedProgress != null) ...[
                        const SizedBox(height: HexaSpacing.md),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(HexaRadius.pill),
                          child: LinearProgressIndicator(
                            value: normalizedProgress,
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
