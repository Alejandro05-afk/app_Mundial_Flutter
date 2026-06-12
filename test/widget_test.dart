import 'package:flutter_test/flutter_test.dart';

import 'package:mundial_2026/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const Mundial2026App());

    expect(find.text('Mundial 2026'), findsOneWidget);
  });
}
