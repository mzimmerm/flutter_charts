#!/bin/bash

# Runs the passed example or all examples in 'example/lib/main.dart'.
# If an example name is passed, it must be an existing allowed ExampleEnum name

set -o errexit

echo
echo -------------------------------------
echo Executes 'flutter run' for the passed exampleEnum or for all examples in ExampleEnum
echo Code borrowed from tool/test/integration_test_create_then_validate_screenshots.sh


if [[ "$1" == "--help" ]]; then
  echo Usage: $0 [exampleEnum]
  exit 1 
fi

if [[ -n "$1" ]]; then
  exampleEnum=$1
  echo
  echo Assuming you asking to run only one app, given by ExampleEnum: "$exampleEnum"
  echo
fi  
  
#  This script can only run from project top directory.
if [ -z "$(find . -maxdepth 1 -type d -name integration_test)" ]; then 
  echo Execution directory must be from project top directory. Failed the test for presence of directory integration_test, exiting.
  exit 1
fi

echo
echo -------------------------------------
echo Source script starts emulator and generates program test/tmp/example_descriptor_generated_program_1234.sh.
echo This generated program can run either integration test \(flutter drive\) or the app \(flutter run\), depending on parameters.

#   See the sourced script below for details of variable and contents of $example_descriptor_generated_program.
isFirstRun=true
source tool/test/start_emulator_and_generate_example_descriptor.sh "$isFirstRun" "$exampleEnum"

echo Will run "$example_descriptor_generated_program".
example_descriptor_generated_program=$example_descriptor_generated_program

echo
echo -------------------------------------
echo Running the app with all examples for the example_descriptor.
echo The argument --device-id="$device_id" after flutter run is not needed if only one device is connected.
bash -x "$example_descriptor_generated_program" \
        "flutter  run" \
        " example/lib/main.dart"

