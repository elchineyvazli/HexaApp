import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

import 'profile_page_chrome.dart';

class ProfileVideoTile extends StatelessWidget {
  const ProfileVideoTile({
    required this.thumbnailUrl,
    required this.viewsCount,
    required this.onTap,
    super.key,
  });

  final String thumbnailUrl;
  final int viewsCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${_compactNumber(viewsCount)} görüntülenmeli video',
      child: Material(
        color: HexaColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HexaRadius.sm),
          side: const BorderSide(color: profileOrangeBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HexaRadius.sm),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildThumbnail(),
              const _BottomGradient(),
              Positioned(
                left: 7,
                bottom: 7,
                child: _ViewBadge(value: _compactNumber(viewsCount)),
              ),
              const Positioned(top: 7, right: 7, child: _PlayBadge()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final url = thumbnailUrl.trim();

    if (url.isEmpty) {
      return const _ThumbnailPlaceholder();
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }

        return const _ThumbnailLoading();
      },
      errorBuilder: (context, error, stackTrace) {
        return const _ThumbnailPlaceholder();
      },
    );
  }

  String _compactNumber(int value) {
    final safeValue = value < 0 ? 0 : value;

    if (safeValue >= 1000000000) {
      return '${_trimDecimal(safeValue / 1000000000)}B';
    }

    if (safeValue >= 1000000) {
      return '${_trimDecimal(safeValue / 1000000)}M';
    }

    if (safeValue >= 1000) {
      return '${_trimDecimal(safeValue / 1000)}K';
    }

    return safeValue.toString();
  }

  String _trimDecimal(double value) {
    final text = value.toStringAsFixed(value >= 100 ? 0 : 1);

    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }
}

class _ViewBadge extends StatelessWidget {
  const _ViewBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xE6EA580C),
        borderRadius: BorderRadius.circular(HexaRadius.pill),
        border: Border.all(color: const Color(0x66FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility_rounded, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        shape: BoxShape.circle,
        border: Border.all(color: profileOrangeBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22EA580C),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.play_arrow_rounded,
        color: profileOrangeStrong,
        size: 21,
      ),
    );
  }
}

class _BottomGradient extends StatelessWidget {
  const _BottomGradient();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.43, 1],
            colors: [Colors.transparent, Color(0xB85A260A)],
          ),
        ),
      ),
    );
  }
}

class _ThumbnailLoading extends StatelessWidget {
  const _ThumbnailLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: profileOrangeSoft,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: profileOrangeStrong,
            strokeWidth: 2.2,
          ),
        ),
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFEDD5),
            Color(0xFFFDBA74),
            Color(0xFFF97316),
            Color(0xFFEA580C),
          ],
          stops: [0, 0.34, 0.7, 1],
        ),
      ),
      child: Center(child: _PlaceholderPlayIcon()),
    );
  }
}

class _PlaceholderPlayIcon extends StatelessWidget {
  const _PlaceholderPlayIcon();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xEFFFFFFF),
        shape: BoxShape.circle,
        border: Border.fromBorderSide(BorderSide(color: Color(0x99FFFFFF))),
        boxShadow: [
          BoxShadow(
            color: Color(0x33A33B08),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: SizedBox(
        width: 60,
        height: 60,
        child: Icon(
          Icons.play_arrow_rounded,
          color: profileOrangeStrong,
          size: 38,
        ),
      ),
    );
  }
}
