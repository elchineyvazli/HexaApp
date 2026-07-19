import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hexa_theme.dart';
import 'app_settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? HexaColors.backgroundDark
        : HexaColors.background;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              const _SettingsHeader(),
              Divider(
                height: 1,
                thickness: 1,
                color: theme.dividerColor.withOpacity(isDark ? 0.72 : 0.85),
              ),
              Expanded(
                child: Stack(
                  children: <Widget>[
                    if (!settings.isLoaded)
                      const _SettingsLoadingView()
                    else
                      ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 42),
                        children: <Widget>[
                          _Section(
                            title: 'Uygulama modu',
                            description:
                                'HEXA’nın performans ve medya kullanım biçimini seç.',
                            child: _SettingsGroup(
                              padding: const EdgeInsets.all(7),
                              children: <Widget>[
                                _ModeCard(
                                  title: 'HEXA Original',
                                  description:
                                      'Tam video kalitesi, animasyonlar ve gelişmiş deneyim.',
                                  icon: Icons.auto_awesome_rounded,
                                  selected:
                                      settings.appMode == HexaAppMode.original,
                                  onTap: () {
                                    _setOriginalMode(context, ref);
                                  },
                                ),
                                const SizedBox(height: 7),
                                _ModeCard(
                                  title: 'HEXA Lite',
                                  description:
                                      'Daha düşük veri, pil ve depolama kullanımı.',
                                  icon: Icons.energy_savings_leaf_outlined,
                                  selected:
                                      settings.appMode == HexaAppMode.lite,
                                  onTap: () {
                                    _requestLiteMode(context, ref);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          _Section(
                            title: 'Görünüm',
                            description: 'Uygulamanın genel tema tercihi.',
                            child: _ThemeSelector(
                              preference: settings.themePreference,
                              onSelected: (preference) {
                                _setTheme(ref, preference);
                              },
                            ),
                          ),
                          const SizedBox(height: 28),
                          _Section(
                            title: 'Lite davranışı',
                            description: settings.isLite
                                ? 'Lite modunda kullanılan optimizasyonlar.'
                                : 'Lite moda geçtiğinde uygulanacak değişiklikler.',
                            child: _SettingsGroup(
                              children: <Widget>[
                                _InfoRow(
                                  icon: Icons.play_circle_outline_rounded,
                                  title: 'Yalnızca gerekli videolar hazırlanır',
                                  enabled: settings.isLite,
                                ),
                                const _GroupDivider(),
                                _InfoRow(
                                  icon: Icons.animation_rounded,
                                  title: 'Ağır animasyonlar azaltılır',
                                  enabled: settings.isLite,
                                ),
                                const _GroupDivider(),
                                _InfoRow(
                                  icon: Icons.analytics_outlined,
                                  title: 'Gelişmiş analiz sayfaları gizlenir',
                                  enabled: settings.isLite,
                                ),
                                const _GroupDivider(),
                                const _InfoRow(
                                  icon: Icons.favorite_border_rounded,
                                  title:
                                      'Beğeni, yorum ve takip özellikleri çalışmaya devam eder',
                                  enabled: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          _Section(
                            title: 'Depolama',
                            description: 'Hesap ve bulut verilerin etkilenmez.',
                            child: _SettingsGroup(
                              children: <Widget>[
                                _SettingsActionRow(
                                  icon: Icons.cleaning_services_outlined,
                                  title: 'Geçici dosyaları temizle',
                                  subtitle:
                                      'İndirilebilir medya ve görsel önbelleği',
                                  enabled: !settings.isBusy,
                                  onTap: () {
                                    _clearTemporaryFiles(context, ref);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          const _Section(
                            title: 'Diğer ayarlar',
                            description:
                                'Gelecek sürümlerde kullanıma açılacak seçenekler.',
                            child: _SettingsGroup(
                              children: <Widget>[
                                _ComingSoonRow(
                                  icon: Icons.notifications_none_rounded,
                                  title: 'Bildirim tercihleri',
                                ),
                                _GroupDivider(),
                                _ComingSoonRow(
                                  icon: Icons.shield_outlined,
                                  title: 'Gizlilik ve güvenlik',
                                ),
                                _GroupDivider(),
                                _ComingSoonRow(
                                  icon: Icons.video_settings_outlined,
                                  title: 'Video ve mobil veri kalitesi',
                                ),
                                _GroupDivider(),
                                _ComingSoonRow(
                                  icon: Icons.block_outlined,
                                  title: 'Engellenen kullanıcılar',
                                ),
                                _GroupDivider(),
                                _ComingSoonRow(
                                  icon: Icons.manage_accounts_outlined,
                                  title: 'Hesap yönetimi',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    if (settings.isBusy)
                      const Positioned.fill(child: _SettingsBusyOverlay()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setOriginalMode(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(appSettingsProvider.notifier)
          .setAppMode(HexaAppMode.original);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('HEXA Original etkinleştirildi.')),
        );
    } catch (_) {
      _showError(context);
    }
  }

  Future<void> _requestLiteMode(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('HEXA Lite’a geçilsin mi?'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _LiteDialogRow(
                icon: Icons.play_circle_outline_rounded,
                text: 'Video ön yükleme azaltılır.',
              ),
              SizedBox(height: 13),
              _LiteDialogRow(
                icon: Icons.animation_rounded,
                text: 'Ağır animasyonlar kapatılır.',
              ),
              SizedBox(height: 13),
              _LiteDialogRow(
                icon: Icons.cleaning_services_outlined,
                text: 'Geçici medya önbelleği temizlenir.',
              ),
              SizedBox(height: 13),
              _LiteDialogRow(
                icon: Icons.favorite_border_rounded,
                text:
                    'Beğeni, yorum ve takip özellikleri çalışmaya devam eder.',
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Lite’a geç'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref.read(appSettingsProvider.notifier).setAppMode(HexaAppMode.lite);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'HEXA Lite etkinleştirildi ve geçici önbellek temizlendi.',
            ),
          ),
        );
    } catch (_) {
      _showError(context);
    }
  }

  void _setTheme(WidgetRef ref, HexaThemePreference preference) {
    ref.read(appSettingsProvider.notifier).setThemePreference(preference);
  }

  Future<void> _clearTemporaryFiles(BuildContext context, WidgetRef ref) async {
    await ref.read(appSettingsProvider.notifier).clearTemporaryFiles();

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Geçici dosyalar temizlendi.')),
      );
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Ayar değiştirilemedi.')));
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final theme = Theme.of(context);

    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: <Widget>[
            if (canPop)
              IconButton(
                tooltip: 'Geri',
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 22),
              )
            else
              const SizedBox(width: 48),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                'Ayarlar',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.42,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.25,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.06,
            ),
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.children,
    this.padding = EdgeInsets.zero,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? HexaColors.surfaceDark : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(
            isDark ? 0.62 : 0.85,
          ),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        overlayColor: WidgetStatePropertyAll<Color>(
          HexaColors.purple.withOpacity(0.10),
        ),
        child: AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(13, 13, 12, 13),
          decoration: BoxDecoration(
            color: selected
                ? HexaColors.purple.withOpacity(
                    theme.brightness == Brightness.dark ? 0.13 : 0.09,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? HexaColors.purple.withOpacity(0.48)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? HexaColors.purple.withOpacity(0.16)
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(
                          0.62,
                        ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? HexaColors.purple
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11.5,
                        height: 1.35,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.04,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 160),
                child: Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  key: ValueKey<bool>(selected),
                  size: 20,
                  color: selected
                      ? HexaColors.purple
                      : theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.preference, required this.onSelected});

  final HexaThemePreference preference;
  final ValueChanged<HexaThemePreference> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 8) / 2;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            SizedBox(
              width: itemWidth,
              child: _ThemeCard(
                title: 'Sistem',
                icon: Icons.settings_suggest_outlined,
                selected: preference == HexaThemePreference.system,
                onTap: () {
                  onSelected(HexaThemePreference.system);
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _ThemeCard(
                title: 'Açık',
                icon: Icons.light_mode_outlined,
                selected: preference == HexaThemePreference.light,
                onTap: () {
                  onSelected(HexaThemePreference.light);
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _ThemeCard(
                title: 'Koyu',
                icon: Icons.dark_mode_outlined,
                selected: preference == HexaThemePreference.dark,
                onTap: () {
                  onSelected(HexaThemePreference.dark);
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _ThemeCard(
                title: 'Yeşil',
                icon: Icons.eco_outlined,
                selected: preference == HexaThemePreference.green,
                onTap: () {
                  onSelected(HexaThemePreference.green);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 170),
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: selected
                ? HexaColors.purple.withOpacity(
                    theme.brightness == Brightness.dark ? 0.13 : 0.09,
                  )
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected
                  ? HexaColors.purple.withOpacity(0.52)
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 19,
                color: selected
                    ? HexaColors.purple
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: -0.10,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  color: HexaColors.purple,
                  size: 17,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.enabled,
  });

  final IconData icon;
  final String title;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 13, 14, 13),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 13,
                height: 1.32,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.10,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            enabled ? Icons.check_rounded : Icons.remove_rounded,
            size: 18,
            color: enabled ? HexaColors.purple : theme.colorScheme.outline,
          ),
        ],
      ),
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 13, 10, 13),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 21,
                color: enabled
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.disabledColor,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        color: enabled
                            ? theme.colorScheme.onSurface
                            : theme.disabledColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11.5,
                        height: 1.3,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.04,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 21,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonRow extends StatelessWidget {
  const _ComingSoonRow({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 13, 14, 13),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.10,
              ),
            ),
          ),
          Text(
            'Yakında',
            style: TextStyle(
              color: theme.colorScheme.outline,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.04,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).dividerColor.withOpacity(0.74),
      ),
    );
  }
}

class _LiteDialogRow extends StatelessWidget {
  const _LiteDialogRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: HexaColors.purple.withOpacity(0.11),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: HexaColors.purple),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsLoadingView extends StatelessWidget {
  const _SettingsLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Ayarlar yükleniyor',
        liveRegion: true,
        child: const SizedBox.square(
          dimension: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.1,
            color: HexaColors.purple,
            backgroundColor: Color(0x1AFFFFFF),
          ),
        ),
      ),
    );
  }
}

class _SettingsBusyOverlay extends StatelessWidget {
  const _SettingsBusyOverlay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ColoredBox(
      color: isDark ? const Color(0xA6050507) : const Color(0x80000000),
      child: Center(
        child: Container(
          width: 62,
          height: 62,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark
                ? HexaColors.surfaceStrongDark
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: const SizedBox.square(
            dimension: 23,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: HexaColors.purple,
            ),
          ),
        ),
      ),
    );
  }
}
