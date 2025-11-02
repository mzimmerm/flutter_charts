#!/bin/bash

# Run test which generates screenshots of all examples named in the passed arguments
# followed by screenshot expected/actual comparison for the same set of examples.

set -o errexit

echo "$0" called with args "$@"

# To process command line arguments, we use bargs.sh and .run_screenshot_create_then_validate_integration_test_bargs_vars,
# downloaded as
#    'curl https://raw.githubusercontent.com/unfor19/bargs/master/bargs.sh --output bargs.sh'

# export BARGS_VARS_PATH="${PWD}/tool/test/.run_screenshot_create_then_validate_integration_test_bargs_vars"
export BARGS_VARS_PATH="tool/test/.run_screenshot_create_then_validate_integration_test_bargs_vars"

source tool/external/bargs.sh "$@"
echo "Running auto_layout examples in : $auto_layout"
echo "Running coded_layout examples in : $coded_layout"

exampleDescriptorsAutoLayout="$auto_layout"
exampleDescriptorsCodedLayout="$coded_layout"

# Inner
function _duplicate_test_files_from_auto_layout_to_coded_layout() {

  if ! \
    sed -e 's?package:flutter_charts/test/src/test_main.dart?package:flutter_charts/test/src/coded_layout_test_main.dart?' \
      < integration_test/screenshot_create_test.dart \
      > integration_test/coded_layout_screenshot_create_test.dart; then
    echo ERROR substituting in 'screenshot_create_test.dart', exiting.
    sleep 10
    exit 1
  fi

  if ! \
    sed -e 's?package:flutter_charts/src/chart/cartesian/view_model/line/line_view_model.dart?package:flutter_charts/src/coded_layout/chart/cartesian/view_model/line/coded_layout_line_view_model.dart?' \
        -e 's?package:flutter_charts/src/chart/cartesian/view_model/bar/bar_view_model.dart?package:flutter_charts/src/coded_layout/chart/cartesian/view_model/bar/coded_layout_bar_view_model.dart?' \
        -e 's?LineChartViewModel(?LineChartViewModelCL(?' \
        -e 's?BarChartViewModel(?BarChartViewModelCL(?' \
      < lib/test/src/test_main.dart \
      > lib/test/src/coded_layout_test_main.dart; then
    echo ERROR substituting in 'test_main.dart', exiting.
    sleep 10
    exit 1
  fi
}

# Start emulator
tool/test/start_emulator.sh

# Run the main() in 'target screenshot_create_test.dart',
# in the context of the Flutter driver 'integration_test.dart'.
#
# The 'screenshot_create_test' is the integration test which main()
# calls the method  'testWidget(screenshot, testerCallback)'.
# The 'testerCallback' method is declared inline. It is a 'human hand tester'
# (referred to as 'tester'), which can start an app on device and interact with it
# as a human hand would: tap, drag, set text etc:
#
#    The 'tester' starts the app on device (in our case 'package:flutter_charts/test/src/test_main.dart'
#    as device_test_app). The tester can tap, set text, and overall interact with the device.
#    This ability is used to start the device_test_app, keep tapping a + button, each tap runs
#    next chart example,  which the 'human hand' takes a screenshot of.
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

# todo-00-last-last: put back: for layout in auto_layout coded_layout; do
for layout in auto_layout; do

  case $layout in
    auto_layout)
      exampleDescriptors="$exampleDescriptorsAutoLayout"
      screenshot_create_test="screenshot_create_test.dart"
      ;;
    coded_layout)
      exampleDescriptors="$exampleDescriptorsCodedLayout"
      screenshot_create_test="coded_layout_screenshot_create_test.dart"
      ;;
    default)
      echo Internal error, invalid layout=$layout, exiting
      exit 1
  esac

  comment_duplicate_files_from_auto_layout=$'\n----------\nDuplicating test files from auto_layout to coded_layout\n'
  comment_run_screenshot_create=$'\n----------\nCreating screenshots for '${layout}$'.\n'
  comment_run_screenshot_validate=$'\n----------\nValidating screenshots for '${layout}$'.\n'

  if [[ $layout == coded_layout ]]; then
    # auto_layout test files 'screenshot_create_test.dart' and in there called app 'test_main.dart'
    # are copied to their coded_layout equivalents. We want to keep only one core copy of the test app,
    # the test_main.dart and copy it to a generated coded_layout_test_main.dart.
    echo "$comment_duplicate_files_from_auto_layout"
    _duplicate_test_files_from_auto_layout_to_coded_layout
    sleep 5
  fi
  # Run the main() in [coded_layout_]screenshot_create_test.dart.
  # The main() runs all chart example enums from the group - see above drive test for details of expansion.
  echo "$comment_run_screenshot_create"; sleep 5
  flutter drive \
    --dart-define=EXAMPLE_DESCRIPTORS="$exampleDescriptors" \
    --driver=test_driver/integration_test.dart  \
    --target=integration_test/"$screenshot_create_test"

  # Run the main() in screenshot_validate_test.dart.
  # The main() runs all chart example enums from the group - see above drive test for details of expansion.
  echo "$comment_run_screenshot_validate"; sleep 5
  flutter test \
    --dart-define=EXAMPLE_DESCRIPTORS="$exampleDescriptors" \
    test/screenshot_validate_test.dart

done
