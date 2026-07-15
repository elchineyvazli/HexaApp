import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

import '../profile_model.dart';

const Color profileOrange = Color(0xFFF97316);
const Color profileOrangeStrong = Color(0xFFEA580C);
const Color profileOrangeSoft = Color(0xFFFFEDD5);
const Color profileOrangeBorder = Color(0xFFFDBA74);
const Color profilePageBackground = Color(0xFFFFFAF5);

const LinearGradient profilePageGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFFFFCF9), Color(0xFFFFF7ED), Color(0xFFFFFAF5)],
  stops: [0, 0.54, 1],
);

class ProfilePageHeader extends StatelessWidget {
  const ProfilePageHeader({
    required this.profile,
    required this.isCurrentUser,
    required this.canGoBack,
    required this.onMenu,
    required this.child,
    super.key,
  });

  final UserProfileModel profile;
  final bool isCurrentUser;
  final bool canGoBack;
  final VoidCallback onMenu;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              HexaSpacing.sm,
              HexaSpacing.xs,
              HexaSpacing.sm,
              0,
            ),
            child: Row(
              children: [
                if (canGoBack) ...[
                  _HeaderButton(
                    tooltip: 'Geri dön',
                    icon: Icons.arrow_back_rounded,
                    onPressed: () {
                      Navigator.of(context).maybePop();
                    },
                  ),
                  const SizedBox(width: HexaSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCurrentUser ? 'Profilin' : 'Profil',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: HexaColors.ink,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      if (profile.username.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          profile.username.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: HexaColors.inkMuted,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isCurrentUser)
                  _HeaderButton(
                    tooltip: 'Profil menüsü',
                    icon: Icons.menu_rounded,
                    onPressed: onMenu,
                  ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class ProfileTabSliver extends StatelessWidget {
  const ProfileTabSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      primary: false,
      pinned: true,
      automaticallyImplyLeading: false,
      toolbarHeight: 0,
      backgroundColor: profilePageBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          height: 56,
          margin: const EdgeInsets.fromLTRB(
            HexaSpacing.md,
            4,
            HexaSpacing.md,
            HexaSpacing.xs,
          ),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xF7FFFFFF),
            borderRadius: BorderRadius.circular(HexaRadius.lg),
            border: Border.all(color: profileOrangeBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18EA580C),
                blurRadius: 18,
                spreadRadius: -5,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: profileOrangeSoft,
              borderRadius: BorderRadius.circular(HexaRadius.md),
            ),
            labelColor: profileOrangeStrong,
            unselectedLabelColor: HexaColors.inkMuted,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.grid_view_rounded, size: 20),
                text: 'Videolar',
              ),
              Tab(
                icon: Icon(Icons.bookmark_border_rounded, size: 20),
                text: 'Kaydedilenler',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xF7FFFFFF),
        borderRadius: BorderRadius.circular(HexaRadius.md),
        border: Border.all(color: profileOrangeBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12EA580C),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: HexaColors.ink),
      ),
    );
  }
}
