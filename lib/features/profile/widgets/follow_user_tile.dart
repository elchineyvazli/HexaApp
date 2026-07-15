import 'package:flutter/material.dart';

import '../profile_model.dart';

class FollowUserTile extends StatelessWidget {
  const FollowUserTile({
    super.key,
    required this.profile,
    required this.onTap,
  });

  final UserProfileModel profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayName = profile.displayName.trim();
    final bio = profile.bio.trim().replaceAll('\n', ' ');

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: scheme.surfaceContainerHighest,
        backgroundImage: profile.profileImageUrl.trim().isEmpty
            ? null
            : NetworkImage(profile.profileImageUrl),
        child: profile.profileImageUrl.trim().isEmpty
            ? Icon(Icons.person_rounded, color: scheme.onSurfaceVariant)
            : null,
      ),
      title: Text(
        profile.username,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (displayName.isNotEmpty)
            Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (bio.isNotEmpty)
            Text(
              bio,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
