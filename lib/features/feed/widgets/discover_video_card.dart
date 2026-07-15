import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

class DiscoverVideoCard extends StatelessWidget {
  const DiscoverVideoCard({required this.data, required this.rank, super.key});

  final Map<String, dynamic> data;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = data['thumbnailUrl']?.toString().trim() ?? '';

    final caption = _firstNonEmpty(<Object?>[
      data['caption'],
      data['description'],
      'Değer katan bir video',
    ]);

    final username = _formatUsername(
      _firstNonEmpty(<Object?>[
        data['username'],
        data['uploaderDisplayName'],
        'Hexa üreticisi',
      ]),
    );

    final signalCount = _readCount(data['signalCount'] ?? data['likesCount']);

    return Semantics(
      label: '$username tarafından paylaşılan video',
      child: Container(
        decoration: BoxDecoration(
          color: HexaColors.surface,
          borderRadius: BorderRadius.circular(HexaRadius.lg),
          border: Border.all(color: HexaColors.border),
          boxShadow: HexaShadows.soft,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(HexaRadius.lg - 1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _Thumbnail(thumbnailUrl: thumbnailUrl),
              const _ThumbnailOverlay(),
              Positioned(
                top: HexaSpacing.sm,
                left: HexaSpacing.sm,
                child: _RankBadge(rank: rank),
              ),
              const Positioned(
                top: HexaSpacing.sm,
                right: HexaSpacing.sm,
                child: _PlayBadge(),
              ),
              Positioned(
                left: HexaSpacing.sm,
                right: HexaSpacing.sm,
                bottom: HexaSpacing.sm,
                child: _VideoInformation(
                  caption: caption,
                  username: username,
                  signalCount: signalCount,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  static String _formatUsername(String value) {
    if (value.isEmpty || value.contains(' ')) {
      return value;
    }

    return value.startsWith('@') ? value : '@$value';
  }

  static int _readCount(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.thumbnailUrl});

  final String thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    if (thumbnailUrl.isEmpty) {
      return const _VideoPlaceholder();
    }

    return Image.network(
      thumbnailUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const _VideoPlaceholder();
      },
    );
  }
}

class _ThumbnailOverlay extends StatelessWidget {
  const _ThumbnailOverlay();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0x16000000), Color(0xD92F1713)],
          stops: [0, 0.48, 1],
        ),
      ),
    );
  }
}

class _VideoInformation extends StatelessWidget {
  const _VideoInformation({
    required this.caption,
    required this.username,
    required this.signalCount,
  });

  final String caption;
  final String username;
  final int signalCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          caption,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: HexaColors.inkOnDark,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: Text(
                username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xD9FFFFFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: HexaSpacing.xs),
            const Icon(
              Icons.favorite_rounded,
              color: HexaColors.hopePink,
              size: 15,
            ),
            const SizedBox(width: 4),
            Text(
              _formatCount(signalCount),
              style: const TextStyle(
                color: HexaColors.inkOnDark,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }

    return '$value';
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xEFFFFFFF),
        borderRadius: BorderRadius.circular(HexaRadius.pill),
        border: Border.all(color: const Color(0x66FFFFFF)),
      ),
      child: Text(
        '#$rank',
        style: const TextStyle(
          color: HexaColors.signalStrong,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        color: Color(0xE6FFFFFF),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.play_arrow_rounded,
        color: HexaColors.signalStrong,
        size: 25,
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HexaColors.surfaceWarm,
            HexaColors.signalSoft,
            HexaColors.lavenderSoft,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.play_circle_fill_rounded,
          color: HexaColors.signal,
          size: 58,
        ),
      ),
    );
  }
}
