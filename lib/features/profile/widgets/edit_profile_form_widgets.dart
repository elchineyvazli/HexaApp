// lib/features/profile/widgets/edit_profile_form_widgets.dart

import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

class EditProfileHeader extends StatelessWidget {
  const EditProfileHeader({
    required this.isLoading,
    required this.onClose,
    required this.onSave,
    super.key,
  });

  final bool isLoading;
  final VoidCallback onClose;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        HexaSpacing.xs,
        HexaSpacing.xs,
        HexaSpacing.xs,
        HexaSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: Color(0xEFFFFFFF),
        border: Border(bottom: BorderSide(color: HexaColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Kapat',
            onPressed: isLoading ? null : onClose,
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: HexaSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profili düzenle',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  'Bilgilerini güncel ve anlaşılır tut.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: HexaColors.inkMuted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: isLoading ? null : onSave,
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

class EditProfileSection extends StatelessWidget {
  const EditProfileSection({
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
                child: Icon(icon, color: HexaColors.signalStrong, size: 21),
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

class EditProfileCategorySelector extends StatelessWidget {
  const EditProfileCategorySelector({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
    super.key,
  });

  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: HexaSpacing.xs,
      runSpacing: HexaSpacing.xs,
      children: categories
          .map((category) {
            final selected = category == selectedCategory;

            return ChoiceChip(
              selected: selected,
              label: Text(category),
              avatar: Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 17,
                color: selected ? HexaColors.signalStrong : HexaColors.inkMuted,
              ),
              onSelected: (_) {
                onSelected(category);
              },
            );
          })
          .toList(growable: false),
    );
  }
}
