#!/bin/bash

# Runs, on device or in emulator, the single example chart in examples/main_run_doc_example.dart

set -o errexit

if [[ "$1" == "--help" ]]; then
  echo Usage: $0 [exampleEnum]
  exit 0
fi

# if [[ -z "$1" ]]; then
#   echo Usage:
#   echo    $0 ex31_barChart_column_nonStacked_newAutoLayouter
#   echo    NOT: $0 allSupported
#   echo    NOT: $0 absoluteMinimumNew
#   echo
#   echo A single argument giving an example to run is missing, defaulting to ex31_barChart_column_nonStacked_newAutoLayouter.
#   exampleEnum="ex31_barChart_column_nonStacked_newAutoLayouter"
# else
#   exampleEnum="$1"
# fi

#  This script can only run from project top directory.
if [ -z "$(find . -maxdepth 1 -type d -name integration_test)" ]; then 
  echo Execution directory must be from project top directory. Failed the test for presence of directory integration_test, exiting.
  exit 1
fi

# To quit the running example, type 'q' on the command line.

# flutter run \
#   --dart-define=EXAMPLES_DESCRIPTORS="$exampleEnum" \
#   example/main_run_doc_example.dart

flutter run \
  example/main_run_doc_example.dart



