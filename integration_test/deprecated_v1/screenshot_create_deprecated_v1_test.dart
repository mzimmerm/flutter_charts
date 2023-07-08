import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart' show IntegrationTestWidgetsFlutterBinding;

import 'package:flutter_charts/src/chart/util/example_descriptor.dart' show ExampleDescriptor;
import 'package:flutter_charts/test/src/util/test_util.dart';
import 'package:flutter_charts/test/src/example/main.dart' as app;

/// @Deprecated, see 'integration_test/screenshot_create_test_new.dart'.
///
///   Integration testing by taking a screenshot from the example app,
///   and comparing the produced screenshot with a known correct screenshot.
///
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot', (WidgetTester tester) async {
    var screenshotPaths = ScreenshotPaths(exampleDescriptor: ExampleDescriptor.requestedExampleToRun());
    String screenshotPath = screenshotPaths.actualScreenshotPath;

    // Build the app and run it on device.
    app.main();

    // This is required prior to taking the screenshot (Android only).
    await binding.convertFlutterSurfaceToImage();

    // Trigger a frame.
    await tester.pumpAndSettle();

    // Take screenshot.
    await binding.takeScreenshot(screenshotPath);

  });
}
