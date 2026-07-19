import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hexa/core/theme/hexa_theme.dart';
import 'package:hexa/features/auth/application/auth_service.dart';
import 'package:hexa/features/auth/presentation/auth_screen.dart';
import 'package:hexa/features/auth/presentation/complete_profile_screen.dart';
import 'package:hexa/features/auth/presentation/widgets/hexagon_logo.dart';
import 'package:hexa/features/chat/chat_screen.dart';
import 'package:hexa/features/feed/upload_screen.dart';
import 'package:hexa/features/navigation/main_scaffold.dart';
import 'package:hexa/features/profile/profile_screen.dart';

abstract final class HexaRoutes {
  static const String splash = '/splash';
  static const String startupError = '/startup-error';
  static const String auth = '/auth';
  static const String completeProfile = '/complete-profile';
  static const String feed = '/feed';
  static const String upload = '/upload';
}

/// Kullanıcı dokümanını tek bir canlı akıştan takip eder.
///
/// Böylece her route değişiminde yeni bir Firestore `.get()` çağrısı
/// yapılmaz.
final profileCompletionProvider = StreamProvider.autoDispose<bool?>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;

  if (user == null) {
    return Stream<bool?>.value(null);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((document) => document.data()?['isProfileCompleted'] == true)
      .distinct();
});

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  final profileCompletionState = ref.watch(profileCompletionProvider);

  final router = GoRouter(
    initialLocation: HexaRoutes.splash,
    redirect: (context, state) {
      final path = state.uri.path;

      final user = authState.asData?.value;

      final isSignedIn = user != null;
      final isAuthLoading = authState.isLoading;

      final isProfileLoading = isSignedIn && profileCompletionState.isLoading;

      final hasStartupError =
          authState.hasError || (isSignedIn && profileCompletionState.hasError);

      if (hasStartupError) {
        return path == HexaRoutes.startupError ? null : HexaRoutes.startupError;
      }

      if (isAuthLoading || isProfileLoading) {
        return path == HexaRoutes.splash ? null : HexaRoutes.splash;
      }

      if (!isSignedIn) {
        return path == HexaRoutes.auth ? null : HexaRoutes.auth;
      }

      final isProfileCompleted = profileCompletionState.asData?.value == true;

      if (!isProfileCompleted) {
        return path == HexaRoutes.completeProfile
            ? null
            : HexaRoutes.completeProfile;
      }

      final isEntryRoute =
          path == HexaRoutes.splash ||
          path == HexaRoutes.startupError ||
          path == HexaRoutes.auth ||
          path == HexaRoutes.completeProfile;

      if (isEntryRoute) {
        return HexaRoutes.feed;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: HexaRoutes.splash,
        name: 'splash',
        builder: (context, state) {
          return const _StartupScreen();
        },
      ),
      GoRoute(
        path: HexaRoutes.startupError,
        name: 'startup-error',
        builder: (context, state) {
          return const _StartupErrorScreen();
        },
      ),
      GoRoute(
        path: HexaRoutes.auth,
        name: 'auth',
        builder: (context, state) {
          return const AuthScreen();
        },
      ),
      GoRoute(
        path: HexaRoutes.completeProfile,
        name: 'complete-profile',
        builder: (context, state) {
          return const CompleteProfileScreen();
        },
      ),
      GoRoute(
        path: HexaRoutes.feed,
        name: 'feed',
        builder: (context, state) {
          return const MainScaffold();
        },
      ),
      GoRoute(
        path: HexaRoutes.upload,
        name: 'upload',
        builder: (context, state) {
          return const UploadScreen();
        },
      ),
      GoRoute(
        path: '/profile/:userId',
        name: 'profile',
        builder: (context, state) {
          return ProfileScreen(userId: state.pathParameters['userId']);
        },
      ),
      GoRoute(
        path: '/chat/:chatId',
        name: 'chat',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId'] ?? 'unknown';

          return ChatScreen(chatId: chatId);
        },
      ),
    ],
    errorBuilder: (context, state) {
      return _RouteErrorScreen(error: state.error);
    },
  );

  ref.onDispose(router.dispose);

  return router;
});

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: HexaTheme.darkTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: HexaColors.backgroundDark,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ),
        child: Scaffold(
          backgroundColor: HexaColors.backgroundDark,
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFF0A0A0F),
                  HexaColors.backgroundDark,
                  HexaColors.backgroundDark,
                ],
                stops: <double>[0, 0.42, 1],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Semantics(
                  label: 'HEXA başlatılıyor',
                  liveRegion: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 88,
                        height: 88,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: HexaColors.surfaceDark,
                          borderRadius: BorderRadius.circular(29),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x248B5CF6),
                              blurRadius: 34,
                              spreadRadius: -8,
                            ),
                            BoxShadow(
                              color: Color(0x1406B6D4),
                              blurRadius: 42,
                              spreadRadius: -12,
                            ),
                          ],
                        ),
                        child: HexagonLogo(size: 57, showShadow: false),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        'HEXA',
                        style: TextStyle(
                          color: Color(0xF2FFFFFF),
                          fontSize: 22,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 5.2,
                        ),
                      ),
                      const SizedBox(height: 11),
                      const Text(
                        'Değerli içerik, gerçek destek',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0x66FFFFFF),
                          fontSize: 11.5,
                          height: 1.2,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.15,
                        ),
                      ),
                      const SizedBox(height: 29),
                      const SizedBox.square(
                        dimension: 25,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: HexaColors.purple,
                          backgroundColor: Color(0x1AFFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupErrorScreen extends ConsumerWidget {
  const _StartupErrorScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: HexaTheme.darkTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: HexaColors.backgroundDark,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ),
        child: Scaffold(
          backgroundColor: HexaColors.backgroundDark,
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFF0A0A0F),
                  HexaColors.backgroundDark,
                  HexaColors.backgroundDark,
                ],
                stops: <double>[0, 0.38, 1],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 36,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const _ConnectionErrorMark(),
                        const SizedBox(height: 27),
                        const Text(
                          'Bağlantı kurulamadı',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: HexaColors.inkOnDark,
                            fontSize: 23,
                            height: 1.12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.58,
                          ),
                        ),
                        const SizedBox(height: 11),
                        const Text(
                          'Oturum veya profil bilgileri alınamadı. Bağlantını kontrol edip yeniden dene.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0x80FFFFFF),
                            fontSize: 13.5,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.10,
                          ),
                        ),
                        const SizedBox(height: 25),
                        SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: () {
                              ref.invalidate(authStateProvider);

                              ref.invalidate(profileCompletionProvider);

                              context.go(HexaRoutes.splash);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: HexaColors.purple,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                              ),
                              shape: const StadiumBorder(),
                            ),
                            icon: Icon(Icons.refresh_rounded, size: 19),
                            label: const Text(
                              'Tekrar dene',
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionErrorMark extends StatelessWidget {
  const _ConnectionErrorMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Bağlantı hatası',
      child: Container(
        width: 76,
        height: 76,
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          gradient: HexaGradients.signal,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x248B5CF6),
              blurRadius: 30,
              spreadRadius: -8,
            ),
          ],
        ),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: HexaColors.surfaceDark,
            borderRadius: BorderRadius.circular(24.5),
          ),
          child: Icon(
            Icons.cloud_off_outlined,
            color: Colors.white.withOpacity(0.82),
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: HexaTheme.darkTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: HexaColors.backgroundDark,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ),
        child: Scaffold(
          backgroundColor: HexaColors.backgroundDark,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 36,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.055),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.07),
                          ),
                        ),
                        child: Icon(
                          Icons.explore_off_outlined,
                          color: Colors.white.withOpacity(0.46),
                          size: 29,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Sayfa bulunamadı',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: HexaColors.inkOnDark,
                          fontSize: 22,
                          height: 1.12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.52,
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Aradığın sayfa taşınmış veya artık kullanılamıyor olabilir.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0x70FFFFFF),
                          fontSize: 13,
                          height: 1.46,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.08,
                        ),
                      ),
                      if (kDebugMode && error != null) ...<Widget>[
                        const SizedBox(height: 20),
                        _RouteDebugMessage(message: error.toString()),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: () {
                            context.go(HexaRoutes.feed);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: HexaColors.purple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            shape: const StadiumBorder(),
                          ),
                          icon: Icon(Icons.home_rounded, size: 19),
                          label: const Text(
                            'Ana sayfaya dön',
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteDebugMessage extends StatelessWidget {
  const _RouteDebugMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 130),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: HexaColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          message,
          textAlign: TextAlign.left,
          style: const TextStyle(
            color: Color(0x70FFFFFF),
            fontFamily: 'monospace',
            fontSize: 10.5,
            height: 1.42,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
