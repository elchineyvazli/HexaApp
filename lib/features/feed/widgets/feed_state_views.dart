import 'package:flutter/material.dart';

const Color _feedBackground = Color(0xFF050507);
const Color _feedSurface = Color(0xFF111116);
const Color _feedPurple = Color(0xFF8B5CF6);

class FeedLoadingView extends StatelessWidget {
  const FeedLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _feedBackground,
      child: SafeArea(
        child: Center(
          child: Semantics(
            label: 'Videolar hazırlanıyor',
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox.square(
                  dimension: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: _feedPurple,
                    backgroundColor: const Color(0x1AFFFFFF),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Videolar hazırlanıyor',
                  style: TextStyle(
                    color: Color(0x8FFFFFFF),
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.08,
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

class FeedMessageView extends StatelessWidget {
  const FeedMessageView({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _feedBackground,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.055),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.075),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white.withValues(alpha: 0.72),
                      size: 27,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xF2FFFFFF),
                      fontSize: 20,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.42,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0x80FFFFFF),
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.12,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: onPressed,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      elevation: 0,
                      backgroundColor: _feedPurple,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white.withValues(
                        alpha: 0.08,
                      ),
                      disabledForegroundColor: Colors.white.withValues(
                        alpha: 0.42,
                      ),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        height: 1,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.12,
                      ),
                    ),
                    child: Text(buttonLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FeedLoadingMorePill extends StatelessWidget {
  const FeedLoadingMorePill({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xE6111116),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x52000000),
              blurRadius: 18,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: _feedPurple,
                  backgroundColor: Color(0x1AFFFFFF),
                  strokeCap: StrokeCap.round,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Yeni videolar yükleniyor',
                style: TextStyle(
                  color: Color(0xCFFFFFFF),
                  fontSize: 11.5,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.08,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
