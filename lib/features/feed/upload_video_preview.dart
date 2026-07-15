import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';
import 'package:video_player/video_player.dart';

class UploadVideoPreview extends StatefulWidget {
  const UploadVideoPreview({
    required this.videoFile,
    required this.onPickVideo,
    super.key,
  });

  final File? videoFile;
  final VoidCallback onPickVideo;

  @override
  State<UploadVideoPreview> createState() => _UploadVideoPreviewState();
}

class _UploadVideoPreviewState extends State<UploadVideoPreview> {
  VideoPlayerController? _controller;
  bool _hasInitializationError = false;
  int _controllerGeneration = 0;

  @override
  void initState() {
    super.initState();
    _replaceController(widget.videoFile);
  }

  @override
  void didUpdateWidget(covariant UploadVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.videoFile?.path != widget.videoFile?.path) {
      _replaceController(widget.videoFile);
    }
  }

  Future<void> _replaceController(File? file) async {
    final generation = ++_controllerGeneration;
    final previousController = _controller;

    _controller = null;
    _hasInitializationError = false;

    await previousController?.dispose();

    if (file == null) {
      if (mounted) {
        setState(() {});
      }
      return;
    }

    final controller = VideoPlayerController.file(file);
    _controller = controller;

    try {
      await controller.initialize();

      if (!mounted || generation != _controllerGeneration) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(true);
      await controller.play();

      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (!mounted || generation != _controllerGeneration) {
        return;
      }

      _hasInitializationError = true;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controllerGeneration++;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(HexaRadius.lg),
      child: InkWell(
        onTap: widget.onPickVideo,
        borderRadius: BorderRadius.circular(HexaRadius.lg),
        child: Container(
          height: 260,
          decoration: BoxDecoration(
            color: HexaColors.surface,
            borderRadius: BorderRadius.circular(HexaRadius.lg),
            border: Border.all(color: HexaColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(HexaRadius.lg - 1),
            child: widget.videoFile == null
                ? const _EmptyVideoPreview()
                : _SelectedVideoPreview(
                    controller: _controller,
                    hasError: _hasInitializationError,
                  ),
          ),
        ),
      ),
    );
  }
}

class _EmptyVideoPreview extends StatelessWidget {
  const _EmptyVideoPreview();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HexaColors.surface,
            HexaColors.surfaceWarm,
            HexaColors.lavenderSoft,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(HexaSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: HexaColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: HexaColors.border),
                  boxShadow: HexaShadows.soft,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.video_library_rounded,
                  color: HexaColors.signalStrong,
                  size: 34,
                ),
              ),
              const SizedBox(height: HexaSpacing.md),
              Text(
                'Galeriden video seç',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: HexaSpacing.xs),
              Text(
                'MP4, MOV, M4V veya WebM dosyası seçebilirsin.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: HexaColors.inkMuted),
              ),
              const SizedBox(height: HexaSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: HexaColors.signalSoft,
                  borderRadius: BorderRadius.circular(HexaRadius.pill),
                ),
                child: const Text(
                  'VİDEO SEÇ',
                  style: TextStyle(
                    color: HexaColors.signalStrong,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
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

class _SelectedVideoPreview extends StatelessWidget {
  const _SelectedVideoPreview({
    required this.controller,
    required this.hasError,
  });

  final VideoPlayerController? controller;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final isInitialized = controller?.value.isInitialized == true;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (isInitialized)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller!.value.size.width,
              height: controller!.value.size.height,
              child: VideoPlayer(controller!),
            ),
          )
        else if (hasError)
          const _PreviewError()
        else
          const ColoredBox(
            color: HexaColors.surfaceMuted,
            child: Center(child: CircularProgressIndicator()),
          ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x22000000),
                  Color(0x00000000),
                  Color(0x66000000),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: HexaSpacing.sm,
          right: HexaSpacing.sm,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xEFFFFFFF),
              borderRadius: BorderRadius.circular(HexaRadius.pill),
              border: Border.all(color: const Color(0x55FFFFFF)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_rounded,
                  color: HexaColors.signalStrong,
                  size: 16,
                ),
                SizedBox(width: 5),
                Text(
                  'Değiştir',
                  style: TextStyle(
                    color: HexaColors.signalStrong,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: HexaColors.surfaceMuted,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(HexaSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.video_file_outlined,
                color: HexaColors.error,
                size: 42,
              ),
              const SizedBox(height: HexaSpacing.sm),
              Text(
                'Video önizlemesi açılamadı',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: HexaSpacing.xs),
              Text(
                'Dokunarak başka bir video seçebilirsin.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
