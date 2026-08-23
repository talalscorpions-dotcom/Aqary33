// Basic smoke test for the AQARY app.
//
// It verifies that the app builds and renders its welcome screen.

import 'package:flutter_test/flutter_test.dart';

import 'package:aqary/main.dart';

void main() {
  testWidgets('App renders the welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AqaryApp());

    expect(find.text('Welcome to AQARY'), findsOneWidget);
  });
}
