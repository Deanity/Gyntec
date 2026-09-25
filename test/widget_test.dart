import 'package:flutter_test/flutter_test.dart';
import 'package:gyntec/main.dart';

void main() {
  testWidgets('App smoke test loads MyApp', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
  });
}
