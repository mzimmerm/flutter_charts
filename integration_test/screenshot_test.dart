/// See https://docs.flutter.dev/cookbook/testing/integration/introduction
///   for integration testing in Flutter.
///
/// See https://dev.to/mjablecnik/take-screenshot-during-flutter-integration-tests-435k
///   for how to take a screenshot from your Flutter app inside flutter test integration_test/app_test.dart;
///   but the same should work from an actual flutter run --device_id app.dart
///
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart' show IntegrationTestWidgetsFlutterBinding;

import '../example1/lib/main.dart' as app;
// import '../lib/main.dart' as app; // Flutter Demo mis-placed as a app main file in flutter_charts/lib/main.dart

/// Tests taking a screenshot from a running Flutter app.
/// 
/// Test taking a screenshot from a running Flutter app.
///
/// Run the test (which creates screenshot) from command line 
/// ``` shell
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
  // Initialize the singleton (binding) that ties Widgets to Flutter engine.
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
    
    // Build the app.
    app.main();

    // This is required prior to taking the screenshot (Android only).
    await binding.convertFlutterSurfaceToImage();

    // Trigger a frame.
    await tester.pumpAndSettle();
    await binding.takeScreenshot('screenshot-1');
  });
}
