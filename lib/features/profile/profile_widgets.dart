import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';
import 'profile_model.dart';

// ---------- Yeni palet: Turuncu, Beyaz, Yeşil ----------
abstract final class _P {
  static const Color orange = Color(0xFFFF7B42);
  static const Color orangeDeep = Color(0xFFE55A2B);
  static const Color green = Color(0xFF2ECC71);
  static const Color greenDeep = Color(0xFF27AE60);
  static const Color orangeSoft = Color(0xFFFFF0E6);
  static const Color greenSoft = Color(0xFFE8F8F0);
  static const Color whiteCream = Color(0xFFFFFCF9);
  static const Color orangeBorder = Color(0xFFFFB38A);
  static const Color greenBorder = Color(0xFF82E0AA);
}

class ProfileHeader extends StatefulWidget {
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
  // (parametreler aynı bırakıldı)
  final UserProfileModel user;
  final int postsCount, totalSignals, followersCount, followingCount;
  final bool isCurrentUser, isFollowing, isFollowBusy;
  final VoidCallback onEditProfile,
      onToggleFollow,
      onFollowersTap,
      onFollowingTap;

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuint);
    Future.delayed(const Duration(milliseconds: 100), () => _ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(_anim),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_P.whiteCream, _P.orangeSoft],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _P.orangeBorder.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: _P.orange.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: _P.green.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ModernAvatar(user: widget.user),
                const SizedBox(height: 16),
                _StatsGrid(
                  posts: widget.postsCount,
                  followers: widget.followersCount,
                  following: widget.followingCount,
                  signals: widget.totalSignals,
                  onFollowers: widget.onFollowersTap,
                  onFollowing: widget.onFollowingTap,
                ),
                const SizedBox(height: 16),
                _BioBox(bio: widget.user.bio),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: widget.isCurrentUser
                          ? _EditBtn(onPressed: widget.onEditProfile)
                          : _FollowBtn(
                              isFollowing: widget.isFollowing,
                              busy: widget.isFollowBusy,
                              onTap: widget.onToggleFollow,
                            ),
                    ),
                    const SizedBox(width: 12),
                    _CoinChip(coins: widget.user.coins),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Avatar (çift halka, hexagon, yeşil pulsing) ----------
class _ModernAvatar extends StatelessWidget {
  const _ModernAvatar({required this.user});
  final UserProfileModel user;
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Dış yeşil halka (pulsing)
        TweenAnimationBuilder<double>(
          duration: const Duration(seconds: 2),
          tween: Tween(begin: 0.92, end: 1.08),
          builder: (_, val, child) => Transform.scale(scale: val, child: child),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _P.green.withOpacity(0.6), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: _P.green.withOpacity(0.3),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        // İç turuncu hexagon çerçeve
        SizedBox(
          width: 112,
          height: 112,
          child: CustomPaint(
            painter: _HexRing(_P.orange, _P.orange.withOpacity(0.4)),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: ClipOval(child: _AvatarImage(user: user)),
              ),
            ),
          ),
        ),
        // Onay rozeti (yeşil)
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _P.greenDeep,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.user});
  final UserProfileModel user;
  @override
  Widget build(BuildContext context) {
    final img = user.profileImageUrl.trim();
    if (img.isEmpty) return _Fallback(username: user.username);
    return Image.network(
      img,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _Fallback(username: user.username),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.username});
  final String username;
  @override
  Widget build(BuildContext context) {
    final letter =
        (username.replaceFirst('@', '').trim().isEmpty
                ? 'H'
                : username.replaceFirst('@', '').trim()[0])
            .toUpperCase();
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_P.orange, _P.orangeDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          letter,
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

class _HexRing extends CustomPainter {
  final Color stroke, glow;
  _HexRing(this.stroke, this.glow);
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;
    final gPaint = Paint()
      ..color = glow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    _draw(canvas, c, r, gPaint);
    _draw(
      canvas,
      c,
      r,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  void _draw(Canvas c, Offset o, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = i * pi / 3 - pi / 2;
      final x = o.dx + r * cos(a);
      final y = o.dy + r * sin(a);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_HexRing old) => stroke != old.stroke || glow != old.glow;
}

// ---------- İstatistikler (yeşil vurgulu) ----------
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.posts,
    required this.followers,
    required this.following,
    required this.signals,
    required this.onFollowers,
    required this.onFollowing,
  });
  final int posts, followers, following, signals;
  final VoidCallback onFollowers, onFollowing;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        color: _P.whiteCream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.greenBorder.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: _P.green.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatItem(value: posts, label: 'Gönderi', color: _P.orange),
          const _VDiv(color: _P.greenBorder),
          _StatItem(
            value: followers,
            label: 'Takipçi',
            color: _P.green,
            onTap: onFollowers,
          ),
          const _VDiv(color: _P.greenBorder),
          _StatItem(
            value: following,
            label: 'Takip',
            color: _P.orange,
            onTap: onFollowing,
          ),
          const _VDiv(color: _P.greenBorder),
          _StatItem(value: signals, label: 'Signal', color: _P.green),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });
  final int value;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final formatted = _compact(value);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatted,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: HexaColors.inkMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    if (onTap == null) return Expanded(child: Center(child: content));
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: content,
        ),
      ),
    );
  }
}

class _VDiv extends StatelessWidget {
  const _VDiv({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: color);
}

// ---------- Biyografi (yeşil arka plan) ----------
class _BioBox extends StatelessWidget {
  const _BioBox({required this.bio});
  final String bio;
  @override
  Widget build(BuildContext context) {
    final txt = bio.trim().isEmpty
        ? 'Kendini birkaç kelimeyle anlat...'
        : bio.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_P.greenSoft, _P.whiteCream],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.greenBorder.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.eco_rounded, color: _P.greenDeep, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              txt,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HexaColors.inkMuted,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Butonlar ----------
class _EditBtn extends StatelessWidget {
  const _EditBtn({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.edit_rounded, size: 19),
    label: const Text('Profili düzenle'),
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      backgroundColor: _P.orangeDeep,
      foregroundColor: Colors.white,
    ),
  );
}

class _FollowBtn extends StatelessWidget {
  const _FollowBtn({
    required this.isFollowing,
    required this.busy,
    required this.onTap,
  });
  final bool isFollowing, busy;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final content = AnimatedSwitcher(
      duration: HexaMotion.fast,
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
      child: busy
          ? SizedBox(
              key: const ValueKey('load'),
              width: 19,
              height: 19,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: isFollowing ? _P.orangeDeep : Colors.white,
              ),
            )
          : Row(
              key: ValueKey(isFollowing),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFollowing
                      ? Icons.person_remove_rounded
                      : Icons.person_add_rounded,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(isFollowing ? 'Takipten çık' : 'Takip et'),
              ],
            ),
    );
    if (isFollowing)
      return OutlinedButton(
        onPressed: busy ? null : onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: _P.orangeDeep,
          side: BorderSide(color: _P.orangeBorder),
        ),
        child: content,
      );
    return FilledButton(
      onPressed: busy ? null : onTap,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: _P.orangeDeep,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _P.orangeDeep,
        disabledForegroundColor: Colors.white,
      ),
      child: content,
    );
  }
}

// ---------- Coin çipi (yeşil) ----------
class _CoinChip extends StatelessWidget {
  const _CoinChip({required this.coins});
  final int coins;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 52, minWidth: 92),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: _P.greenSoft,
      borderRadius: BorderRadius.circular(HexaRadius.md),
      border: Border.all(color: _P.greenBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.monetization_on_rounded,
          color: _P.greenDeep,
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

String _compact(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return '$v';
}
