#!/bin/bash

# The section below shows how to run this test script - dart unit tests, flutter widget tests (both in directory 'test'),
#   and flutter integration tests (=driver tests) (in directory 'integration_test'

# Bash with clean: Run all tests of all examples:
#   d1=$(date +%s); flutter clean; flutter pub upgrade; flutter pub get; tool/test/run_all_tests.sh; echo TOOK $(($(date +%s) - $d1)) seconds

# Eshell with clean: Run all tests of all examples:
#   setq d1 (string-to-number (format-time-string "%s")); flutter clean; flutter pub upgrade; flutter pub get; tool/test/run_all_tests.sh; ; setq d2 (string-to-number (format-time-string "%s")); echo "TOOK $(- d2 d1) seconds"

# No clean: Run one example:
# tool/test/run_all_tests.sh ex31SomeNegativeValues

set -e

echo
echo -------------------------------------
echo -------------------------------------
echo Running Dart files testing, which is still run with Flutter
flutter test test/util/util_labels_test.dart
flutter test test/util/extensions_dart_test.dart
flutter test test/util/util_dart_test.dart
flutter test test/chart/layouter_one_dimensional_test.dart

echo
echo -------------------------------------
echo -------------------------------------
echo Running Flutter widget tests
flutter test test/widget_test.dart

echo
echo -------------------------------------
echo -------------------------------------
echo RERUNNING All Flutter tests, showing all names. The option --reporter expanded is showing names.
flutter test --reporter expanded

echo
echo -------------------------------------
echo -------------------------------------
echo Running screenshot differences tests screenshots validation
echo This runs an integration [drive] screenshot create test first, followed by widget test that compares screenshots actual/expected
echo First argument is $1
tool/test/integration_test_validate_screenshots.sh firstRun ex900ErrorFixUserDataAllZero
tool/test/integration_test_validate_screenshots.sh nextRun

echo
echo -------------------------------------
echo -------------------------------------
echo Running screenshot actual/expected test for NEW LAYOUT
USE_OLD_DATA_CONTAINER=false tool/test/integration_test_validate_screenshots.sh nextRun ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded
USE_OLD_DATA_CONTAINER=false tool/test/integration_test_validate_screenshots.sh nextRun ex31SomeNegativeValues    verticalBarChart
