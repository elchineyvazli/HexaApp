import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../feed/feed_models.dart';
import '../feed/video_item.dart';

class ProfileVideoViewerScreen extends StatefulWidget {
  const ProfileVideoViewerScreen({
    required this.videos,
    required this.initialIndex,
    super.key,
  });

  final List<VideoModel> videos;
  final int initialIndex;

  @override
  State<ProfileVideoViewerScreen> createState() {
    return _ProfileVideoViewerScreenState();
  }
}

class _ProfileVideoViewerScreenState extends State<ProfileVideoViewerScreen> {
  static const Color _backgroundColor = Color(0xFF050507);

  late final PageController _pageController;
  late int _currentIndex;

  int _dismissInteractionToken = 0;

  bool _interactionOpen = false;

  @override
  void initState() {
    super.initState();

    _currentIndex = _resolveInitialIndex();

    _pageController = PageController(initialPage: _currentIndex);
  }

  int _resolveInitialIndex() {
    if (widget.videos.isEmpty) {
      return 0;
    }

    if (widget.initialIndex < 0) {
      return 0;
    }

    if (widget.initialIndex >= widget.videos.length) {
      return widget.videos.length - 1;
    }

    return widget.initialIndex;
  }

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  void _setInteractionOpen(bool value) {
    if (!mounted || _interactionOpen == value) {
      return;
    }

    setState(() {
      _interactionOpen = value;
    });
  }

  void _dismissInteraction() {
    if (!mounted || !_interactionOpen) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _interactionOpen = false;
      _dismissInteractionToken++;
    });
  }

  void _handlePageChanged(int index) {
    if (_currentIndex == index) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _currentIndex = index;
      _interactionOpen = false;
      _dismissInteractionToken++;
    });

    HapticFeedback.selectionClick();
  }

  void _handleBackPressed() {
    if (_interactionOpen) {
      _dismissInteraction();
      return;
    }

    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _backgroundColor,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: PopScope<Object?>(
        canPop: !_interactionOpen,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _dismissInteraction();
          }
        },
        child: Scaffold(
          backgroundColor: _backgroundColor,
          body: widget.videos.isEmpty
              ? _EmptyVideoViewer(onBackPressed: _handleBackPressed)
              : _buildVideoViewer(),
        ),
      ),
    );
  }

  Widget _buildVideoViewer() {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          physics: _interactionOpen
              ? const NeverScrollableScrollPhysics()
              : const PageScrollPhysics(parent: ClampingScrollPhysics()),
          pageSnapping: true,
          allowImplicitScrolling: true,
          itemCount: widget.videos.length,
          onPageChanged: _handlePageChanged,
          itemBuilder: (context, index) {
            final video = widget.videos[index];
            final distance = (index - _currentIndex).abs();

            return RepaintBoundary(
              key: ValueKey<String>('profile-video-${video.id}'),
              child: VideoItem(
                video: video,
                isActive: index == _currentIndex,
                shouldPreload: distance <= 1,
                dismissInteractionToken: _dismissInteractionToken,
                onInteractionStateChanged: _setInteractionOpen,
              ),
            );
          },
        ),
        const _ViewerTopScrim(),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            opacity: _interactionOpen ? 0 : 1,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: IgnorePointer(
              ignoring: _interactionOpen,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
                  child: Row(
                    children: <Widget>[
                      _ViewerBackButton(onPressed: _handleBackPressed),
                      const Spacer(),
                      _ViewerPositionLabel(
                        current: _currentIndex + 1,
                        total: widget.videos.length,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ViewerTopScrim extends StatelessWidget {
  const _ViewerTopScrim();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 124,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0x99050507),
                Color(0x4D050507),
                Color(0x00050507),
              ],
              stops: <double>[0, 0.48, 1],
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewerBackButton extends StatefulWidget {
  const _ViewerBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_ViewerBackButton> createState() {
    return _ViewerBackButtonState();
  }
}

class _ViewerBackButtonState extends State<_ViewerBackButton> {
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
    return Semantics(
      button: true,
      label: 'Geri',
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
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x66050507),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white.withValues(alpha: 0.94),
              size: 23,
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewerPositionLabel extends StatelessWidget {
  const _ViewerPositionLabel({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$total videodan $current. video',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          '$current / $total',
          style: const TextStyle(
            color: Color(0xCFFFFFFF),
            fontSize: 12,
            height: 1,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
            shadows: <Shadow>[
              Shadow(
                color: Color(0xCC000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyVideoViewer extends StatelessWidget {
  const _EmptyVideoViewer({required this.onBackPressed});

  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.videocam_off_outlined,
                    color: Colors.white.withValues(alpha: 0.32),
                    size: 32,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Gösterilecek video bulunamadı.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0x8FFFFFFF),
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 12,
            child: _ViewerBackButton(onPressed: onBackPressed),
          ),
        ],
      ),
    );
  }
}
