import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexa/main.dart';

void main() {
  testWidgets('Hexa App Smoke Test', (WidgetTester tester) async {
    // Uygulamayı Riverpod ProviderScope ile test ortamında başlatıyoruz
    await tester.pumpWidget(const ProviderScope(child: HexaApp()));

    // Ekranda HEXA ve buton metinlerinin doğru yüklendiğini kodla doğruluyoruz
    expect(find.text('HEXA'), findsOneWidget);
    expect(find.text('GOOGLE İLE BAŞLA'), findsOneWidget);
  });
}
