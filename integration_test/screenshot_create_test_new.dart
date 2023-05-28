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
/// Those screenshot-comparing tests are in [screenshot comparing test file](test/screenshot_check_test.dart).

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart' show IntegrationTestWidgetsFlutterBinding;

import '../test/test_util.dart';

import '../example/lib/src/util/examples_descriptor.dart';
// todo-00-next : use main_new : import '../example/lib/main_new.dart' as app;
import '../example/lib/main.dart' as app;

// todo-00-progress
// import 'dart:io' show sleep;
// import 'dart:async' show Future;

/// Integration testing by taking a screenshot from the example app,
///   and comparing the produced screenshot with a known correct screenshot.
///
/// Flutter integration test of one instance of the example app, with example data, options, and chart type
///   dictated by the [ExamplesEnum] and [ExamplesChartTypeEnum], set by caller in `--dart-define`.
///
/// The data and options given by the enums are set in [example/lib/main.dart] method 
/// [_ExampleDefiner.createRequestedChart].
///
/// See [example/lib/main.dart] method [_ExampleDefiner.createRequestedChart] on processed `--dart-define` values.
///
/// The test can be run from command line or a script as
/// ```shell
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
///  ```
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

  // Normally, we can do just
  //   IntegrationTestWidgetsFlutterBinding.ensureInitialized()
  // But if we want access to the binding, we can do something like:
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot', (WidgetTester tester) async {
    // Find the command-line provided enums which define chart data, options and type to use in the example app.
    // The app find the enums transiently, here we need it to generate consistent screenshot filename.
    var screenshotPaths = screenshotPathsFor(app.requestedExampleToRun());
    String screenshotPath = screenshotPaths.item2;

    // Build the app and run it on device.
    app.main();

    // This is required prior to taking the screenshot (Android only).
    await binding.convertFlutterSurfaceToImage();

    // todo-00-progress : added loop as test. This should be replaced with asking for next app vvv
    // This runs successfully from command line, creating 3 screenshots using:
    //  flutter drive --dart-define=EXAMPLE_TO_RUN=ex10RandomData   --dart-define=CHART_TYPE=lineChart   --dart-define=CHART_ORIENTATION=column   --dart-define=CHART_STACKING=nonStacked   --dart-define=CHART_LAYOUTER=oldManualLayouter   --driver=test_driver/integration_test.dart --target=integration_test/screenshot_create_test_new.dart

    var numExamplesToRun = 3;
    var examplesRunCounter = 0;

    while (examplesRunCounter < numExamplesToRun) {

      // Set the screenshot name corresponding to runCounter
      screenshotPath = '$screenshotPath-$examplesRunCounter';

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
      //     screenshot_check_test.dart
      //   ```
      //   must be run after this test. This test runs on the computer, and compares files on the computer,
      //   not on the device.

      // todo-00-progress vvv
      // ### Preliminary proof of concept that this section can run in a loop:
      //   1. Find and tap (click) the + button, showing new data
      //   2. Wait 3s
      //   3. Back to top of the loop

      // 1. Find the floating action button to tap on.
      final Finder fab = find.byTooltip('New Random Data');

      // Emulate a tap on the floating action button.
      await tester.tap(fab);

      // Sleep for some time before running next example
      // await Future.delayed(const Duration(seconds: 3));

      // also works: sleep(const Duration(seconds: 3));

      // Increase the examples counter
      examplesRunCounter++;
      // todo-00-progress ^^^
    }
  });
}
