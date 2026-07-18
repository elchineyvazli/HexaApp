import 'dart:ui';
import 'dart:math' as math;

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
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  late final List<Animation<double>> _actionAnimations;

  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: HexaMotion.slow,
      value: widget.isVisible ? 1 : 0,
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.42, curve: HexaMotion.enter),
      reverseCurve: HexaMotion.exit,
    );

    _scale = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: HexaMotion.emphasized,
        reverseCurve: HexaMotion.exit,
      ),
    );

    _slide = Tween<Offset>(begin: const Offset(0, 0.28), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: HexaMotion.emphasized,
            reverseCurve: HexaMotion.exit,
          ),
        );

    _actionAnimations = List<Animation<double>>.generate(4, (index) {
      final start = 0.16 + index * 0.1;
      final end = (start + 0.46).clamp(0, 1).toDouble();

      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: HexaMotion.listEnter),
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
      left: HexaSpacing.sm,
      right: HexaSpacing.sm,
      bottom: HexaSpacing.sm,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: HexaSpacing.xs),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 410),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                if (_controller.value == 0 && !widget.isVisible) {
                  return const SizedBox.shrink();
                }

                return IgnorePointer(
                  ignoring: _controller.value < 0.72,
                  child: FadeTransition(
                    opacity: _opacity,
                    child: SlideTransition(
                      position: _slide,
                      child: ScaleTransition(scale: _scale, child: child),
                    ),
                  ),
                );
              },
              child: _buildPanel(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    return ClipRRect(
      borderRadius: HexaRadius.borderLg,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: HexaColors.earth.withAlpha(178),
            borderRadius: HexaRadius.borderLg,
            border: Border.all(color: HexaColors.white.withAlpha(34)),
            boxShadow: widget.isLiked
                ? HexaShadows.signal
                : HexaShadows.floating,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _StaggeredAction(
                  animation: _actionAnimations[0],
                  child: _ActionSurface(
                    icon: widget.isLiked
                        ? Icons.auto_awesome_rounded
                        : Icons.auto_awesome_outlined,
                    semanticsLabel: widget.isLiked
                        ? 'Hexa beğenisini kaldır'
                        : 'Hexa beğenisi gönder',
                    count: _compactCount(widget.signalCount),
                    active: widget.isLiked,
                    activeColor: HexaColors.hopePink,
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
                    icon: widget.isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    semanticsLabel: widget.isSaved
                        ? 'Kaydedilenlerden çıkar'
                        : 'Videoyu kaydet',
                    active: widget.isSaved,
                    activeColor: HexaColors.warning,
                    onPressed: widget.onSavePressed,
                  ),
                ),
              ),
              Expanded(
                child: _StaggeredAction(
                  animation: _actionAnimations[3],
                  child: _ActionSurface(
                    icon: Icons.ios_share_rounded,
                    semanticsLabel: 'Videoyu paylaş',
                    onPressed: widget.onSharePressed,
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
        final double value = animation.value.clamp(0.0, 1.0).toDouble();
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 9 * (1 - value)),
            child: Transform.scale(scale: 0.82 + value * 0.18, child: child),
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
    required this.onPressed,
    this.count,
    this.active = false,
    this.activeColor = HexaColors.white,
  });

  final IconData icon;
  final String semanticsLabel;
  final VoidCallback onPressed;

  final String? count;
  final bool active;
  final Color activeColor;

  @override
  State<_ActionSurface> createState() {
    return _ActionSurfaceState();
  }
}

class _ActionSurfaceState extends State<_ActionSurface> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    final color = widget.active ? widget.activeColor : HexaColors.white;

    return Semantics(
      button: true,
      toggled: widget.active,
      label: widget.semanticsLabel,
      child: Tooltip(
        message: widget.semanticsLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            setState(() => _pressed = true);
          },
          onTapCancel: () {
            setState(() => _pressed = false);
          },
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onPressed();
          },
          child: AnimatedScale(
            scale: _pressed ? HexaMotion.pressScale : 1,
            duration: reduceMotion ? Duration.zero : HexaMotion.fast,
            curve: HexaMotion.elastic,
            child: SizedBox.expand(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  AnimatedSwitcher(
                    duration: reduceMotion ? Duration.zero : HexaMotion.fast,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      );
                    },
                    child: Icon(
                      widget.icon,
                      key: ValueKey<IconData>(widget.icon),
                      color: color,
                      size: 24,
                    ),
                  ),
                  if (widget.count != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.count!,
                      style: TextStyle(
                        color: widget.active
                            ? color
                            : HexaColors.white.withAlpha(170),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSurface extends StatelessWidget {
  const _ProfileSurface({
    required this.avatarUrl,
    required this.enabled,
    required this.onPressed,
  });

  final String avatarUrl;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'İçerik sahibinin profiline git',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onPressed : null,
        child: Center(
          child: Opacity(
            opacity: enabled ? 1 : 0.42,
            child: ClipPath(
              clipper: const _HexagonClipper(),
              child: Container(
                width: 39,
                height: 39,
                color: HexaColors.white.withAlpha(22),
                child: avatarUrl.trim().isEmpty
                    ? const Icon(
                        Icons.person_outline_rounded,
                        color: HexaColors.white,
                        size: 21,
                      )
                    : CachedNetworkImage(
                        imageUrl: avatarUrl,
                        fit: BoxFit.cover,
                        fadeInDuration: HexaMotion.fast,
                        errorWidget: (_, __, ___) {
                          return const Icon(
                            Icons.person_outline_rounded,
                            color: HexaColors.white,
                            size: 21,
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HexagonClipper extends CustomClipper<Path> {
  const _HexagonClipper();

  @override
  Path getClip(Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final path = Path();

    for (var index = 0; index < 6; index++) {
      final angle = -3.141592653589793 / 2 + index * 3.141592653589793 / 3;

      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    return path..close();
  }

  @override
  bool shouldReclip(covariant _HexagonClipper oldClipper) {
    return false;
  }
}

String _compactCount(int value) {
  if (value >= 1000000) {
    final digits = value >= 10000000 ? 0 : 1;

    return '${(value / 1000000).toStringAsFixed(digits)}M';
  }

  if (value >= 1000) {
    final digits = value >= 10000 ? 0 : 1;

    return '${(value / 1000).toStringAsFixed(digits)}K';
  }

  return value.toString();
}
