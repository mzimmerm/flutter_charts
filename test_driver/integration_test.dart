/* todo keep this: Active code is to take a screenshot, but this is what we should have for normal testing:
import 'package:integration_test/integration_test_driver.dart';
Future<void> main() => integrationDriver();

// Note: This file is needed for the new integration_test (Flutter 2.5 and later) to work.
//       Without this file, there is a warning on 
//           import 'package:integration_test/integration_test_driver.dart'; 
*/

import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String screenshotName, List<int> screenshotBytes) async {
      final File image = File('$screenshotName.png');
      image.writeAsBytesSync(screenshotBytes);
      // Return false if the screenshot is invalid.
      return true;
    },
  );
}

