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

import '../test/test_util.dart';

import 'package:flutter_charts/src/chart/util/example_descriptor.dart';
// todo-00-next : use main_new : import '../example/lib/main_new.dart' as app;
import '../example/lib/main.dart' as app;

// todo-00-progress
import 'dart:io' show sleep;
// import 'dart:async' show Future;

/// Integration testing by taking a screenshot from the example app,
///   and comparing the produced screenshot with a known correct screenshot.
///
/// todo-00-next : update  this section
/// Flutter integration test of one instance of the example app, with example data, options, and chart type
///   dictated by the [ExampleEnum] and [ExamplesChartTypeEnum], set by caller in `--dart-define`.
///
/// The data and options given by the enums are set in [example/lib/main.dart] method 
/// [_ExampleDefiner.createRequestedChart].
///
/// Two ways to run this test:
///
/// 1. From command line, the 'new' way (2023-06-01) passing the examples to run
///    in one `--dart-define=EXAMPLES_DESCRIPTORS=ETC`. Notes and details:
///
///    - Can be run as
///      ```shell
///        flutter drive \
///          --dart-define=EXAMPLES_DESCRIPTORS='ex75_lineChart_row_nonStacked_newAutoLayouter ex31_barChart_*_*_newAutoLayouter' \
///          --driver=test_driver/integration_test.dart  \
///          --target=integration_test/screenshot_create_test_new.dart
///      ```
///    - If run as above, the EXAMPLES_DESCRIPTORS appears in the [main] of this file,
///      the 'screenshot_create_test_new.dart', which is what we want, as this test generates
///      screenshots of all examples defined in 'EXAMPLES_DESCRIPTORS'.
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
///           --target=integration_test/screenshot_create_test.dart
///
///         # or not-default charts screenshots as
///
///         flutter  drive \
///           --dart-define=EXAMPLE_TO_RUN=ex_5_0_StocksRankedOnYWithNegatives_DataYLabels_UserColors \
///           --dart-define=CHART_TYPE=barChart \
///           --driver=test_driver/integration_test.dart \
///           --target=integration_test/screenshot_create_test.dart
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
    message: 'main() of screenshot_create_test_new.dart',
  );

  // Normally, we can do just
  //   IntegrationTestWidgetsFlutterBinding.ensureInitialized()
  // But if we want access to the binding, we can do something like:
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot', (WidgetTester tester) async {
/* todo-00-done
    var screenshotPaths = screenshotPathsFor(ExampleDescriptor.requestedExampleToRun());
    String screenshotPath = screenshotPaths.item2;
*/

    // Build the app and run it on device.
    app.main();

    // This is required prior to taking the screenshot (Android only).
    await binding.convertFlutterSurfaceToImage();

    // todo-00-progress : added loop as test. This should be replaced with asking for next app vvv
    // This runs successfully from command line, creating 3 screenshots using:
    //  flutter drive --dart-define=EXAMPLE_TO_RUN=ex10RandomData   --dart-define=CHART_TYPE=lineChart   --dart-define=CHART_ORIENTATION=column   --dart-define=CHART_STACKING=nonStacked   --dart-define=CHART_LAYOUTER=oldManualLayouter   --driver=test_driver/integration_test.dart --target=integration_test/screenshot_create_test_new.dart

    // Keep generating screenshots while Tooltip on the FloatingButton is ''
    for (var exampleDescriptor in examplesDescriptors) {

      var screenshotPaths = ScreenshotPaths(
        exampleDescriptor: exampleDescriptor,
      ); // old: ExampleDescriptor.requestedExampleToRun()
      String screenshotPath = screenshotPaths.actualScreenshotPath;

      // Trigger a frame.
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

      // todo-00-progress vvv
      // ### Preliminary proof of concept that this section can run in a loop:
      //   1. Find and tap (click) the + button, showing new data
      //   2. Wait 3s
      //   3. Back to top of the loop

      // 1. Find the floating action button to tap on.
      final Finder fab = find.byTooltip(ExampleMainAndTestSupport.floatingButtonTooltipMoveToNextExample);

      // Emulate a tap on the floating action button.
      // Important: This ensures the app moves to build and display the next example.
      //            The loop that runs here ensures it moves to the next example as well,
      //            to capture the screenshot using the correct corresponding name.
      //            This whole thing assumes that both this main(), and main() in examples/lib/src/main.dart
      //            obtain and process the same  [extractExamplesDescriptorsFromDartDefine]!
      await tester.tap(fab);

      // Sleep for some time before running next example
      // await Future.delayed(const Duration(seconds: 3));

      // sleep(const Duration(seconds: 1));

      // Trigger a frame again after a tap. This seems to workaround the target artifact on second screenshot.
      await tester.pumpAndSettle();

      // todo-00-progress ^^^
    }

/* todo-00-done : not needed
    // Trigger a last frame.
    await tester.pumpAndSettle();

    // And take a dummy screenshot
    await binding.takeScreenshot('/home/mzimmermann/dev/my-projects-source/public-on-github/flutter_charts_v2/integration_test/screenshots_tested/dummy.png');
*/

  });
}
