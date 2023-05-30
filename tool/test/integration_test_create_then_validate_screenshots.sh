#!/bin/bash

# This script runs a SINGLE or ALL examples in the example app in "example/lib/main.dart",
#   captures a screenshot from each example, then optionally runs a follow-up process which
#   validates that the captured screenshot is the same as an expected screenshot (taken earlier and validated).
#
# In more details:
#   - Running a single or all examples is controlled by $1.
#     - If $1 is set, it is assumed to be an example id from 'ExampleEnum', and the single example is executed
#     - Else, all examples from  'ExampleEnum' are executed
#   - This script runs in 2 steps
#     1. Sources a program-generating script 'start_emulator_and_generate_example_descriptor.sh'
#        which creates one or more scripts stored in 'tests/tmp/example_descriptor_generated_program_RANDOM.sh'
#        (calling each of these scripts tmp-script-program).
#        - Each tmp-script-program:
#          - looks like this:
#            ```sh
#             $1 \
#             --dart-define=EXAMPLE_TO_RUN=ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded \
#             --dart-define=CHART_TYPE=barChart \
#             --dart-define=CHART_LAYOUTER=$CHART_LAYOUTER \
#             $2
#            ```
#          - contains one example from 'ExampleEnum' or the command line to execute.
#          - provides an argument to an executable $1 which can be 'flutter drive --driver --target',
#            so it (the tmp-script-program) can execute its $1 argument by running itself as:
#              'tmp-script-program flutter drive --target integration_test/screenshot_create_test.dart'
#            so runs the passed executable appended with the rest of its line, e.g.
#            ```sh
#              flutter drive \
#                --driver=test_driver/integration_test.dart \
#                --target=integration_test/screenshot_create_test.dart  \
#                --dart-define=EXAMPLE_TO_RUN=ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded  \
#                --dart-define=CHART_TYPE=barChart  \
#                --dart-define=CHART_LAYOUTER=$CHART_LAYOUTER \
#                $2
#            ```
#          - is executed in step 2.
#
#     2. Each tmp-script-program is executed twice:
#       2.1. First, runs integration test ('flutter drive') on the tmp-script-program arguments
#       2.2. Next,  runs screenshot comparison test (this is a flutter widget test 'flutter test')
#          'flutter test  test/screenshot_check_test.dart'
#           which compares
#           - screenshot captured in step 2 with
#           - screenshot expected, captured before any changes

# Exit on error
set -o errexit

if [[ "$1" == "--help" ]]; then
  echo Usage: integration_test_create_then_validate_screenshots.sh \[exampleEnum\]
  exit 1 
fi

if [[ $1 != firstRun && $1 != nextRun ]]; then
  echo First argument, must be either firstRun or nextRun, exiting.
  exit 1
fi

if [[ $1 == firstRun ]]; then
  isFirstRun=true
elif [[ $1 == nextRun ]]; then
  echo Running without: 1. Starting emulator 2. without pub get 3. without build!
  isFirstRun=false
  # noPubNoBuild='--no-pub --use-application-binary=./build/app/outputs/apk/debug/app-debug.apk'
  # noPubNoBuild='--no-pub --no-build'
  # --no-build has no effect;
  # --use-application-binary does not work, as the example enum is baked in the build binary app-debug.apk
  # --no-pub has very small effect.
  # NONE OF THIS IS PROBABLY WORTH IT
  noPubNoBuild='--no-pub'
  noPub='--no-pub'
fi

if [[ -n "$2" ]]; then

  # If the second argument is provided, 5 values which fully specify the chart to run must be provided:
  #   EXAMPLE_TO_RUN, CHART_TYPE, CHART_ORIENTATION, CHART_STACKING, and CHART_LAYOUTER
  exampleEnum=$2
  chartTypeEnum=$3
  chartOrientation=$CHART_ORIENTATION
  chartStacking=$CHART_STACKING
  chartLayouter=$CHART_LAYOUTER

  echo
  echo -------------------------------------
  echo Assuming you asking to run only one test, given by ExampleEnum: "$exampleEnum"
  echo Not cleaning screenshots results, to be able to run multiple single examples and keep results.
  echo
else
  echo
  echo -------------------------------------
  echo Removing old tmp test files, ignoring errors
  rm --force integration_test/screenshots_tested/*.png
fi  
  
#  This script can only run from project top directory.
if [ -z "$(find . -maxdepth 1 -type d -name integration_test)" ]; then 
  echo Execution directory must be from project top directory. Failed the test for presence of directory integration_test, exiting.
  exit 1
fi


echo
echo -------------------------------------
echo Step 1: Sources script \"start_emulator_and_generate_example_descriptor.sh\", which starts emulator
echo         and generates program \"tmp/example_descriptor_generated_program_$RANDOM.sh\"
echo         that contains command lines to test each example one after another in step 2.
#   This program can run 1) integration test 'flutter drive' 2) widget test 'flutter test' 3) the app 'flutter run'.
#   See the sourced script below for details of variable and contents of $example_descriptor_generated_program.
source tool/test/start_emulator_and_generate_example_descriptor.sh \
  "$isFirstRun" \
  "$exampleEnum" \
  "$chartTypeEnum" \
  "$chartOrientation" \
  "$chartStacking" \
  "$isUseOldLayouter"

echo Will run "$example_descriptor_generated_program".
echo
example_descriptor_generated_program=$example_descriptor_generated_program

# Run integration test which creates screenshot, then validates it. An example of what the bash -x runs:
#            ```sh
#              flutter drive \
#                --driver=test_driver/integration_test.dart \
#                --target=integration_test/screenshot_create_test.dart  \
#                --dart-define=EXAMPLE_TO_RUN=ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded  \
#                --dart-define=CHART_TYPE=barChart  \
#                --dart-define=CHART_LAYOUTER=$CHART_LAYOUTER \
#                $2
#            ```
echo
echo -------------------------------------
echo Step 2: Running SCREENSHOTS-GENERATING integration tests \"flutter drive\" on \"$example_descriptor_generated_program\".
echo         on file \"screenshot_create_test.dart\".
echo         This generates screenshots for all examples,
echo         by running the tmp program \"$example_descriptor_generated_program\"
echo         generated by \"example_descriptor.dart\"
echo
bash -x "$example_descriptor_generated_program" \
        "flutter drive $noPubNoBuild" \
        " --driver=test_driver/integration_test.dart --target=integration_test/screenshot_create_test.dart"

echo
echo -------------------------------------
echo Step 3: Running SCREENSHOTS-VALIDATING widget tests \"flutter test\" on \"$example_descriptor_generated_program\".
echo         It validates, one by one, that the screenshots generated in Step 2 tests are unchanged.
echo
bash -x "$example_descriptor_generated_program" \
        "flutter test $noPub" \
        " test/screenshot_check_test.dart"
