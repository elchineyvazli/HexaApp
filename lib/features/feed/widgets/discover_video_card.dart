import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

class DiscoverVideoCard extends StatelessWidget {
  const DiscoverVideoCard({required this.data, required this.rank, super.key});

  final Map<String, dynamic> data;

  /// Mevcut DiscoverScreen çağrılarını bozmamak için korunur.
  /// Görsel olarak sıralama rozeti gösterilmez.
  final int rank;

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = _readString(data['thumbnailUrl']);

    final username = _formatUsername(
      _firstNonEmpty(<Object?>[
        data['username'],
        data['uploaderDisplayName'],
        'Hexa üreticisi',
      ]),
    );

    final viewCount = _readFirstCount(<Object?>[
      data['viewsCount'],
      data['viewCount'],
      data['playsCount'],
      data['likesCount'],
      data['signalCount'],
    ]);

    final formattedCount = _formatCount(viewCount);

    return Semantics(
      image: true,
      label:
          'Keşfet sıralamasında $rank. video. '
          '$username tarafından paylaşıldı. '
          '$formattedCount izlenme.',
      child: ColoredBox(
        color: HexaColors.surfaceDark,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _Thumbnail(thumbnailUrl: thumbnailUrl),
            const _BottomReadabilityGradient(),
            Positioned(
              left: 8,
              bottom: 7,
              child: _VideoMetric(value: formattedCount),
            ),
          ],
        ),
      ),
    );
  }

  static String _readString(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static String _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = _readString(value);

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

  static int _readFirstCount(List<Object?> values) {
    for (final value in values) {
      if (value is int) {
        return value.clamp(0, 1 << 31);
      }

      if (value is num) {
        return value.toInt().clamp(0, 1 << 31);
      }

      if (value is List) {
        return value.length;
      }

      if (value is Map) {
        return value.length;
      }

      final parsed = int.tryParse(value?.toString() ?? '');

      if (parsed != null) {
        return parsed.clamp(0, 1 << 31);
      }
    }

    return 0;
  }

  static String _formatCount(int value) {
    if (value >= 1000000000) {
      return _compactValue(value / 1000000000, 'B');
    }

    if (value >= 1000000) {
      return _compactValue(value / 1000000, 'M');
    }

    if (value >= 1000) {
      return _compactValue(value / 1000, 'K');
    }

    return value.toString();
  }

  static String _compactValue(double value, String suffix) {
    final formatted = value.toStringAsFixed(1);

    final cleaned = formatted.endsWith('.0')
        ? formatted.substring(0, formatted.length - 2)
        : formatted;

    return '$cleaned$suffix';
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
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return const _VideoPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        return const _VideoPlaceholder(hasError: true);
      },
    );
  }
}

class _BottomReadabilityGradient extends StatelessWidget {
  const _BottomReadabilityGradient();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 74,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0x00050507),
                Color(0x24050507),
                Color(0xB8050507),
              ],
              stops: <double>[0, 0.48, 1],
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoMetric extends StatelessWidget {
  const _VideoMetric({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          Icons.play_arrow_rounded,
          color: Colors.white.withOpacity(0.92),
          size: 15,
          shadows: const <Shadow>[
            Shadow(
              color: Color(0xCC000000),
              blurRadius: 7,
              offset: Offset(0, 1),
            ),
          ],
        ),
        const SizedBox(width: 2),
        Text(
          value,
          maxLines: 1,
          style: const TextStyle(
            color: Color(0xEFFFFFFF),
            fontSize: 11,
            height: 1,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.08,
            shadows: <Shadow>[
              Shadow(
                color: Color(0xCC000000),
                blurRadius: 8,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({this.hasError = false});

  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: HexaColors.surfaceDark,
      child: Center(
        child: Icon(
          hasError ? Icons.videocam_off_outlined : Icons.play_arrow_rounded,
          color: Colors.white.withOpacity(hasError ? 0.22 : 0.12),
          size: hasError ? 25 : 27,
        ),
      ),
    );
  }
}
