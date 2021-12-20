/// Flutter integration (drive) tests creating a screenshot from running app.
///
/// Running these tests should be followed by tests which compare expected/actual screenshots.
/// Those screenshot-comparing tests are in [screenshot comparing test file](test/screenshot_check_test.dart).

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart' show IntegrationTestWidgetsFlutterBinding;

import '../test/test_util.dart';

import '../example1/lib/src/util/examples_descriptor.dart';
import '../example1/lib/main.dart' as app;

/// Integration testing by taking a screenshot from the example app,
///   and comparing the produced screenshot with a known correct screenshot.
///
/// Flutter integration test of one instance of the example app, with example data, options, and chart type
///   dictated by the [ExamplesEnum] and [ExamplesChartTypeEnum], set by caller in `--dart-define`.
///
/// The data and options given by the enums are set in [example1/lib/main.dart] method [defineOptionsAndData()].
///
/// See [example1/lib/main.dart] method [requestedExampleToRun()] on processed `--dart-define` values.
///
/// The test can be run from command line or a script as
/// ```shell
///         cd dev/my-projects-source/public-on-github/flutter_charts
///         flutter emulator --launch "Nexus_6_API_29_2"
///         sleep 20
///         flutter clean
///         flutter pub upgrade
///         flutter pub get
///
///         flutter drive \
///           --driver=test_driver/integration_test.dart
///           --target=integration_test/screenshot_create_test.dart
///
///         # or non-default charts screenshots as
///
///         flutter  drive \
///           --dart-define=EXAMPLE_TO_RUN=ex_5_0_StocksRankedOnYWithNegatives_DataYLabels_UserColors \
///           --dart-define=CHART_TYPE_TO_SHOW=VerticalBarChart \
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
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized() as IntegrationTestWidgetsFlutterBinding;

  testWidgets('screenshot', (WidgetTester tester) async {
    // Find the command-line provided enums which define chart data, options and type to use in the example app.
    // The app find the enums transiently, here we need it to generate consistent screenshot filename.
    var screenshotPaths = screenshotPathsFor(app.requestedExampleToRun());
    String screenshotPath = screenshotPaths.item2;

    // Build the app.
    app.main();

    // This is required prior to taking the screenshot (Android only).
    await binding.convertFlutterSurfaceToImage();

    // Trigger a frame.
    await tester.pumpAndSettle();
    await binding.takeScreenshot(screenshotPath);

    // We cannot compare the actual/expected screenshots here, because this test (being integration test)
    //   runs on the device, and any File access is on the device.
    // So, to finish the test and compare actual/expected screenshots, a Flutter regular test (widget test)
    //   named
    //   ```dart
    //     screenshot_check_test.dart
    //   ```
    //   must be run after this test.
  });
}
