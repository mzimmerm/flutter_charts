/* todo keep this: Active code is to take a screenshot, but this is what we should have for normal testing:
import 'package:integration_test/integration_test_driver.dart';
Future<void> main() => integrationDriver();

// Note: This file is needed for the new integration_test (Flutter 2.5 and later) to work.
//       Without this file, there is a warning on 
//           import 'package:integration_test/integration_test_driver.dart'; 
*/

/// Allows to control apps from tests, while test code runs on a native device, physical or emulated.
import 'dart:io';
import 'package:flutter_charts/src/chart/util/example_descriptor.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {

  // Extract descriptors for examples to run. examplesDescriptors must be pushed via --dart-define=EXAMPLES_DESCRIPTORS.
  // This is here only to show a message whether the env variable was picked up.
  // List<ExampleDescriptor> examplesDescriptors =
  ExampleDescriptor.extractExamplesDescriptorsFromDartDefine(
    message: 'main() of screenshot_create_test_new.dart',
  );

  // KEEP NOTE: 2023-05-23: Broken in Flutter somewhere between 3.7(?) and 3.10.
  //   Added ', [Map<String, Object?>? optionalArgs]' optional argument to keep analyzer happy
  onScreenshot(String screenshotName, List<int> screenshotBytes, [Map<String, Object?>? optionalArgs]) async {
    final File image = File(screenshotName);
    // Write the image as bytes; flush ensures close before dart exit.
    image.writeAsBytesSync(screenshotBytes, mode: FileMode.write, flush: true);
    if (image.existsSync()) {
      return true;
    }
    // Return false if the screenshot is invalid.
    return false;
  }

  try {
    await integrationDriver(
      onScreenshot: onScreenshot,
    );
  } catch (e) {
    print(' ### Log.Error: Screenshot test driver "integration_test.dart" threw exception $e');
  }
}
