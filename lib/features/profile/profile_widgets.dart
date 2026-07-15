import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

import 'profile_model.dart';

abstract final class _ProfilePalette {
  const _ProfilePalette._();

  static const Color orange = Color(0xFFF97316);
  static const Color orangeStrong = Color(0xFFEA580C);
  static const Color orangeSoft = Color(0xFFFFEDD5);
  static const Color orangeSurface = Color(0xFFFFF7ED);
  static const Color orangeBorder = Color(0xFFFDBA74);
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.user,
    required this.postsCount,
    required this.totalSignals,
    required this.followersCount,
    required this.followingCount,
    required this.isCurrentUser,
    required this.isFollowing,
    required this.isFollowBusy,
    required this.onEditProfile,
    required this.onToggleFollow,
    required this.onFollowersTap,
    required this.onFollowingTap,
    super.key,
  });

  final UserProfileModel user;
  final int postsCount;
  final int totalSignals;
  final int followersCount;
  final int followingCount;
  final bool isCurrentUser;
  final bool isFollowing;
  final bool isFollowBusy;
  final VoidCallback onEditProfile;
  final VoidCallback onToggleFollow;
  final VoidCallback onFollowersTap;
  final VoidCallback onFollowingTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HexaSpacing.md,
        HexaSpacing.sm,
        HexaSpacing.md,
        HexaSpacing.md,
      ),
      child: Container(
        width: double.infinity,
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
            Center(
              child: _ProfileAvatar(
                imageUrl: user.profileImageUrl,
                username: user.username,
              ),
            ),
            const SizedBox(height: HexaSpacing.md),
            _ProfileStatsRow(
              postsCount: postsCount,
              followersCount: followersCount,
              followingCount: followingCount,
              totalSignals: totalSignals,
              onFollowersTap: onFollowersTap,
              onFollowingTap: onFollowingTap,
            ),
            const SizedBox(height: HexaSpacing.md),
            _ProfileBio(bio: user.bio),
            const SizedBox(height: HexaSpacing.md),
            Row(
              children: [
                Expanded(
                  child: isCurrentUser
                      ? _EditProfileButton(onPressed: onEditProfile)
                      : _FollowButton(
                          isFollowing: isFollowing,
                          isBusy: isFollowBusy,
                          onPressed: onToggleFollow,
                        ),
                ),
                const SizedBox(width: HexaSpacing.sm),
                _CoinBadge(coins: user.coins),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.imageUrl, required this.username});

  final String imageUrl;
  final String username;

  @override
  Widget build(BuildContext context) {
    final cleanImageUrl = imageUrl.trim();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 106,
          height: 106,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: HexaColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: _ProfilePalette.orange, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33F97316),
                blurRadius: 20,
                spreadRadius: -2,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: cleanImageUrl.isEmpty
                ? _AvatarFallback(username: username)
                : Image.network(
                    cleanImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _AvatarFallback(username: username);
                    },
                  ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 3,
          child: Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: _ProfilePalette.orangeStrong,
              shape: BoxShape.circle,
              border: Border.all(color: HexaColors.surface, width: 2),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.verified_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    final normalized = username.replaceFirst('@', '').trim();

    final initial = normalized.isEmpty
        ? 'H'
        : normalized.substring(0, 1).toUpperCase();

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDBA74), Color(0xFFF97316), Color(0xFFEA580C)],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ProfileStatsRow extends StatelessWidget {
  const _ProfileStatsRow({
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    required this.totalSignals,
    required this.onFollowersTap,
    required this.onFollowingTap,
  });

  final int postsCount;
  final int followersCount;
  final int followingCount;
  final int totalSignals;
  final VoidCallback onFollowersTap;
  final VoidCallback onFollowingTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HexaSpacing.xs,
        vertical: HexaSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _ProfilePalette.orangeSurface,
        borderRadius: BorderRadius.circular(HexaRadius.md),
        border: Border.all(color: _ProfilePalette.orangeBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ProfileStat(
              value: _formatNumber(postsCount),
              label: 'Gönderi',
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _ProfileStat(
              value: _formatNumber(followersCount),
              label: 'Takipçi',
              onTap: onFollowersTap,
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _ProfileStat(
              value: _formatNumber(followingCount),
              label: 'Takip',
              onTap: onFollowingTap,
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _ProfileStat(
              value: _formatNumber(totalSignals),
              label: 'Signal',
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label, this.onTap});

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: HexaSpacing.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: HexaColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: HexaColors.inkMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Semantics(
      button: true,
      label: '$label listesini aç',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(HexaRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HexaRadius.sm),
          child: content,
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 42, color: _ProfilePalette.orangeBorder);
  }
}

class _ProfileBio extends StatelessWidget {
  const _ProfileBio({required this.bio});

  final String bio;

  @override
  Widget build(BuildContext context) {
    final cleanBio = bio.trim();
    final hasBio = cleanBio.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HexaSpacing.sm),
      decoration: BoxDecoration(
        color: HexaColors.surface,
        borderRadius: BorderRadius.circular(HexaRadius.md),
        border: Border.all(color: HexaColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote_rounded,
            color: _ProfilePalette.orangeStrong,
            size: 20,
          ),
          const SizedBox(width: HexaSpacing.xs),
          Expanded(
            child: Text(
              hasBio ? cleanBio : 'Henüz bir biyografi eklenmemiş.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: hasBio ? HexaColors.inkMuted : HexaColors.inkSoft,
                height: 1.45,
                fontStyle: hasBio ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.edit_rounded, size: 19),
      label: const Text('Profili düzenle'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: _ProfilePalette.orangeStrong,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _ProfilePalette.orangeSoft,
        disabledForegroundColor: HexaColors.inkSoft,
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.isFollowing,
    required this.isBusy,
    required this.onPressed,
  });

  final bool isFollowing;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedSwitcher(
      duration: HexaMotion.fast,
      child: isBusy
          ? SizedBox(
              key: const ValueKey<String>('loading'),
              width: 19,
              height: 19,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: isFollowing
                    ? _ProfilePalette.orangeStrong
                    : Colors.white,
              ),
            )
          : Row(
              key: ValueKey<bool>(isFollowing),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFollowing
                      ? Icons.person_remove_rounded
                      : Icons.person_add_rounded,
                  size: 18,
                ),
                const SizedBox(width: HexaSpacing.xs),
                Text(isFollowing ? 'Takipten çık' : 'Takip et'),
              ],
            ),
    );

    if (isFollowing) {
      return OutlinedButton(
        onPressed: isBusy ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: _ProfilePalette.orangeStrong,
          side: const BorderSide(color: _ProfilePalette.orangeBorder),
        ),
        child: content,
      );
    }

    return FilledButton(
      onPressed: isBusy ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: _ProfilePalette.orangeStrong,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _ProfilePalette.orangeStrong,
        disabledForegroundColor: Colors.white,
      ),
      child: content,
    );
  }
}

class _CoinBadge extends StatelessWidget {
  const _CoinBadge({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52, minWidth: 92),
      padding: const EdgeInsets.symmetric(
        horizontal: HexaSpacing.sm,
        vertical: HexaSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _ProfilePalette.orangeSoft,
        borderRadius: BorderRadius.circular(HexaRadius.md),
        border: Border.all(color: _ProfilePalette.orangeBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on_rounded,
            color: _ProfilePalette.orangeStrong,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            '$coins C',
            style: const TextStyle(
              color: HexaColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatNumber(int count) {
  final safeCount = count < 0 ? 0 : count;

  if (safeCount >= 1000000) {
    return '${(safeCount / 1000000).toStringAsFixed(1)}M';
  }

  if (safeCount >= 1000) {
    return '${(safeCount / 1000).toStringAsFixed(1)}K';
  }

  return '$safeCount';
}
