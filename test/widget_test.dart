import 'package:flutter_test/flutter_test.dart';
import 'package:vibeo/main.dart'; // Paket ismini 'vibeo' olarak güncelledik

// ENGLISH: This test ensures that the Vibeo application starts correctly.
// TÜRKÇE: Bu test, Vibeo uygulamasının doğru şekilde başladığından emin olur.

void main() {
  testWidgets('Vibeo login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VibeoApp());

    // Verify that VIBEO text exists.
    // Ekranda VIBEO yazısının olduğunu doğrula.
    expect(find.text('VIBEO'), findsOneWidget);

    // Verify that the login button exists.
    // Giriş butonunun varlığını doğrula.
    expect(find.text("LET'S VIBE"), findsOneWidget);
  });
}
