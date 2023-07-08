import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart' show IntegrationTestWidgetsFlutterBinding;

import '../lib/test/src/util/test_util.dart';

import 'package:flutter_charts/src/chart/util/example_descriptor.dart';
import 'package:flutter_charts/test/src/example/main.dart' as app;

/// Flutter integration test takes screenshots as files from the running app '../example/lib/main.dart'
/// for all chart examples defined by the '--dart-define' environment variable 'EXAMPLES_DESCRIPTORS',
/// and resolved in [ExampleDescriptor.extractExamplesDescriptorsFromDartDefine].
///
/// Integration test invocation from command line:
///
///   ```shell
///     flutter drive \
///       --dart-define=EXAMPLES_DESCRIPTORS='absoluteMinimumNew' \
///       --driver=test_driver/integration_test.dart  \
///       --target=integration_test/screenshot_create_test.dart
///   ```
///
/// Note: Samples of EXAMPLES_DESCRIPTORS:
///   - 'ex75_lineChart_row_nonStacked_newAutoLayouter ex31_barChart_*_*_newAutoLayouter'
///   - 'absoluteMinimumNew'
///   - etc, see [ExampleDescriptor]
///
/// Note: Integration test design:
///   - The main program in `--driver=` runs on the computer.
///       It's running 'main' is found by '--target', for example, accepts image bytes and stores image file on computer.
///   - This main program in `--target=` runs on the mobile device.
///       For example, takes screenshot as bytes using [IntegrationTestWidgetsFlutterBinding.takeScreenshot],
///       then sends the image bytes to '--driver'.
///   - Both main programs can reach to each other and communicate bath ways.
///
/// Integration test steps:
///   - This `--target` installs and runs 'main' of the example app in '../example/lib/main.dart' on the device,
///   - This '--target' extracts the set of examples to run and take screenshots from by
///       invoking [ExampleDescriptor.extractExamplesDescriptorsFromDartDefine] in this code
///       ```dart
///         await binding.takeScreenshot(screenshotPath);
///       ```
///   - This '--target' invokes the [IntegrationTestWidgetsFlutterBinding.takeScreenshot], which finds
///       the screenshot-saving '--driver' program running in the computer background;
///       The result is screenshot taken from the example app as bytes, sent to the '--driver'
///   - The '--driver' takes the screenshot bytes from '--target', and saves the bytes as image
///       on a path determined by [ScreenshotPaths] in this code:
///       ```dart
///           image.writeAsBytesSync(screenshotBytes, mode: FileMode.write, flush: true);
///       ```
///   - The '--target' then moves to the next example.
///
/// Important: To complete the integration test, a follow-up test 'test/screenshot_validate_test.dart'
///   should run to compare the screenshot(s) taken by this test with expected. This follow-up test is invoked
///   by running
///
///   ```shell
///     flutter test \
///       --dart-define=EXAMPLES_DESCRIPTORS='absoluteMinimumNew' \
///       test/screenshot_validate_test.dart
///   ```
///
///
/// Note : An OLD ways to run older version of this test in 'integration_test/deprecated_v1/screenshot_create_deprecated_v1_test.dart':
///
/// 2. @deprecated: From command line or a script, passing details of example name, chartType, chartOrientation,
///    etc in individual `--dart-define` strings.
///    ```shell
///         cd dev/my-projects-source/public-on-github/flutter_charts
///         flutter emulator --launch "Nexus_6_API_33"
///         sleep 20
///         flutter clean
///         flutter pub upgrade
///         flutter pub get
///
///         flutter drive \
///           --driver=test_driver/integration_test.dart
///           --target=integration_test/deprecated_v1/screenshot_create_deprecated_v1_test.dart
///
///         # or not-default charts screenshots as
///
///         flutter  drive \
///           --dart-define=EXAMPLE_TO_RUN=ex_5_0_StocksRankedOnYWithNegatives_DataYLabels_UserColors \
///           --dart-define=CHART_TYPE=barChart \
///           --driver=test_driver/integration_test.dart \
///           --target=integration_test/deprecated_v1/screenshot_create_deprecated_v1_test.dart
///
///         # Check if file screenshot-1.png exists on top level
///    ```
///
void main() {

  // Binding in Flutter usually means Singleton.
  //
  // Create the singleton (binding) that ties Widgets to the Flutter engine.
  //
  // See 'WidgetsBinding? get instance' in WidgetsBinding mixin on how singletons
  //   work based on WidgetsBinding and BindingBase [base class for mixins that provide singleton services ("bindings")]
  //
  // This is how it works:
  //   - IntegrationTestWidgetsFlutterBinding extends LiveTestWidgetsFlutterBinding extends TestWidgetsFlutterBinding
  //       extends BindingBase  with WidgetsBinding
  //   - WidgetsBinding mixes in IntegrationTestWidgetsFlutterBinding the method 'initInstances()' which contains
  //        ```
  //        void initInstances() {
  //          super.initInstances();
  //          _instance = this; // <== If initInstances() is called in a constructor,
  //                            //     then this == instance of whichever class constuctor this is called in
  //        }
  //        ```
  //   - ensureInitialized() constructs IntegrationTestWidgetsFlutterBinding() which calls super constructors all the
  //     way to BindingBase constructor. BindingBase constructor looks like:
  //        ```
  //        BindingBase() {
  //          initInstances(); // <== This calls the mixed in method from WidgetsBinding which sets _instance = this.
  //                           //     At the time of the constructor call, this == IntegrationTestWidgetsFlutterBinding,
  //                           //       because that is the context ensureInitialized() is called from
  //                           //     So the _instance above is set to instance of IntegrationTestWidgetsFlutterBinding
  //        }
  //        ```
  //   - So, in the ensureInitialized(), the singleton instance of IntegrationTestWidgetsFlutterBinding is created.

  // Extract descriptors for examples to run. examplesDescriptors must be pushed via --dart-define=EXAMPLES_DESCRIPTORS.
  List<ExampleDescriptor> examplesDescriptors = ExampleDescriptor.extractExamplesDescriptorsFromDartDefine(
    message: 'main() of screenshot_create_test.dart',
  );

  // Normally, we can do just
  //   IntegrationTestWidgetsFlutterBinding.ensureInitialized()
  // But if we want access to the binding, we can do something like:
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot', (WidgetTester tester) async {

    // Build the app and run it on device.
    app.main();

    // This is required prior to taking the screenshot (Android only).
    await binding.convertFlutterSurfaceToImage();

    // Keep generating screenshots while Tooltip on the FloatingButton is ''
    for (var exampleDescriptor in examplesDescriptors) {

      print(' \n\n######### Log.Info.Level1: screenshot_create_test.dart: Will TAKE SCREENSHOT of $exampleDescriptor');

      var screenshotPaths = ScreenshotPaths(
        exampleDescriptor: exampleDescriptor,
      ); // old: ExampleDescriptor.requestedExampleToRun()
      String screenshotPath = screenshotPaths.actualScreenshotPath;

      // Trigger a frame.
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // When [binding.takeScreenshot] is called, the [binding] INVOKES the method callback
      // defined for [onScreenshot:] in [test_driver/integration_test.dart] and passes the callback
      // the stream of bytes from the screenshot. The callback is executed, and saves the screenshot
      // bytes to a file specified there - the test_driver framework somehow causes the image saved on
      // the computer where this test runs (not on the device)
      await binding.takeScreenshot(screenshotPath);

      // We cannot compare the actual/expected screenshots here,
      //   because this test is integration test (aka 'flutter drive' test)
      //   and runs on the device, and any File access is on the device (except the magic in integration_test.dart).
      // So, to finish the test and compare actual/expected screenshots, a Flutter regular test (widget test)
      //   named
      //   ```dart
      //     screenshot_validate_test.dart
      //   ```
      //   must be run after this test. This test runs on the computer, and compares files on the computer,
      //   not on the device.

      // 1. Find the floating action button to tap on.
      final Finder fab = find.byTooltip(ExampleMainAndTestSupport.floatingButtonTooltipMoveToNextExample);

      // Emulate a tap on the floating action button.
      // Important: This ensures the app moves to build and display the next example, having taken
      //            the screenshot two steps above.
      //            The loop that runs here ensures it moves to the next example as well,
      //            to capture the screenshot using the correct corresponding name.
      //            This whole thing assumes that both this main(), and main() in examples/lib/src/main.dart
      //            obtain and process the same  [extractExamplesDescriptorsFromDartDefine]!
      await tester.tap(fab);

      // Trigger a frame again after a tap. This seems to workaround the target artifact on second screenshot.
      await tester.pumpAndSettle();

    }

  });
}
