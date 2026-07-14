import 'package:flutter/material.dart';

class ProfileVideoTile extends StatelessWidget {
  const ProfileVideoTile({
    super.key,
    required this.thumbnailUrl,
    required this.viewsCount,
    required this.onTap,
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
        color: const Color(0xFF1E293B),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildThumbnail(),
              const _BottomGradient(),
              Positioned(
                left: 7,
                bottom: 7,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.visibility_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _compactNumber(viewsCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 5)],
                      ),
                    ),
                  ],
                ),
              ),
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
      errorBuilder: (_, __, ___) {
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
            stops: [0.55, 1],
            colors: [Colors.transparent, Color(0xB8000000)],
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
      color: Color(0xFF1E293B),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFFB9BBD),
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
            Color(0xFFFB9BBD),
            Color(0xFFC575B1),
            Color(0xFF833C69),
            Color(0xFF601F24),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.play_arrow_rounded,
          color: Color(0xD9FFFFFF),
          size: 38,
        ),
      ),
    );
  }
}
