import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hexa/core/theme/hexa_theme.dart';
import 'package:hexa/features/auth/application/auth_service.dart';
import 'package:hexa/features/auth/presentation/auth_screen.dart';
import 'package:hexa/features/auth/presentation/complete_profile_screen.dart';
import 'package:hexa/features/chat/chat_screen.dart';
import 'package:hexa/features/feed/upload_screen.dart';
import 'package:hexa/features/navigation/main_scaffold.dart';
import 'package:hexa/features/profile/profile_screen.dart';

abstract final class HexaRoutes {
  static const String splash = '/splash';
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

      if (isAuthLoading || isProfileLoading) {
        return path == HexaRoutes.splash ? null : HexaRoutes.splash;
      }

      if (!isSignedIn) {
        return path == HexaRoutes.auth ? null : HexaRoutes.auth;
      }

      // Ağ/izin hatası mevcut oturumu kilitlemesin. Hata halinde kullanıcı
      // feed'e alınır; hata ayrıca ekranların kendi veri katmanında gösterilir.
      final isProfileCompleted = profileCompletionState.asData?.value ?? true;

      if (!isProfileCompleted) {
        return path == HexaRoutes.completeProfile
            ? null
            : HexaRoutes.completeProfile;
      }

      final isEntryRoute =
          path == HexaRoutes.splash ||
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
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HexaMark(),
            SizedBox(height: HexaSpacing.lg),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _HexaMark extends StatelessWidget {
  const _HexaMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: HexaColors.signal,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: Colors.white,
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Hexa',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
      ],
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
