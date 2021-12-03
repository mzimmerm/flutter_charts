import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../example/lib/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // WidgetsFlutterBinding.ensureInitialized();
  
  /*
  // todo-00 change this to only export
  group('unneeded test', () {
    testWidgets(
        'tap on the floating + button, and verify some text present on some widget',
    (WidgetTester tester) async {
          app.main();
          await tester.pumpAndSettle();
          expect(find.text('a'), findsOneWidget);
          
          // Find the floating actio button.
        final Finder fab = find.byTooltip('+');
        
        // Emulate a click on the floating action button.
        await tester.tap(fab);
        
        // Trigger a frame.
        await tester.pumpAndSettle();
        
        // Verify 'a' is still somewhere
        expect(find.text('a'), findsOneWidget);
        
        },);
    },);
*/
  
  group('end-to-end test', () {
    testWidgets('tap on the floating action button, verify counter',
            (WidgetTester tester) async {
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