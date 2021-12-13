/* todo keep this: Active code is to take a screenshot, but this is what we should have for normal testing:
import 'package:integration_test/integration_test_driver.dart';
Future<void> main() => integrationDriver();

// Note: This file is needed for the new integration_test (Flutter 2.5 and later) to work.
//       Without this file, there is a warning on 
//           import 'package:integration_test/integration_test_driver.dart'; 
*/

/// Allows to control apps from tests, while test code runs on a native device, physical or emulated. 
import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String screenshotName, List<int> screenshotBytes) async {
      final File image = File(screenshotName);
      // Write the image as bytes; flush ensures close before dart exit.
      image.writeAsBytesSync(screenshotBytes, mode: FileMode.write, flush: true);
      if (image.existsSync()) {
        return true;
      }
      // Return false if the screenshot is invalid.
      return false;
    },
  );
}

