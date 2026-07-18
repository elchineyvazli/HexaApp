import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/semantics.dart';

import '../../../core/theme/hexa_theme.dart';

class VideoPlayerControls extends StatelessWidget {
  const VideoPlayerControls({
    required this.controller,
    required this.isMuted,
    required this.onToggleMute,
    required this.onSeekForward,
    required this.onSeekBackward,
    super.key,
  });

  final VideoPlayerController controller;
  final bool isMuted;
  final VoidCallback onToggleMute;

  /// Görsel ileri/geri düğmeleri kaldırıldı.
  ///
  /// Bu callback'ler erişilebilirlik eylemleri ve ileride açılacak detay
  /// paneli için korunmaktadır.
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = HexaMotion.reduceMotionOf(context);
    final isInitialized = controller.value.isInitialized;

    return Positioned(
      left: HexaSpacing.sm,
      right: HexaSpacing.sm,
      bottom: 0,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        minimum: const EdgeInsets.only(bottom: HexaSpacing.xs),
        child: AnimatedOpacity(
          opacity: isInitialized ? 1 : 0,
          duration: reduceMotion ? Duration.zero : HexaMotion.fast,
          curve: HexaMotion.enter,
          child: Semantics(
            container: true,
            label: 'Video oynatma kontrolleri',
            customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
              const CustomSemanticsAction(label: '10 saniye geri'):
                  onSeekBackward,
              const CustomSemanticsAction(label: '10 saniye ileri'):
                  onSeekForward,
            },
            child: Row(
              children: <Widget>[
                _MuteControl(isMuted: isMuted, onTap: onToggleMute),
                const SizedBox(width: HexaSpacing.sm),
                Expanded(
                  child: SizedBox(
                    height: 22,
                    child: VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      colors: const VideoProgressColors(
                        playedColor: HexaColors.hopePink,
                        bufferedColor: Color(0x5CFFFFFF),
                        backgroundColor: Color(0x29FFFFFF),
                      ),
                    ),
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

class _MuteControl extends StatefulWidget {
  const _MuteControl({required this.isMuted, required this.onTap});

  final bool isMuted;
  final VoidCallback onTap;

  @override
  State<_MuteControl> createState() {
    return _MuteControlState();
  }
}

class _MuteControlState extends State<_MuteControl> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    return Semantics(
      button: true,
      label: widget.isMuted ? 'Video sesini aç' : 'Video sesini kapat',
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
          child: AnimatedContainer(
            duration: reduceMotion ? Duration.zero : HexaMotion.normal,
            curve: HexaMotion.emphasized,
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HexaColors.earth.withAlpha(142),
              shape: BoxShape.circle,
              border: Border.all(color: HexaColors.white.withAlpha(42)),
            ),
            child: AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : HexaMotion.fast,
              child: Icon(
                widget.isMuted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                key: ValueKey<bool>(widget.isMuted),
                color: HexaColors.white,
                size: 17,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
