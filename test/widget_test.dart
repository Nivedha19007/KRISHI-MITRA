import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agriconnect/app.dart';

void main() {
  testWidgets('KrishiMitra app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: KrishiMitraApp(),
      ),
    );
    expect(find.text('KRISHI MITRA'), findsWidgets);
  });
}
