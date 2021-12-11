import 'package:flutter_test/flutter_test.dart';

import '../example1/lib/main.dart' as app;

/// Flutter widget tests
/// 
/// Run as
/// ``` shell
///   flutter clean; flutter test test/flutter_app_widget_test.dart 
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
