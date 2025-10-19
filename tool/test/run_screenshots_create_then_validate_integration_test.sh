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
# The 'screenshot_create_test' is like a 'human hand' which can interact with app running on device:
#
#    It can start the app on device
#    It can tap, set text, and overall interact with the device.
#
# Overall interaction summary between screenshot_test and device:
#
# 010. screenshot_create_thread: screenshot_create_test.main starts
# 020. screenshot_create_thread: reads examples list
# 030. screenshot_create_thread: uses it's 'hand' (called 'tester') to start device_test_app on device, device_test_app.main
# 040. device_thread:            on it's own thread, device_test_app also also reads examples list, then displays chart in first example
# 050. screenshot_create_thread: loop over examples list
# 060. screenshot_create_thread:     use 'hand' to give device_thread time to settle
# 070. screenshot_create_thread:     use 'hand' to take screenshot on device
# 080. note:                         at this point, both device and screenshot are on the same example in examples list.
# 090. screenshot_create_thread:     use hand' to tap on + button on device_thread; this causes device_thread to:
# 100. device_thread:                change state,
# 110. device_thread:                call 'exampleRunState.moveToNextExample', and refresh. After 'refresh', the device shows the next chart example
# 120. note:                         at this point, the device is one example ahead; this will synchronize back at loop begin
# 130. screenshot_create_thread:     use 'hand' to give device_thread time to settle on the next example
#
# Note: The last 3 steps happen at the same time; but the settle ensures back at loop begin, same example is used.

# Detail interaction:
#
# 010. screenshot_create_thread:  'screenshot_create_test.main()':
# 020. screenshot_create_thread:  Picks up the EXAMPLES_DESCRIPTORS from the environment, and runs all chart example enums
#      screenshot_create_thread:  from the EXAMPLES_DESCRIPTORS test or group (the test name or group name passed here via exampleDescriptors="$*").
# 020. screenshot_create_thread:  Reads examples list:
#      screenshot_create_thread:      List<ExampleDescriptor> exampleDescriptors = ExampleDescriptor.extractExamplesDescriptorsFromDartDefine
# 030. screenshot_create_thread:  Calls the 'device_test_app.main()' (this is possible, main() is just another function) from the app device_test_app
#                                 WHICH STARTS the 'device_test_app.main()' on the DEVICE. *Steps on DEVICE unless noted*
#                                 Note: 'package:flutter_charts/test/src/test_main.dart' as device_test_app
#                                       device_code:  This 'device_test_app.main()' has a HomePage 'ExampleHomePage' which is stateful, and part of the state is
#                                       device_code: 'ExampleRunState exampleRunState' which holds the name of the current running example in
#                                       device_code:  runningExample = exampleDescriptorsToRun[i]
#                                       device_code:  The initial state holds 'runningExample = exampleDescriptorsToRun.first'
# 040. device_thread:            List<ExampleDescriptor> exampleDescriptors = ExampleDescriptor.extractExamplesDescriptorsFromDartDefine
# 040. device_thread:            Now both 'device_test_aexampleDescriptorspp' and 'screenshot_create_test' have the same list of examples to run
# 040. device_thread:            Displays the chart described inThis tap causes state change, which the 'runningExample' (set initially to exampleDescriptorsToRun.first),
# 050. screenshot_create_thread: loops over all 'exampleDescriptors', and calls:
#      screenshot_create_thread:     binding.takeScreenshot(screenshotPath) // takes screenshot of 'runningExample'
#      screenshot_create_thread:     Simulates tap on 'floatingButton' on the 'device_test_app.main()', which causes:
# 060. screenshot_create_thread:     use 'hand' to give device_thread time to settle
# 070. screenshot_create_thread:     use 'hand' to take screenshot on device
# 080. note:                         at this point, both device and screenshot are on the same example in examples list.
# 090. screenshot_create_thread:     use hand' to tap on + button on device_thread; this causes device_thread to:
# 100. device_thread:                change state,
# 110. device_thread:                'exampleRunState.moveToNextExample':
#      device_thread:                moveToNextExample forces state change which forces refresh, with next example
# 120. note:                         at this point, the device is one example ahead; this will synchronize back at loop begin
# 130. screenshot_create_thread:     use 'hand' to give device_thread time to settle on the next example
#

flutter drive \
  --dart-define=EXAMPLES_DESCRIPTORS="$exampleDescriptors" \
  --driver=test_driver/integration_test.dart  \
  --target=integration_test/screenshot_create_test.dart

# Run the main() in screenshot_validate_test.dart.
# The main() runs all chart example enums from the group - see above drive test for details of expansion.
flutter test \
  --dart-define=EXAMPLES_DESCRIPTORS="$exampleDescriptors" \
  test/screenshot_validate_test.dart
