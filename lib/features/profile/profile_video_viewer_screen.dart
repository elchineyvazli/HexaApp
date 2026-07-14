import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../feed/feed_models.dart';
import '../feed/video_item.dart';

class ProfileVideoViewerScreen extends StatefulWidget {
  const ProfileVideoViewerScreen({
    super.key,
    required this.videos,
    required this.initialIndex,
  });

  final List<VideoModel> videos;
  final int initialIndex;

  @override
  State<ProfileVideoViewerScreen> createState() {
    return _ProfileVideoViewerScreenState();
  }
}

class _ProfileVideoViewerScreenState extends State<ProfileVideoViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    if (widget.videos.isEmpty) {
      _currentIndex = 0;
    } else if (widget.initialIndex < 0) {
      _currentIndex = 0;
    } else if (widget.initialIndex >= widget.videos.length) {
      _currentIndex = widget.videos.length - 1;
    } else {
      _currentIndex = widget.initialIndex;
    }

    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: widget.videos.isEmpty
            ? const _EmptyVideoViewer()
            : Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    allowImplicitScrolling: true,
                    itemCount: widget.videos.length,
                    onPageChanged: (index) {
                      if (_currentIndex == index) {
                        return;
                      }

                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final video = widget.videos[index];
                      final distance = (index - _currentIndex).abs();

                      return VideoItem(
                        key: ValueKey('profile-video-${video.id}'),
                        video: video,
                        isActive: index == _currentIndex,
                        shouldPreload: distance <= 1,
                      );
                    },
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Row(
                          children: [
                            Material(
                              color: const Color(0x99000000),
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: IconButton(
                                tooltip: 'Geri',
                                onPressed: () {
                                  Navigator.of(context).maybePop();
                                },
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Spacer(),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0x99000000),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0x33FFFFFF),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                child: Text(
                                  '${_currentIndex + 1}'
                                  ' / '
                                  '${widget.videos.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmptyVideoViewer extends StatelessWidget {
  const _EmptyVideoViewer();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          const Center(
            child: Text(
              'Gösterilecek video bulunamadı.',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          Positioned(
            top: 8,
            left: 12,
            child: IconButton(
              tooltip: 'Geri',
              onPressed: () {
                Navigator.of(context).maybePop();
              },
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
