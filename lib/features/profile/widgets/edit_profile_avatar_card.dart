// lib/features/profile/widgets/edit_profile_avatar_card.dart

import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

class EditProfileAvatarCard extends StatelessWidget {
  const EditProfileAvatarCard({
    required this.imageUrl,
    required this.username,
    required this.onTap,
    super.key,
  });

  final String imageUrl;
  final String username;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HexaSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xF7FFFFFF),
        borderRadius: BorderRadius.circular(HexaRadius.lg),
        border: Border.all(color: HexaColors.border),
        boxShadow: HexaShadows.soft,
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: HexaColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: HexaColors.borderStrong,
                        width: 1.5,
                      ),
                      boxShadow: HexaShadows.signal,
                    ),
                    child: ClipOval(
                      child: imageUrl.trim().isEmpty
                          ? _AvatarFallback(username: username)
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _AvatarFallback(username: username);
                              },
                            ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 2,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: HexaColors.signalStrong,
                        shape: BoxShape.circle,
                        border: Border.all(color: HexaColors.surface, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.photo_camera_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: HexaSpacing.md),
          Text(
            'Profil görseli',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: HexaSpacing.xs),
          Text(
            'Görsel seçeneklerini açmak için fotoğrafa dokun.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: HexaColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    final cleanUsername = username.replaceFirst('@', '').trim();

    final initial = cleanUsername.isEmpty
        ? 'H'
        : cleanUsername.substring(0, 1).toUpperCase();

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: HexaGradients.hope),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
