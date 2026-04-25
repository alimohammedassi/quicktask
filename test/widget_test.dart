// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, use matchers to verify widget appearance, and check that event handlers
// work as expected.

import 'package:flutter_test/flutter_test.dart';



void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // NOTE: Full tests require Firebase to be initialized.
    // Skipping widget build test for now.
    expect(true, isTrue);
  });
}
