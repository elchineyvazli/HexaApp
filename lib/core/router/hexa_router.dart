// lib/core/router/hexa_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/application/auth_service.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/complete_profile_screen.dart'; // YENİ EKLENDİ
import '../../features/feed/feed_screen.dart';
import '../../features/feed/upload_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/navigation/main_scaffold.dart';
import '../../features/chat/chat_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Auth durumunu izliyoruz ki giriş/çıkış yapıldığı anda router tetiklensin!
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/feed',
    redirect: (context, state) async {
      final user = FirebaseAuth.instance.currentUser;
      final isCompleteRoute = state.uri.toString() == '/complete-profile';
      final isAuthRoute = state.uri.toString() == '/auth';

      if (user != null) {
        try {
          // Kullanıcının Firestore'daki kalkan durumunu kontrol et
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          final isCompleted = userDoc.data()?['isProfileCompleted'] as bool? ?? false;

          // 1. Profil tamamlanmadıysa ve şu an tamamlama ekranında değilse -> ZORLA HAPSET!
          if (!isCompleted && !isCompleteRoute) {
            return '/complete-profile';
          }
          // 2. Profil tamamlandıysa ve hala tamamlama ya da login ekranındaysa -> AKIŞA AT!
          if (isCompleted && (isCompleteRoute || isAuthRoute)) {
            return '/feed';
          }
        } catch (e) {
          // Ağ hatası vb. durumlarda akışı bozma
        }
      }
      return null;
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
          final chatId = state.pathParameters['chatId'] ?? 'Unknown';
          return ChatScreen(chatId: chatId);
        },
      ),
    ],
  );
});