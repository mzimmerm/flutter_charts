#!/bin/bash

# Run test which generates screenshots of all examples named in the passed arguments
# followed by screenshot expected/actual comparison for the same set of examples.

set -o errexit

if [[ $# -eq 0 ]]; then
  echo 'Specify at least one example or group from the command line, exiting'
  exit 1
fi

exampleDescriptors="$*"

# Start emulator
tool/test/start_emulator.sh

# Run the main() in 'target screenshot_create_test.dart', in context of the Flutter driver 'integration_test.dart'.
#
# The 'screenshot_create_test' creates a 'human hand tester' instance, which can start an app on device and interact with it:
#
#    The tester can start the app on device (in our case 'package:flutter_charts/test/src/test_main.dart' as device_test_app)
#    The tester can tap, set text, and overall interact with the device.
#    This ability is used to start the device_test_app, keep tapping a + button, each tap runs next chart example.
#    which the 'human hand' takes a screenshot of.
#    Each 'human hand action' is implemented by a method call on the 'tester' object.
#
# Overall interaction summary between screenshot_test and device:
#
# 010. screenshot_create_thread: screenshot_create_test.main starts.
# 020. screenshot_create_thread: reads examples list.
# 030. screenshot_create_thread: uses it's 'hand' (called 'tester') to start device_test_app on device, device_test_app.main.
# 040. device_thread:            on it's own thread, device_test_app also also reads examples list, then displays chart in first example.
# 050. screenshot_create_thread: loop over examples list
# 060. screenshot_create_thread:     use 'hand' to give device_thread time to settle.
# 070. screenshot_create_thread:     use 'hand' to take screenshot on device.
# 080. note:                         at this point, both device and screenshot are on the same example in exampleDescriptors list.
# 090. screenshot_create_thread:     use hand' to tap on + button on device_thread; this causes device_thread to:
# 100. device_thread:                change state
# 110. device_thread:                call 'exampleRunState.moveToNextExample', and refresh. After 'refresh', the device shows the next chart example.
# 120. note:                         at this point, the device is one example ahead; this will synchronize back at loop begin
# 130. screenshot_create_thread:     use 'hand' to give device_thread time to settle on the next example
#
# Note: The last 3 steps happen at the same time; but the settle ensures back at loop begin, same example is used.

# Detail interaction:
#
# 010. screenshot_create_thread:  'screenshot_create_test.main()':
# 020. screenshot_create_thread:  Picks up the EXAMPLE_DESCRIPTORS from the environment, and runs all chart example enums
#      screenshot_create_thread:  from the EXAMPLE_DESCRIPTORS test or group (the test name or group name passed here via exampleDescriptors="$*").
# 020. screenshot_create_thread:  Reads examples list:
#      screenshot_create_thread:      List<ExampleDescriptor> exampleDescriptors = ExampleDescriptor.extractExampleDescriptorsFromDartDefine
# 030. screenshot_create_thread:  Calls the 'device_test_app.main()' (this is possible, main() is just another function) from the app device_test_app
#                                 WHICH STARTS the 'device_test_app.main()' on the DEVICE. *Steps on DEVICE unless noted*.
#                                 Note:
#                                   screenshot_create_code: 'package:flutter_charts/test/src/test_main.dart' as device_test_app
#                                   device_code: This 'device_test_app.main()' has a HomePage 'ExampleHomePage'
#                                                which is stateful, and part of the state is
#                                                'ExampleRunState exampleRunState'
#                                                which holds the name of the current running example in
#                                                'runningExample = exampleDescriptorsToRun[i]'.
#                                                The initial state holds
#                                                'runningExample = exampleDescriptorsToRun.first'.
#                                                The state change after tap on + is used to display next example chart on device.
# 040. device_thread:            List<ExampleDescriptor> exampleDescriptors = ExampleDescriptor.extractExampleDescriptorsFromDartDefine
# 040. device_thread:            Now both 'device_test_app' and 'screenshot_create_test' have the same list of examples to run
# 040. device_thread:            Displays the chart described inThis tap causes state change, which the 'runningExample' (set initially to exampleDescriptorsToRun.first),
# 050. screenshot_create_thread: loop over all 'exampleDescriptors', and call:
#      screenshot_create_thread:     binding.takeScreenshot(screenshotPath) // takes screenshot of 'runningExample'
#      screenshot_create_thread:     Simulates tap on 'floatingButton' on the 'device_test_app.main()', which causes:
# 060. screenshot_create_thread:     use 'hand' to give device_thread time to settle
# 070. screenshot_create_thread:     use 'hand' to take screenshot on device
# 080. note:                         at this point, both device and screenshot are on the same example in exampleDescriptors list.
# 090. screenshot_create_thread:     use hand' to tap on + button on device_thread; this causes device_thread to:
# 100. device_thread:                change state,
# 110. device_thread:                'exampleRunState.moveToNextExample':
#      device_thread:                moveToNextExample forces state change which forces refresh, with next example
# 120. note:                         at this point, the device is one example ahead; this will synchronize back at loop begin
# 130. screenshot_create_thread:     use 'hand' to give device_thread time to settle on the next example
#

# There are 3 'main()' programs involved in creating screenshot of on-device-running-app in 'test/src/test_main.dart'
#    1. The on-computer-running-driver main() 'driver' in 'test_driver/integration_test.dart'
#       with a single call to
#           integrationDriver( onScreenshot: onScreenshotCallback )
#       which communicates with on-device-running-test
#    2. The on-device-running-test     main() in 'integration_test/screenshot_create_test.dart' which
#          a) Starts the on-device-running-app in 3)
#          b) Creates a 'user hand' tester which controls the on-device-running-app
#    3. The on-device-running-app      main() in 'test/src/test_main.dart' as device_test_app;' which is the chart app

flutter drive \
  --dart-define=EXAMPLE_DESCRIPTORS="$exampleDescriptors" \
  --driver=test_driver/integration_test.dart  \
  --target=integration_test/screenshot_create_test.dart

# Run the main() in screenshot_validate_test.dart.
# The main() runs all chart example enums from the group - see above drive test for details of expansion.
flutter test \
  --dart-define=EXAMPLE_DESCRIPTORS="$exampleDescriptors" \
  test/screenshot_validate_test.dart
