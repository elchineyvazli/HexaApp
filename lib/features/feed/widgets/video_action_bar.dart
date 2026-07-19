import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/hexa_theme.dart';
import '../feed_models.dart';

class VideoActionBar extends StatefulWidget {
  const VideoActionBar({
    required this.isVisible,
    required this.video,
    required this.isLiked,
    required this.isSaved,
    required this.signalCount,
    required this.onProfilePressed,
    required this.onLikePressed,
    required this.onSharePressed,
    required this.onSavePressed,
    super.key,
  });

  final bool isVisible;
  final VideoModel video;

  final bool isLiked;
  final bool isSaved;
  final int signalCount;

  final VoidCallback onProfilePressed;
  final VoidCallback onLikePressed;
  final VoidCallback onSharePressed;
  final VoidCallback onSavePressed;

  @override
  State<VideoActionBar> createState() {
    return _VideoActionBarState();
  }
}

class _VideoActionBarState extends State<VideoActionBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  late final List<Animation<double>> _actionAnimations;

  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 220),
      value: widget.isVisible ? 1 : 0,
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.72, curve: Curves.easeOutCubic),
      reverseCurve: Curves.easeInCubic,
    );

    _slide = Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _actionAnimations = List<Animation<double>>.generate(4, (index) {
      final start = 0.12 + index * 0.07;
      final end = (start + 0.48).clamp(0.0, 1.0);

      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    }, growable: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _reduceMotion = HexaMotion.reduceMotionOf(context);

    if (_reduceMotion) {
      _controller.value = widget.isVisible ? 1 : 0;
    }
  }

  @override
  void didUpdateWidget(covariant VideoActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isVisible == widget.isVisible) {
      return;
    }

    if (_reduceMotion) {
      _controller.value = widget.isVisible ? 1 : 0;
      return;
    }

    if (widget.isVisible) {
      _controller.forward(from: 0);
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 8,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 4),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                if (_controller.value == 0 && !widget.isVisible) {
                  return const SizedBox.shrink();
                }

                return IgnorePointer(
                  ignoring: _controller.value < 0.68,
                  child: FadeTransition(
                    opacity: _opacity,
                    child: SlideTransition(position: _slide, child: child),
                  ),
                );
              },
              child: _buildPanel(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 86,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xEC111116),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0x1FFFFFFF)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x73000000),
                blurRadius: 30,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _StaggeredAction(
                  animation: _actionAnimations[0],
                  child: _ActionSurface(
                    icon: widget.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    semanticsLabel: widget.isLiked
                        ? 'Beğeniyi kaldır'
                        : 'Videoyu beğen',
                    label: _compactCount(widget.signalCount),
                    active: widget.isLiked,
                    activeColor: const Color(0xFF8B5CF6),
                    onPressed: widget.onLikePressed,
                  ),
                ),
              ),
              Expanded(
                child: _StaggeredAction(
                  animation: _actionAnimations[1],
                  child: _ProfileSurface(
                    avatarUrl: widget.video.uploaderAvatarUrl,
                    enabled: widget.video.hasUploaderProfile,
                    onPressed: widget.onProfilePressed,
                  ),
                ),
              ),
              Expanded(
                child: _StaggeredAction(
                  animation: _actionAnimations[2],
                  child: _ActionSurface(
                    icon: Icons.ios_share_rounded,
                    semanticsLabel: 'Videoyu paylaş',
                    label: 'Paylaş',
                    onPressed: widget.onSharePressed,
                  ),
                ),
              ),
              Expanded(
                child: _StaggeredAction(
                  animation: _actionAnimations[3],
                  child: _ActionSurface(
                    icon: widget.isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    semanticsLabel: widget.isSaved
                        ? 'Kaydedilenlerden çıkar'
                        : 'Videoyu kaydet',
                    label: 'Kaydet',
                    active: widget.isSaved,
                    activeColor: const Color(0xFF06B6D4),
                    onPressed: widget.onSavePressed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaggeredAction extends StatelessWidget {
  const _StaggeredAction({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = animation.value.clamp(0.0, 1.0).toDouble();

        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)),
            child: Transform.scale(scale: 0.94 + value * 0.06, child: child),
          ),
        );
      },
      child: child,
    );
  }
}

class _ActionSurface extends StatefulWidget {
  const _ActionSurface({
    required this.icon,
    required this.semanticsLabel,
    required this.label,
    required this.onPressed,
    this.active = false,
    this.activeColor = Colors.white,
  });

  final IconData icon;
  final String semanticsLabel;
  final String label;
  final VoidCallback onPressed;

  final bool active;
  final Color activeColor;

  @override
  State<_ActionSurface> createState() {
    return _ActionSurfaceState();
  }
}

class _ActionSurfaceState extends State<_ActionSurface> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    final foregroundColor = widget.active
        ? widget.activeColor
        : const Color(0xEBFFFFFF);

    return Semantics(
      button: true,
      toggled: widget.active,
      label: widget.semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          _setPressed(true);
        },
        onTapCancel: () {
          _setPressed(false);
        },
        onTapUp: (_) {
          _setPressed(false);
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.88 : 1,
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.82,
                          end: 1,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    widget.icon,
                    key: ValueKey<IconData>(widget.icon),
                    color: foregroundColor,
                    size: 25,
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    color: widget.active
                        ? foregroundColor
                        : const Color(0xAFFFFFFF),
                    fontSize: 10,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.05,
                  ),
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSurface extends StatefulWidget {
  const _ProfileSurface({
    required this.avatarUrl,
    required this.enabled,
    required this.onPressed,
  });

  final String avatarUrl;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_ProfileSurface> createState() {
    return _ProfileSurfaceState();
  }
}

class _ProfileSurfaceState extends State<_ProfileSurface> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: 'İçerik sahibinin profiline git',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled
            ? (_) {
                _setPressed(true);
              }
            : null,
        onTapCancel: widget.enabled
            ? () {
                _setPressed(false);
              }
            : null,
        onTapUp: widget.enabled
            ? (_) {
                _setPressed(false);
                widget.onPressed();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.88 : 1,
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Opacity(
            opacity: widget.enabled ? 1 : 0.38,
            child: SizedBox.expand(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(1.4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: widget.enabled
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                Color(0xFF8B5CF6),
                                Color(0xFF06B6D4),
                              ],
                            )
                          : null,
                      color: widget.enabled ? null : const Color(0x29FFFFFF),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF111116),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: ColoredBox(
                          color: const Color(0xFF202027),
                          child: _buildAvatar(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Profil',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xAFFFFFFF),
                      fontSize: 10,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.05,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final avatarUrl = widget.avatarUrl.trim();

    if (avatarUrl.isEmpty) {
      return const Center(
        child: Icon(Icons.person_rounded, color: Color(0xCFFFFFFF), size: 21),
      );
    }

    return CachedNetworkImage(
      imageUrl: avatarUrl,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 140),
      fadeOutDuration: const Duration(milliseconds: 100),
      placeholder: (_, __) {
        return const Center(
          child: SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
              strokeWidth: 1.4,
              color: Color(0x99FFFFFF),
            ),
          ),
        );
      },
      errorWidget: (_, __, ___) {
        return const Center(
          child: Icon(Icons.person_rounded, color: Color(0xCFFFFFFF), size: 21),
        );
      },
    );
  }
}

String _compactCount(int value) {
  if (value >= 1000000000) {
    return _formatCompactValue(value / 1000000000, 'B');
  }

  if (value >= 1000000) {
    return _formatCompactValue(value / 1000000, 'M');
  }

  if (value >= 1000) {
    return _formatCompactValue(value / 1000, 'K');
  }

  return value.toString();
}

String _formatCompactValue(double value, String suffix) {
  final formatted = value >= 100
      ? value.toStringAsFixed(0)
      : value >= 10
      ? value.toStringAsFixed(1)
      : value.toStringAsFixed(1);

  final cleaned = formatted.endsWith('.0')
      ? formatted.substring(0, formatted.length - 2)
      : formatted;

  return '$cleaned$suffix';
}
