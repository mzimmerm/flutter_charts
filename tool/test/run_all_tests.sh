#!/bin/bash

# Bash with clean: Run all tests of all examples:
#   d1=$(date +%s); flutter clean; flutter pub upgrade; flutter pub get; tool/test/run_all_tests.sh absoluteMinimumNew; echo TOOK $(($(date +%s) - $d1)) seconds

# Eshell with clean: Run all tests of all examples:
#   setq d1 (string-to-number (format-time-string "%s")); flutter clean; flutter pub upgrade; flutter pub get; tool/test/run_all_tests.sh absoluteMinimumNew; ; setq d2 (string-to-number (format-time-string "%s")); echo "TOOK $(- d2 d1) seconds"

# No clean: Run one example:
# tool/test/run_all_tests.sh ex31_barChart_column_stacked_newAutoLayouter ex75_lineChart_row_nonStacked_newAutoLayouter

# Possible groups:
#  minimumNew
#  allSupportedNew
#  minimumOld
#  allSupportedOld
#  minimum
#  allSupported


set -o errexit

# Run Dart tests (still as 'flutter test') and Flutter widget tests 'flutter test'
tool/test/run_core_dart_and_flutter_widget_tests.sh

# Run screenshot compare tests
tool/test/run_screenshots_compare_integration_test.sh "$@"


