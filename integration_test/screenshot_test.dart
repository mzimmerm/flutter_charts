/// See https://docs.flutter.dev/cookbook/testing/integration/introduction
///   for integration testing in Flutter.
///
/// See https://dev.to/mjablecnik/take-screenshot-during-flutter-integration-tests-435k
///   for how to take a screenshot from your Flutter app inside flutter test integration_test/app_test.dart;
///   but the same should work from an actual flutter run --device_id app.dart
///
// import 'dart:ffi';

// import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart' show IntegrationTestWidgetsFlutterBinding;
import 'package:tuple/tuple.dart';
import 'dart:io';

import '../test/test_util.dart';

import '../example1/lib/ExamplesChartTypeEnum.dart';
import '../example1/lib/ExamplesEnum.dart';
import '../example1/lib/examples_descriptor.dart';
import '../example1/lib/main.dart' as app;
// import '../lib/main.dart' as app; // Flutter Demo mis-placed as a app main file in flutter_charts/lib/main.dart

// TODO-00 : RENAME TO SCREENSHOT_CREATE_TEST.Dart

/// Integration testing by taking a screenshot from the example app, 
///   and comparing the produced screenshot with a known correct screenshot.
/// 
/// Flutter integration test of one instance of the example app, with example data, options, and chart type
///   dictated by the [ExamplesEnum] and [ExamplesChartTypeEnum], set by caller in `--dart-define`.
///   
/// The data and options given by the enums are set in [example1/lib/main.dart] method [defineOptionsAndData()].
/// 
/// See [example1/lib/main.dart] method [requestedExampleComboToRun()] on processed `--dart-define` values.
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
///           --target=integration_test/screenshot_test.dart
///           
///         # or non-default charts screenshots as
///         
///         flutter  drive \
///           --dart-define=EXAMPLE_TO_RUN=ex_5_0_StocksRankedOnYWithNegatives_DataYLabels_UserColors \
///           --dart-define=CHART_TYPE_TO_SHOW=VerticalBarChart \
///           --driver=test_driver/integration_test.dart \
///           --target=integration_test/screenshot_test.dart
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
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
  as IntegrationTestWidgetsFlutterBinding;

  testWidgets('screenshot', (WidgetTester tester) async {
    // Find the command-line provided enums which define chart data, options and type to use in the example app.
    // The app find the enums transiently, here we need it to generate consistent screenshot filename. 
    // todo-00 rename comboToRun to exampleToRun everywhere
    // todo-00 move this code to a single function in test_util.dart
    Tuple2<ExamplesEnum, ExamplesChartTypeEnum> exampleToRun = app.requestedExampleComboToRun();
    String screenshotPath = relativePath(screenshotDirName(), exampleToRun);
    String expectedScreenshotPath = relativePath(expectedScreenshotDirName(), exampleToRun);

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
    
     // todo-00 THIS CODE RUNS ON THE DEVICE. SO, ANY FILE OPERATIONS ARE ON THE DEVICE. THIS MUST BE MOVED TO ANOTHER TEST WHICH IS REGULAR FLUTTER WIDGET TEST. 
/*
   // Flag controls if this test runs 'expect'. 
    // Set to false to generate initial validated screenshots.
    bool runExpect = true;

    if (runExpect) {
      // todo-00 figure out how to start flutter drive in project. current dir says /
      print('Directory is ${Directory.current}');
      String path = '/home/mzimmermann/dev/my-projects-source/public-on-github/flutter_charts_v2/';
      
      var contents = File(path + expectedScreenshotPath).readAsBytesSync();

      File expectedFile = File(path + expectedScreenshotPath);
      File actualFile = File(path + screenshotPath);
      
      expectedFile.readAsString().then((String contents) {
        print('Expected File Contents\n---------------');
        print(contents);
      });

      actualFile.readAsString().then((String contents) {
        print('ActualFile File Contents\n---------------');
        print(contents);
      });

      if (expectedFile.existsSync()) {
        if (actualFile.existsSync()) {
          expectSync(
            expectedFile.readAsBytesSync(),
            actualFile.readAsBytesSync(),
          );
        } else {
          throw StateError('Could not await for actual file');
        }
      } else {
        throw StateError('Could not await for expected file');
      }
    }
*/
  });
  
  // todo-00 more tests
}

/*
  /// Path to screenshot file the test uses for each test.
  String relativePath(String screenshotDirName, Tuple2 <ExamplesEnum, ExamplesChartTypeEnum> comboToRun) {
    return '$screenshotDirName/${screenshotFileName(comboToRun)}';
  }

  /// Path to screenshot file which this test generates. 
  /// 
  /// Generated from enum values. 
  /// Example: 'ex10RandomData-lineChart.png'.
  String screenshotFileName(Tuple2<ExamplesEnum, ExamplesChartTypeEnum> comboToRun) {
    return '${enumName(comboToRun.item1)}_${enumName(comboToRun.item2)}.png';
  }

  /// The name of the directory where screenshots are placed.
  /// 
  /// This test is assumed to run from project's root.
  String screenshotDirName() {
    return 'integration_test/screenshots_tested';
  }

  String expectedScreenshotDirName() {
    return 'integration_test/screenshots_expected';
  }
*/

