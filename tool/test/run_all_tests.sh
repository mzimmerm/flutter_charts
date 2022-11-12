#!/bin/bash

# Runs all tests - dart unit tests, flutter widget tests (both in directory 'test'), 
#   and flutter integration tests (=driver tests) (in directory 'integration_test'

# To run all tests of all examples:
#   d1=$(date +%s); flutter clean; flutter pub upgrade; flutter pub get; tool/test/run_all_tests.sh; echo TOOK $(($(date +%s) - $d1)) seconds

# To run one example:
# tool/test/run_all_tests.sh ex31SomeNegativeValues

set -e

echo
echo -------------------------------------
echo Running Dart files testing, which is still run with Flutter
flutter test test/util/y_labels_test.dart
flutter test test/util/extension_string_test.dart
flutter test test/util/util_dart_test.dart
flutter test test/chart/layouter_one_dimensional_test.dart

echo
echo -------------------------------------
echo Running Flutter widget tests
flutter test test/widget_test.dart

echo
echo -------------------------------------
echo RERUNNING All Flutter tests, showing all names
flutter test --reporter expanded

echo
echo -------------------------------------
echo Running a wrapper around Flutter integration tests for screenshots
echo This runs an integration [drive] screenshot create test first, followed by widget screenshot check test
tool/test/integration_test_validate_screenshots.sh $1
