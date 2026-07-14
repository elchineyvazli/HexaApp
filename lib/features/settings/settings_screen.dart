import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: Stack(
        children: [
          if (!settings.isLoaded)
            const Center(child: CircularProgressIndicator())
          else
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                _Section(
                  title: 'Hexa modu',
                  description:
                      'Original tam deneyimi, Lite ise daha düşük veri, pil ve depolama kullanımını hedefler.',
                  child: Column(
                    children: [
                      _ModeCard(
                        title: 'Hexa Original',
                        description:
                            'Tam video kalitesi, animasyonlar, lo-fi ve gelişmiş özellikler.',
                        icon: Icons.auto_awesome_rounded,
                        selected: settings.appMode == HexaAppMode.original,
                        onTap: () {
                          _setOriginalMode(context, ref);
                        },
                      ),
                      const SizedBox(height: 10),
                      _ModeCard(
                        title: 'Hexa Lite',
                        description:
                            'Daha az ön yükleme, hafif animasyonlar ve küçük önbellek.',
                        icon: Icons.energy_savings_leaf_rounded,
                        selected: settings.appMode == HexaAppMode.lite,
                        onTap: () {
                          _requestLiteMode(context, ref);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _Section(
                  title: 'Görünüm',
                  description:
                      'Tema seçimi uygulama yeniden açıldığında korunur.',
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.7,
                    children: [
                      _ThemeCard(
                        title: 'Sistem',
                        icon: Icons.settings_suggest_rounded,
                        selected:
                            settings.themePreference ==
                            HexaThemePreference.system,
                        onTap: () {
                          _setTheme(ref, HexaThemePreference.system);
                        },
                      ),
                      _ThemeCard(
                        title: 'Light',
                        icon: Icons.light_mode_rounded,
                        selected:
                            settings.themePreference ==
                            HexaThemePreference.light,
                        onTap: () {
                          _setTheme(ref, HexaThemePreference.light);
                        },
                      ),
                      _ThemeCard(
                        title: 'Dark',
                        icon: Icons.dark_mode_rounded,
                        selected:
                            settings.themePreference ==
                            HexaThemePreference.dark,
                        onTap: () {
                          _setTheme(ref, HexaThemePreference.dark);
                        },
                      ),
                      _ThemeCard(
                        title: 'Green',
                        icon: Icons.eco_rounded,
                        selected:
                            settings.themePreference ==
                            HexaThemePreference.green,
                        onTap: () {
                          _setTheme(ref, HexaThemePreference.green);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _Section(
                  title: 'Lite davranışı',
                  description:
                      'Görünmemesi ve backend işleminin durması aynı şey değildir.',
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.play_circle_outline,
                        title: 'Yalnızca gerekli videolar hazırlanır',
                        enabled: settings.isLite,
                      ),
                      _InfoRow(
                        icon: Icons.animation_rounded,
                        title: 'Ağır animasyonlar azaltılır',
                        enabled: settings.isLite,
                      ),
                      _InfoRow(
                        icon: Icons.analytics_outlined,
                        title: 'Gelişmiş analiz sayfaları gizlenir',
                        enabled: settings.isLite,
                      ),
                      _InfoRow(
                        icon: Icons.favorite_rounded,
                        title:
                            'Signal, yorum, takip ve sayaçlar çalışmaya devam eder',
                        enabled: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _Section(
                  title: 'Depolama',
                  description:
                      'Hesap ve bulut verileri silinmez. Yalnızca yeniden indirilebilen geçici dosyalar temizlenir.',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.cleaning_services_rounded),
                    ),
                    title: const Text('Geçici dosyaları temizle'),
                    subtitle: const Text(
                      'Görsel ve indirilebilir medya önbelleğini temizler.',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: settings.isBusy
                        ? null
                        : () {
                            _clearTemporaryFiles(context, ref);
                          },
                  ),
                ),
                const SizedBox(height: 22),
                const _Section(
                  title: 'Yakında',
                  description:
                      'Sonraki profil ve güvenlik aşamalarında bağlanacak ayarlar.',
                  child: Column(
                    children: [
                      _ComingSoonRow(
                        icon: Icons.notifications_outlined,
                        title: 'Bildirim tercihleri',
                      ),
                      _ComingSoonRow(
                        icon: Icons.shield_outlined,
                        title: 'Gizlilik ve güvenlik',
                      ),
                      _ComingSoonRow(
                        icon: Icons.video_settings_outlined,
                        title: 'Video ve mobil veri kalitesi',
                      ),
                      _ComingSoonRow(
                        icon: Icons.block_outlined,
                        title: 'Engellenen kullanıcılar',
                      ),
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
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hexa Original etkinleştirildi.')),
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
          title: const Text('Hexa Lite etkinleştirilsin mi?'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lite moda geçildiğinde:'),
              SizedBox(height: 12),
              Text('• Video ön yükleme azaltılır'),
              SizedBox(height: 6),
              Text('• Ağır animasyonlar kapatılır'),
              SizedBox(height: 6),
              Text('• Geçici medya önbelleği temizlenir'),
              SizedBox(height: 6),
              Text('• Signal, yorum, takip ve sayaçlar çalışmaya devam eder'),
            ],
          ),
          actions: [
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hexa Lite etkinleştirildi ve geçici önbellek temizlendi.',
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Geçici dosyalar temizlendi.')),
    );
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ayar değiştirilemedi.')));
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
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
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: selected
                    ? scheme.primary
                    : scheme.surfaceContainerHighest,
                foregroundColor: selected
                    ? scheme.onPrimary
                    : scheme.onSurfaceVariant,
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? scheme.primary : scheme.outline,
              ),
            ],
          ),
        ),
      ),
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
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, size: 18, color: scheme.primary),
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
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 11),
          Expanded(child: Text(title)),
          Icon(
            enabled ? Icons.check_circle_rounded : Icons.remove_circle_outline,
            size: 19,
            color: enabled ? scheme.primary : scheme.outline,
          ),
        ],
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
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 11),
          Expanded(child: Text(title)),
          Text(
            'Yakında',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
