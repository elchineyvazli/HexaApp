import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/hexa_app.dart';
import 'core/theme/hexa_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _installGlobalErrorHandlers();

  await _configureSystemUi();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    runApp(const ProviderScope(child: HexaApp()));
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);

    runApp(HexaStartupFailureApp(error: error, stackTrace: stackTrace));
  }
}

Future<void> _configureSystemUi() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: HexaColors.transparent,
      systemNavigationBarColor: HexaColors.transparent,
      systemNavigationBarDividerColor: HexaColors.transparent,
    ),
  );
}

void _installGlobalErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);

    if (kDebugMode) {
      debugPrintStack(
        label: details.exceptionAsString(),
        stackTrace: details.stack,
      );
    }
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    debugPrint('Unhandled application error: $error');
    debugPrintStack(stackTrace: stackTrace);

    return true;
  };
}
