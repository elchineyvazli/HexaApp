import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hexa/core/router/hexa_router.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ZIRH YOK! Eğer Firebase bağlantısında (json veya gradle) bir hata varsa
  // uygulama butona basmayı beklemeden daha açılırken çökecek ve bize hatayı söyleyecek!
  await Firebase.initializeApp();

  runApp(const ProviderScope(child: HexaApp()));
}

class HexaApp extends ConsumerWidget {
  const HexaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Hexa',
      debugShowCheckedModeBanner: false,
      theme: HexaTheme.darkTheme,
      routerConfig: router,
    );
  }
}
