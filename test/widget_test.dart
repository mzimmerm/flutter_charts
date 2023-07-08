import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_charts/test/src/example/main.dart' as app;
import 'package:flutter_charts/src/chart/util/example_descriptor.dart' show ExampleMainAndTestSupport;

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
      final Finder floatingButton = find.byTooltip(ExampleMainAndTestSupport.floatingButtonTooltipMoveToNextExample);

      // Emulate a tap on the floating action button.
      await tester.tap(floatingButton);

      // Trigger a frame.
      await tester.pumpAndSettle();

      // Verify the counter increments by 1.
      expect(find.text('vvvvvvvv:'), findsOneWidget);
    });
  });
}
