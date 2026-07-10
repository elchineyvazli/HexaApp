import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hexa/core/router/hexa_router.dart';
import 'package:hexa/main.dart';

void main() {
  testWidgets(
    'Hexa app shell renders with an overridden test router',
    (WidgetTester tester) async {
      final testRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              return const Scaffold(
                body: Center(
                  child: Text(
                    'HEXA_TEST_HOME',
                    key: Key('hexa-test-home'),
                  ),
                ),
              );
            },
          ),
        ],
      );

      addTearDown(testRouter.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routerProvider.overrideWithValue(testRouter),
          ],
          child: const HexaApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('hexa-test-home')), findsOneWidget);
      expect(find.text('HEXA_TEST_HOME'), findsOneWidget);
    },
  );
}