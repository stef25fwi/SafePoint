import 'package:flutter_test/flutter_test.dart';
import 'package:safepoint_app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SafePointApp());
    expect(find.byType(SafePointApp), findsOneWidget);
  });
}
