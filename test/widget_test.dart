import 'package:flutter_test/flutter_test.dart';

import '../example/lib/main.dart' as app;

/// Flutter widget tests for the example app in '../example/lib/main.dart'.
///
/// Tests check some expected values on the main page of the app.
///
/// Run as
/// ``` shell
///   flutter clean; flutter test test/widget_test.dart
/// ```
void main() {
  group('Widget tests on page 1', () {
    testWidgets('find expected text on widgets', (WidgetTester tester) async {
      // Build the app.
      app.main();

      await tester.pumpAndSettle();

      // Verify the counter starts at 0.
      expect(find.text('vvvvvvvv:'), findsOneWidget);

      // Finds the floating action button to tap on.
      final Finder fab = find.byTooltip('New Random Data');

      // Emulate a tap on the floating action button.
      await tester.tap(fab);

      // Trigger a frame.
      await tester.pumpAndSettle();

      // Verify the counter increments by 1.
      expect(find.text('vvvvvvvv:'), findsOneWidget);
    });
  });
}
