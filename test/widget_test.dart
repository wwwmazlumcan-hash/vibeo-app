import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('placeholder smoke test', (WidgetTester tester) async {
    // Firebase bağımlılığı nedeniyle tam entegrasyon testi CI'da atlanır.
    expect(true, isTrue);
  });
}
