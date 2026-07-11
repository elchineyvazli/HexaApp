import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexa/core/router/hexa_router.dart';
import 'package:hexa/core/theme/hexa_theme.dart';
import 'package:hexa/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: HexaColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: HexaColors.border,
    ),
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    runApp(const ProviderScope(child: HexaApp()));
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(HexaStartupFailureApp(error: error));
  }
}

class HexaApp extends ConsumerWidget {
  const HexaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Hexa',
      debugShowCheckedModeBanner: false,
      theme: HexaTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}

class HexaStartupFailureApp extends StatelessWidget {
  const HexaStartupFailureApp({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hexa',
      debugShowCheckedModeBanner: false,
      theme: HexaTheme.lightTheme,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(HexaSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Container(
                  padding: const EdgeInsets.all(HexaSpacing.lg),
                  decoration: BoxDecoration(
                    color: HexaColors.surface,
                    borderRadius: BorderRadius.circular(HexaRadius.lg),
                    border: Border.all(color: HexaColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x120B141B),
                        blurRadius: 32,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: HexaColors.signalSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_off_rounded,
                          size: 34,
                          color: HexaColors.signal,
                        ),
                      ),
                      const SizedBox(height: HexaSpacing.lg),
                      Text(
                        'Hexa başlatılamadı',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: HexaSpacing.sm),
                      Text(
                        'Firebase başlangıç yapılandırması kontrol edilmeli.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: HexaColors.inkMuted,
                            ),
                      ),
                      const SizedBox(height: HexaSpacing.lg),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(HexaSpacing.md),
                        decoration: BoxDecoration(
                          color: HexaColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(HexaRadius.md),
                          border: Border.all(color: HexaColors.border),
                        ),
                        child: SelectableText(
                          error.toString(),
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            color: HexaColors.inkMuted,
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.45,
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
