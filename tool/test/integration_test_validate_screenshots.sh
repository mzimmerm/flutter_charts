#!/bin/bash

# This script runs a single or all examples in the example app in "example/lib/main.dart",
#   captures a screenshot from each example, then runs a follow-up process which
#   validates that the captured screenshot is the same as an expected screenshot (taken earlier and validated).
# In more detail, this script runs in 3 steps
#   1. Sources a program-generating script 'start_emulator_and_generate_examples_descriptor.sh'
#      which creates a program executed in step 2. This program has multiple lines, 
#      each line allows to run one example from 'ExamplesEnum'. 
#   2. For each line in the above script (that is for each example in 'ExamplesEnum'), runs integration test 
#        'flutter drive --target integration_test/screenshot_create_test.dart'
#   3. For each line in the above script (that is for each example in 'ExamplesEnum'), runs a flutter widget test
#        'flutter test  test/screenshot_check_test.dart'
#      which compares
#         - screenshot captured in step 2 with
#         - screenshot expected, captured before any changes

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

echo
echo -------------------------------------
echo Step 2: Running SCREENSHOTS-GENERATING integration tests \"flutter drive\" on \"$examples_descriptor_generated_program\".
echo         on file \"screenshot_create_test.dart\".
echo         This generates screenshots for all examples,
echo         by running the tmp program \"$examples_descriptor_generated_program\"
echo         generated by \"examples_descriptor.dart\"
echo
bash -x "$examples_descriptor_generated_program" \
        "flutter  drive" \
        " --driver=test_driver/integration_test.dart --target=integration_test/screenshot_create_test.dart"

echo
echo -------------------------------------
echo Step 3: Running SCREENSHOTS-VALIDATING widget tests \"flutter test\" on \"$examples_descriptor_generated_program\".
echo         It validates, one by one, that the screenshots generated in Step 2 tests are unchanged.
echo
bash -x "$examples_descriptor_generated_program" \
        "flutter test" \
        " test/screenshot_check_test.dart"
