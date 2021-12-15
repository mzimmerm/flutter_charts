#!/bin/bash

# This script runs integration test in integration_test/screenshot_create_test.dart
#   which compares screenshots captured                  from the example app in "example1/lib/main.dart",
#   to screenshots expected, captured before any changes from the example app in "example1/lib/main.dart".

if [[ "$1" == "--help" ]]; then
  echo Usage: integration_test_validate_screenshots.sh
  exit 1 
fi

if [[ -n "$1" ]]; then
  exampleEnum=$1
  echo
  echo Assuming you asking to run only one test, given by ExamplesEnum: "$exampleEnum"
  echo
fi  
  
#  This script can only run from project top directory.
if [ -z "$(find . -maxdepth 1 -type d -name integration_test)" ]; then 
  echo Execution directory must be from project top directory. Failed the test for presence of directory integration_test, exiting.
  exit 1
fi


# Source script which starts emulator and generates program named $examples_descriptor_generated_program. 
#   This program can run either integration test (fluter driver) or the app (flutter run), depending on parameters.
# See the sourced script below for details of variable and contents of $examples_descriptor_generated_program.
source tool/test/start_emulator_and_generate_examples_descriptor.sh "$exampleEnum"
examples_descriptor_generated_program=$examples_descriptor_generated_program

echo
echo -------------------------------------
echo Running integration test [flutter drive] for screenshots, by running the example app for each set of data at a time.
bash -x "$examples_descriptor_generated_program" \
        "flutter  drive" \
        " --driver=test_driver/integration_test.dart --target=integration_test/screenshot_create_test.dart"

echo
echo -------------------------------------
echo Running flutter widget test which validates the screenshots generated by the aboce integration test are unchanged. 
bash -x "$examples_descriptor_generated_program" \
        "flutter test" \
        " test/screenshot_check_test.dart"
