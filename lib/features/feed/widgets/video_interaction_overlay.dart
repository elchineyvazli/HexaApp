import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/hexa_theme.dart';
import '../feed_models.dart';
import 'like_burst_animation.dart';
import 'video_action_bar.dart';

class VideoInteractionOverlay extends StatefulWidget {
  const VideoInteractionOverlay({
    required this.video,
    required this.enabled,
    required this.dismissToken,
    required this.onTogglePlayback,
    required this.onOpenComments,
    required this.onActionBarVisibilityChanged,
    super.key,
  });

  final VideoModel video;
  final bool enabled;
  final int dismissToken;

  final Future<void> Function() onTogglePlayback;

  final Future<void> Function() onOpenComments;

  final ValueChanged<bool> onActionBarVisibilityChanged;

  @override
  State<VideoInteractionOverlay> createState() {
    return _VideoInteractionOverlayState();
  }
}

class _VideoInteractionOverlayState extends State<VideoInteractionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _elementsController;

  late final Animation<double> _elementsOpacity;

  late final Animation<Offset> _elementsOffset;

  late final Animation<double> _commentScale;

  Timer? _entryTimer;

  bool _isActionBarVisible = false;
  bool _isLiked = false;
  bool _isSaved = false;
  bool _reduceMotion = false;

  int _signalCount = 0;
  int _likeAnimationToken = 0;

  Offset _doubleTapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();

    _signalCount = widget.video.signalCount;

    _elementsController = AnimationController(
      vsync: this,
      duration: HexaMotion.slow,
    );

    _elementsOpacity = CurvedAnimation(
      parent: _elementsController,
      curve: const Interval(0, 0.72, curve: HexaMotion.enter),
      reverseCurve: HexaMotion.exit,
    );

    _elementsOffset =
        Tween<Offset>(begin: const Offset(0, 0.025), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _elementsController,
            curve: HexaMotion.enter,
            reverseCurve: HexaMotion.exit,
          ),
        );

    _commentScale = Tween<double>(begin: 0.84, end: 1).animate(
      CurvedAnimation(
        parent: _elementsController,
        curve: const Interval(0.24, 1, curve: Curves.easeOutBack),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final reduceMotion = HexaMotion.reduceMotionOf(context);

    if (_reduceMotion == reduceMotion &&
        (_entryTimer != null || _elementsController.value > 0)) {
      return;
    }

    _reduceMotion = reduceMotion;

    if (_reduceMotion) {
      _entryTimer?.cancel();
      _elementsController.value = 1;
    } else if (_elementsController.value == 0) {
      _scheduleEntry();
    }
  }

  @override
  void didUpdateWidget(covariant VideoInteractionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    final videoChanged = oldWidget.video.id != widget.video.id;

    if (videoChanged) {
      final actionBarWasVisible = _isActionBarVisible;

      _isLiked = false;
      _isSaved = false;
      _signalCount = widget.video.signalCount;
      _likeAnimationToken = 0;
      _doubleTapPosition = Offset.zero;
      _isActionBarVisible = false;

      _entryTimer?.cancel();

      if (_reduceMotion) {
        _elementsController.value = 1;
      } else {
        _elementsController.reset();
        _scheduleEntry();
      }

      if (actionBarWasVisible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onActionBarVisibilityChanged(false);
          }
        });
      }

      return;
    }

    if (!_isLiked && oldWidget.video.signalCount != widget.video.signalCount) {
      _signalCount = widget.video.signalCount;
    }

    final mustDismiss =
        !widget.enabled || oldWidget.dismissToken != widget.dismissToken;

    if (mustDismiss && _isActionBarVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isActionBarVisible) {
          _setActionBarVisible(false);
        }
      });
    }
  }

  @override
  void dispose() {
    _entryTimer?.cancel();
    _elementsController.dispose();

    super.dispose();
  }

  void _scheduleEntry() {
    _entryTimer?.cancel();

    _entryTimer = Timer(const Duration(milliseconds: 240), () {
      _entryTimer = null;

      if (!mounted || !widget.enabled || _isActionBarVisible) {
        return;
      }

      _elementsController.forward();
    });
  }

  void _setActionBarVisible(bool value) {
    if (!mounted || _isActionBarVisible == value) {
      return;
    }

    setState(() {
      _isActionBarVisible = value;
    });

    widget.onActionBarVisibilityChanged(value);

    if (_reduceMotion) {
      _elementsController.value = value ? 0 : 1;
      return;
    }

    if (value) {
      _elementsController.reverse();
    } else {
      _elementsController.forward();
    }
  }

  void _handleSingleTap() {
    if (!widget.enabled) {
      return;
    }

    if (_isActionBarVisible) {
      HapticFeedback.selectionClick();
      _setActionBarVisible(false);
      return;
    }

    unawaited(widget.onTogglePlayback());
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapPosition = details.localPosition;
  }

  void _handleDoubleTap() {
    if (!widget.enabled || _isActionBarVisible) {
      return;
    }

    setState(() {
      if (!_isLiked) {
        _isLiked = true;
        _signalCount++;
      }

      _likeAnimationToken++;
    });

    HapticFeedback.mediumImpact();
  }

  void _handleLongPress() {
    if (!widget.enabled || _isActionBarVisible) {
      return;
    }

    HapticFeedback.heavyImpact();
    _setActionBarVisible(true);
  }

  void _toggleLikeFromBar() {
    final nextLiked = !_isLiked;

    setState(() {
      _isLiked = nextLiked;

      _signalCount = (_signalCount + (nextLiked ? 1 : -1))
          .clamp(0, 1 << 31)
          .toInt();

      if (nextLiked) {
        _doubleTapPosition = Offset.zero;
        _likeAnimationToken++;
      }
    });

    HapticFeedback.selectionClick();
  }

  void _toggleSave() {
    setState(() {
      _isSaved = !_isSaved;
    });

    HapticFeedback.selectionClick();
  }

  Future<void> _shareVideo() async {
    final url = widget.video.playbackUrl.trim();

    if (url.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: url));

    if (!mounted) {
      return;
    }

    HapticFeedback.selectionClick();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Video bağlantısı kopyalandı.'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  void _openProfile() {
    final userId = widget.video.uploaderId.trim();

    if (userId.isEmpty || !widget.video.hasUploaderProfile) {
      return;
    }

    _setActionBarVisible(false);

    context.push('/profile/${Uri.encodeComponent(userId)}');
  }

  void _openComments() {
    if (!widget.enabled || _isActionBarVisible) {
      return;
    }

    HapticFeedback.selectionClick();

    unawaited(widget.onOpenComments());
  }

  String _formatCount(int count) {
    if (count >= 1000000000) {
      return '${(count / 1000000000).toStringAsFixed(1)}B';
    }

    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }

    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }

    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fallbackOrigin = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight / 2,
        );

        final rawOrigin = _doubleTapPosition == Offset.zero
            ? fallbackOrigin
            : _doubleTapPosition;

        final animationOrigin = Offset(
          constraints.maxWidth <= 144
              ? constraints.maxWidth / 2
              : rawOrigin.dx.clamp(72, constraints.maxWidth - 72).toDouble(),
          constraints.maxHeight <= 202
              ? constraints.maxHeight / 2
              : rawOrigin.dy.clamp(92, constraints.maxHeight - 110).toDouble(),
        );

        final bottomInset = MediaQuery.paddingOf(context).bottom;

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handleSingleTap,
              onDoubleTapDown: _handleDoubleTapDown,
              onDoubleTap: _handleDoubleTap,
              onLongPressStart: (_) {
                _handleLongPress();
              },
            ),

            IgnorePointer(
              child: LikeBurstAnimation(
                token: _likeAnimationToken,
                origin: animationOrigin,
                signalCount: _signalCount,
              ),
            ),

            IgnorePointer(
              child: FadeTransition(
                opacity: _elementsOpacity,
                child: SlideTransition(
                  position: _elementsOffset,
                  child: Positioned(
                    left: HexaSpacing.lg,
                    bottom: bottomInset + HexaSpacing.lg,
                    child: _ViewSignal(
                      value: _formatCount(widget.video.viewsCount),
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              right: HexaSpacing.sm,
              top: constraints.maxHeight * 0.42,
              child: IgnorePointer(
                ignoring: _isActionBarVisible || !widget.enabled,
                child: FadeTransition(
                  opacity: _elementsOpacity,
                  child: ScaleTransition(
                    scale: _commentScale,
                    child: _CommentPortal(onTap: _openComments),
                  ),
                ),
              ),
            ),

            VideoActionBar(
              isVisible: _isActionBarVisible,
              video: widget.video,
              isLiked: _isLiked,
              isSaved: _isSaved,
              signalCount: _signalCount,
              onProfilePressed: _openProfile,
              onLikePressed: _toggleLikeFromBar,
              onSharePressed: _shareVideo,
              onSavePressed: _toggleSave,
            ),
          ],
        );
      },
    );
  }
}

class _ViewSignal extends StatelessWidget {
  const _ViewSignal({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: HexaColors.white,
            fontWeight: FontWeight.w800,
            shadows: const <Shadow>[
              Shadow(color: HexaColors.earth, blurRadius: 10),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 42,
          height: 2,
          decoration: BoxDecoration(
            gradient: HexaGradients.navIndicator,
            borderRadius: HexaRadius.borderPill,
            boxShadow: const <BoxShadow>[
              BoxShadow(color: HexaColors.signalGlow, blurRadius: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentPortal extends StatefulWidget {
  const _CommentPortal({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CommentPortal> createState() {
    return _CommentPortalState();
  }
}

class _CommentPortalState extends State<_CommentPortal> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    return Semantics(
      button: true,
      label: 'Yorumları aç',
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
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? HexaMotion.pressScale : 1,
          duration: reduceMotion ? Duration.zero : HexaMotion.fast,
          curve: HexaMotion.elastic,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HexaColors.earth.withAlpha(92),
              shape: BoxShape.circle,
              border: Border.all(color: HexaColors.white.withAlpha(50)),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: Color(0x33000000), blurRadius: 14),
              ],
            ),
            child: const Icon(
              Icons.mode_comment_rounded,
              color: HexaColors.white,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}
