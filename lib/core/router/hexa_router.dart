import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hexa/features/auth/application/auth_service.dart';
import 'package:hexa/features/auth/presentation/auth_screen.dart';
import 'package:hexa/features/auth/presentation/complete_profile_screen.dart';
import 'package:hexa/features/chat/chat_screen.dart';
import 'package:hexa/features/feed/upload_screen.dart';
import 'package:hexa/features/navigation/main_scaffold.dart';
import 'package:hexa/features/profile/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  final router = GoRouter(
    initialLocation: '/auth',
    redirect: (context, state) async {
      final currentPath = state.uri.path;
      final isAuthRoute = currentPath == '/auth';
      final isCompleteProfileRoute = currentPath == '/complete-profile';

      if (authState.isLoading) {
        return null;
      }

      final user = authState.asData?.value;

      if (user == null) {
        return isAuthRoute ? null : '/auth';
      }

      try {
        final userDocument = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final isProfileCompleted =
            userDocument.data()?['isProfileCompleted'] == true;

        if (!isProfileCompleted && !isCompleteProfileRoute) {
          return '/complete-profile';
        }

        if (isProfileCompleted && (isAuthRoute || isCompleteProfileRoute)) {
          return '/feed';
        }

        return null;
      } on FirebaseException {
        // Geliştirme sırasında geçici bir Firebase/bağlantı sorunu
        // giriş yapmış kullanıcıyı tamamen bloke etmesin.
        if (isAuthRoute || isCompleteProfileRoute) {
          return '/feed';
        }

        return null;
      }
    },
    routes: [
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/complete-profile',
        name: 'complete-profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: '/feed',
        name: 'feed',
        builder: (context, state) => const MainScaffold(),
      ),
      GoRoute(
        path: '/upload',
        name: 'upload',
        builder: (context, state) => const UploadScreen(),
      ),
      GoRoute(
        path: '/profile/:userId',
        name: 'profile',
        builder: (context, state) {
          final userId = state.pathParameters['userId'];

          return ProfileScreen(userId: userId);
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
  );

  ref.onDispose(router.dispose);

  return router;
});
