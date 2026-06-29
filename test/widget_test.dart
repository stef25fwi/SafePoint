import 'package:flutter_test/flutter_test.dart';
import 'package:refuge_volcan/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RefugeVolcanApp());
    expect(find.byType(RefugeVolcanApp), findsOneWidget);
  });
}
