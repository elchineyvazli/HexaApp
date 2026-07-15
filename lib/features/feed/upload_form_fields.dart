import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

class UploadFormFields extends StatelessWidget {
  const UploadFormFields({
    required this.captionController,
    required this.onSubmit,
    required this.isSubmitEnabled,
    super.key,
  });

  final TextEditingController captionController;
  final VoidCallback onSubmit;
  final bool isSubmitEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: captionController,
          maxLines: 4,
          minLines: 3,
          maxLength: 300,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            labelText: 'Video açıklaması',
            hintText: 'Bu videonun insanlara nasıl değer katacağını anlat...',
            alignLabelWithHint: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 72),
              child: Icon(Icons.notes_rounded),
            ),
            helperText: 'Açık, anlaşılır ve anlamlı bir açıklama yaz.',
          ),
        ),
        const SizedBox(height: HexaSpacing.md),
        Container(
          padding: const EdgeInsets.all(HexaSpacing.sm),
          decoration: BoxDecoration(
            color: HexaColors.mintSoft,
            borderRadius: BorderRadius.circular(HexaRadius.md),
            border: Border.all(color: HexaColors.mint),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: HexaColors.success,
                size: 20,
              ),
              SizedBox(width: HexaSpacing.xs),
              Expanded(
                child: Text(
                  'İyi açıklamalar videonun doğru topluluğa ulaşmasına yardımcı olur.',
                  style: TextStyle(
                    color: HexaColors.success,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: HexaSpacing.lg),
        FilledButton.icon(
          onPressed: isSubmitEnabled ? onSubmit : null,
          icon: const Icon(Icons.publish_rounded),
          label: const Text('Şimdi yayınla'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(58)),
        ),
        if (!isSubmitEnabled) ...[
          const SizedBox(height: HexaSpacing.xs),
          const Text(
            'Yayınlamadan önce bir video seçmelisin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: HexaColors.inkSoft, fontSize: 11),
          ),
        ],
      ],
    );
  }
}
