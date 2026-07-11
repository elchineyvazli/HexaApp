import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hexa/core/theme/hexa_theme.dart';
import 'package:hexa/features/auth/application/auth_service.dart';
import 'package:hexa/features/auth/presentation/auth_screen.dart';
import 'package:hexa/features/auth/presentation/complete_profile_screen.dart';
import 'package:hexa/features/auth/presentation/widgets/auth_background.dart';
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
/// Böylece her route değişiminde yeni bir Firestore `.get()` çağrısı yapılmaz.
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
    routes: [
      GoRoute(
        path: HexaRoutes.splash,
        name: 'splash',
        builder: (context, state) => const _StartupScreen(),
      ),
      GoRoute(
        path: HexaRoutes.startupError,
        name: 'startup-error',
        builder: (context, state) => const _StartupErrorScreen(),
      ),
      GoRoute(
        path: HexaRoutes.auth,
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: HexaRoutes.completeProfile,
        name: 'complete-profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: HexaRoutes.feed,
        name: 'feed',
        builder: (context, state) => const MainScaffold(),
      ),
      GoRoute(
        path: HexaRoutes.upload,
        name: 'upload',
        builder: (context, state) => const UploadScreen(),
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
    errorBuilder: (context, state) => _RouteErrorScreen(error: state.error),
  );

  ref.onDispose(router.dispose);
  return router;
});

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AuthBackground(),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutBack,
                    tween: Tween(begin: 0.82, end: 1),
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: const HexagonLogo(size: 88),
                  ),
                  const SizedBox(height: HexaSpacing.md),
                  Text(
                    'HEXA',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'DEĞERLİ İÇERİK, GERÇEK DESTEK',
                    style: TextStyle(
                      color: HexaColors.inkMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: HexaSpacing.lg),
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartupErrorScreen extends ConsumerWidget {
  const _StartupErrorScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          const AuthBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(HexaSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.all(HexaSpacing.lg),
                    decoration: BoxDecoration(
                      color: const Color(0xF7FFFFFF),
                      borderRadius: BorderRadius.circular(HexaRadius.lg),
                      border: Border.all(color: HexaColors.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HexagonLogo(size: 72),
                        const SizedBox(height: HexaSpacing.lg),
                        Text(
                          'Bağlantıyı tamamlayamadık',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: HexaSpacing.sm),
                        Text(
                          'Oturum veya profil bilgisi alınamadı. İnternet bağlantını kontrol edip yeniden dene.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: HexaColors.inkMuted),
                        ),
                        const SizedBox(height: HexaSpacing.lg),
                        FilledButton.icon(
                          onPressed: () {
                            ref.invalidate(authStateProvider);
                            ref.invalidate(profileCompletionProvider);
                            context.go(HexaRoutes.splash);
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tekrar dene'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sayfa bulunamadı')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(HexaSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.explore_off_rounded,
                  size: 64,
                  color: HexaColors.signal,
                ),
                const SizedBox(height: HexaSpacing.md),
                Text(
                  'Aradığın sayfaya ulaşamadık.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (error != null) ...[
                  const SizedBox(height: HexaSpacing.sm),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: HexaSpacing.lg),
                FilledButton.icon(
                  onPressed: () => context.go(HexaRoutes.feed),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Ana sayfaya dön'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
