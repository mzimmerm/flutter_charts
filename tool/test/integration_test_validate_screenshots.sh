#!/bin/bash

# This script runs a SINGLE or ALL examples in the example app in "example/lib/main.dart",
#   captures a screenshot from each example, then optionally runs a follow-up process which
#   validates that the captured screenshot is the same as an expected screenshot (taken earlier and validated).
#
# In more details:
#   - Running a single or all examples is controlled by $1.
#     - If $1 is set, it is assumed to be an example id from 'ExamplesEnum', and the single example is executed
#     - Else, all examples from  'ExamplesEnum' are executed
#   - This script runs in 2 steps
#     1. Sources a program-generating script 'start_emulator_and_generate_examples_descriptor.sh'
#        which creates one or more scripts stored in 'tests/tmp/examples_descriptor_generated_program_RANDOM.sh'
#        (calling each of these scripts tmp-script-program).
#        - Each tmp-script-program:
#          - looks like this:
#            ```sh
#             $1 \
#             --dart-define=EXAMPLE_TO_RUN=ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded \
#             --dart-define=CHART_TYPE_TO_SHOW=verticalBarChart \
#             --dart-define=USE_OLD_DATA_CONTAINER=$USE_OLD_DATA_CONTAINER \
#             $2
#            ```
# todo-00-last : I THINK $2 IS UNUSED THROUGHOUT, VALIDATE AND REMOVE
#          - contains one example from 'ExamplesEnum' or the command line to execute.
#          - provides an argument to an executable $1 which can be 'flutter drive --driver --target',
#            so it (the tmp-script-program) can execute its $1 argument by running itself as:
#              'tmp-script-program flutter drive --target integration_test/screenshot_create_test.dart'
#            so runs the passed executable appended with the rest of its line, e.g.
#            ```sh
#              flutter drive \
#                --driver=test_driver/integration_test.dart \
#                --target=integration_test/screenshot_create_test.dart  \
#                --dart-define=EXAMPLE_TO_RUN=ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded  \
#                --dart-define=CHART_TYPE_TO_SHOW=verticalBarChart  \
#                --dart-define=USE_OLD_DATA_CONTAINER=$USE_OLD_DATA_CONTAINER  \
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
  echo Usage: integration_test_validate_screenshots.sh \[exampleEnum\]
  exit 1 
fi

if [[ -n "$1" ]]; then
  exampleEnum=$1
  chartTypeEnum=$2
  echo
  echo -------------------------------------
  echo Assuming you asking to run only one test, given by ExamplesEnum: "$exampleEnum"
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
echo Step 1: Sources script \"start_emulator_and_generate_examples_descriptor.sh\", which starts emulator
echo         and generates program \"tmp/examples_descriptor_generated_program_$RANDOM.sh\"
echo         that contains command lines to test each example one after another in step 2.
#   This program can run either integration test (flutter driver) or the app (flutter run), depending on parameters.
# See the sourced script below for details of variable and contents of $examples_descriptor_generated_program.
source tool/test/start_emulator_and_generate_examples_descriptor.sh "$exampleEnum" "$chartTypeEnum"
echo Will run "$examples_descriptor_generated_program".
echo
examples_descriptor_generated_program=$examples_descriptor_generated_program

# Run integration test which creates screenshot, then validates it. An example of what the bash -x runs:
#            ```sh
#              flutter drive \
#                --driver=test_driver/integration_test.dart \
#                --target=integration_test/screenshot_create_test.dart  \
#                --dart-define=EXAMPLE_TO_RUN=ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded  \
#                --dart-define=CHART_TYPE_TO_SHOW=verticalBarChart  \
#                --dart-define=USE_OLD_DATA_CONTAINER=$USE_OLD_DATA_CONTAINER  \
#                $2
#            ```
echo
echo -------------------------------------
echo Step 2: Running SCREENSHOTS-GENERATING integration tests \"flutter drive\" on \"$examples_descriptor_generated_program\".
echo         on file \"screenshot_create_test.dart\".
echo         This generates screenshots for all examples,
echo         by running the tmp program \"$examples_descriptor_generated_program\"
echo         generated by \"examples_descriptor.dart\"
echo
bash -x "$examples_descriptor_generated_program" \
        "flutter drive" \
        " --driver=test_driver/integration_test.dart --target=integration_test/screenshot_create_test.dart"

echo
echo -------------------------------------
echo Step 3: Running SCREENSHOTS-VALIDATING widget tests \"flutter test\" on \"$examples_descriptor_generated_program\".
echo         It validates, one by one, that the screenshots generated in Step 2 tests are unchanged.
echo
bash -x "$examples_descriptor_generated_program" \
        "flutter test" \
        " test/screenshot_check_test.dart"
