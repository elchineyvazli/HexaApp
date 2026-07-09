// lib/features/feed/upload_form_fields.dart
import 'package:flutter/material.dart';

class UploadFormFields extends StatelessWidget {
  final TextEditingController captionController;
  final VoidCallback onSubmit;
  final bool isSubmitEnabled;

  const UploadFormFields({
    super.key,
    required this.captionController,
    required this.onSubmit,
    required this.isSubmitEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Açıklama Girişi
        TextField(
          controller: captionController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Videonun altına bir şeyler yaz...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF5E00)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Paylaş Butonu
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5E00),
            disabledBackgroundColor: const Color(0xFF334155),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: isSubmitEnabled ? onSubmit : null,
          child: const Text(
            'Şimdi Yayınla',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
