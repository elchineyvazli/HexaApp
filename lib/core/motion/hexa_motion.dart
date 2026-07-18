import 'package:flutter/material.dart';

/// Hexa'nın bütün hareketlerinin tek kaynağı.
///
/// Ekranlarda rastgele Duration, Curve, scale veya giriş offset'i kullanmayın.
abstract final class HexaMotion {
  static const Duration none = Duration.zero;
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 520);
  static const Duration breathe = Duration(milliseconds: 720);
  static const Duration ambient = Duration(seconds: 20);

  static const Curve enter = Cubic(0.20, 0.82, 0.28, 1);
  static const Curve exit = Cubic(0.40, 0, 0.80, 0.20);
  static const Curve emphasized = Cubic(0.16, 1, 0.30, 1);
  static const Curve elastic = Curves.elasticOut;
  static const Curve listEnter = Curves.easeOutBack;

  static const double pressScale = 0.96;
  static const Offset pageEnterOffset = Offset(0, 0.02);

  static bool reduceMotionOf(BuildContext context) {
    return MediaQuery.maybeDisableAnimationsOf(context) == true ||
        MediaQuery.maybeAccessibleNavigationOf(context) == true;
  }

  static Duration durationOf(BuildContext context, Duration preferred) {
    return reduceMotionOf(context) ? Duration.zero : preferred;
  }

  static Duration staggerDelay(
    int index, {
    Duration step = const Duration(milliseconds: 44),
    Duration maximum = const Duration(milliseconds: 264),
  }) {
    if (index <= 0) {
      return Duration.zero;
    }

    final milliseconds = index * step.inMilliseconds;
    final limited = milliseconds.clamp(0, maximum.inMilliseconds).toInt();

    return Duration(milliseconds: limited);
  }
}

/// Hem ThemeData hem go_router geçişlerinde kullanılacak ortak hareket.
abstract final class HexaTransitions {
  static Widget page({
    required BuildContext context,
    required Animation<double> animation,
    required Widget child,
  }) {
    if (HexaMotion.reduceMotionOf(context)) {
      return child;
    }

    final curved = CurvedAnimation(
      parent: animation,
      curve: HexaMotion.enter,
      reverseCurve: HexaMotion.exit,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: HexaMotion.pageEnterOffset,
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// MaterialPageRoute tabanlı bütün platformlarda aynı Hexa geçişini uygular.
class HexaPageTransitionsBuilder extends PageTransitionsBuilder {
  const HexaPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return HexaTransitions.page(
      context: context,
      animation: animation,
      child: child,
    );
  }
}
