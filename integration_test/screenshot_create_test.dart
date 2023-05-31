/// Flutter integration (drive) tests creating a screenshot from running app.
///
/// This program, the `screenshot_create_test.dart` in the `--target` parameter, is executed using
/// the shell command run on computer:
///
///  ```sh
///  "flutter drive" \
///     " --driver=test_driver/integration_test.dart --target=integration_test/screenshot_create_test.dart"
///  ```
/// The `flutter drive` installs the `screenshot_create_test.dart` on the device, and runs it on the device.
///
/// The on-device `--target` program `screenshot_create_test.dart`,  is controller during its execution
/// by the program in the `--driver` parameter, which runs on the computer.
///
/// In the configuration of screenshot testing:
///
///   - The on-device execution of this `--target` program `screenshot_create_test.dart` contains a line that triggers
///     a screenshot-take on the device, in this code:
///     ```dart
///       await binding.takeScreenshot(screenshotPath);
///     ```
///   - The on-computer control, executes the `--driver` program `integration_test.dart` which contains code that captures
///     the bytes from the screenshot event, and stores the bytes in on-computer image:
///     ```dart
///       Future<void> main() async {
///         await integrationDriver(
///           onScreenshot: (String screenshotName, List<int> screenshotBytes) async {
///             final File image = File(screenshotName);
///             // Write the image as bytes; flush ensures close before dart exit.
///             image.writeAsBytesSync(screenshotBytes, mode: FileMode.write, flush: true);
///             if (image.existsSync()) {
///               return true;
///             }
///             // Return false if the screenshot is invalid.
///             return false;
///           },
///         );
///       }
///     ```
///
/// Running these tests should be followed by tests which compare expected/actual screenshots.
/// Those screenshot-comparing tests are in [screenshot comparing test file](test/screenshot_validate_test.dart).

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart' show IntegrationTestWidgetsFlutterBinding;

import 'package:flutter_charts/src/chart/util/example_descriptor.dart' show ExampleDescriptor;
import '../test/test_util.dart';
import '../example/lib/main.dart' as app;

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

    // When [binding.takeScreenshot] is called, the [binding] INVOKES the method callback
    // defined for [onScreenshot:] in [test_driver/integration_test.dart] and passes the callback
    // the stream of bytes from the screenshot. The callback is executed, and saves the screenshot
    // bytes to a file specified there - the test_driver framework somehow causes the image saved on
    // the computer where this test runs (not on the device)
    await binding.takeScreenshot(screenshotPath);

  });
}
