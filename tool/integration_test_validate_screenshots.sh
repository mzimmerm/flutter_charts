#!/bin/bash

# This script runs integration test in integration_test/screenshot_test.dart
#   which compares screenshots captured                  from the example app in "example1/lib/main.dart",
#   to screenshots expected, captured before any changes from the example app in "example1/lib/main.dart".

if [[ "$1" == "--help" ]]; then
  echo Usage: integration_test_validate_screenshots.sh
  exit 1 
fi
  
#  This script can only run from project top directory.
if [ -z "$(find . -maxdepth 1 -type d -name integration_test)" ]; then 
  echo Execution directory must be from project top direcroty. Failed the test for presence of directory integration_test, exiting.
  exit 1
fi

# Source script which starts emulator and generates program named ~/tmp/run_examples.sh. 
#   This program runs "flutter drive" integration test.
# See the sourced script usage for details of ~/tmp/run_examples.sh.
source tool/start_emulator_and_generate_examples_descriptor.sh


# todo-00 make tmp a tmp file

echo Executing integration test [flutter drive] by repeatedly running the example app for each set of data at a time.
bash -x ~/tmp/run_examples.sh \
        "flutter  drive" \
        " --driver=test_driver/integration_test.dart --target=integration_test/screenshot_test.dart"

bash -x ~/tmp/run_examples.sh \
        "flutter test" \
        " test/screenshot_check_test.dart"


