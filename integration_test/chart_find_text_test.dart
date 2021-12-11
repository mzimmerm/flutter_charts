/// See https://docs.flutter.dev/cookbook/testing/integration/introduction
///   for integration testing in Flutter.
/// 
/// See https://dev.to/mjablecnik/take-screenshot-during-flutter-integration-tests-435k
///   for how to take a screenshot from your Flutter app inside flutter test integration_test/app_test.dart;
///   but the same should work from an actual flutter run --device_id app.dart
///   
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../example/lib/main.dart' as app;

void main() {
  // Initialize the singleton (binding) that ties Widgets to Flutter engine.
  // See 'WidgetsBinding? get instance' in WidgetsBinding mixin on how singletons 
  //   work based on WidgetsBinding and BindingBase [base class for mixins that provide singleton services ("bindings")]
  // Note: This is how it works:
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
  //   - So, through the ensureInitialized(), the singleton instance of IntegrationTestWidgetsFlutterBinding is created.
  
  // Normally, we can do just
  //   IntegrationTestWidgetsFlutterBinding.ensureInitialized()
  // But if we want access to the binding, we can do something like:
  // final binding = IntegrationTestWidgetsFlutterBinding();
  // IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
  as IntegrationTestWidgetsFlutterBinding;
  
  group('screenshot', () {
    testWidgets('tap on the floating action button, verify counter',
            (WidgetTester tester) async {
          app.main();

          await tester.pumpAndSettle();
          
          // Take a screenshot step 1. On Android only - not on Web or IOS
          await binding.convertFlutterSurfaceToImage();
          // Always needed (even without screenshot)
          await tester.pumpAndSettle();
          // Take a screenshot step 2. On all devices.
          await binding.takeScreenshot('test-screenshot');
          // await binding.revertFlutterImage();
/*
          
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
*/
        });
  });
  }