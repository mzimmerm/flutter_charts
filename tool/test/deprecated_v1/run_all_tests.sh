#!/bin/bash

# Bash with clean: Run all tests of all examples:
#   d1=$(date +%s); flutter clean; flutter pub upgrade; flutter pub get; tool/test/deprecated_v1/run_all_tests.sh; echo TOOK $(($(date +%s) - $d1)) seconds

# Eshell with clean: Run all tests of all examples:
#   setq d1 (string-to-number (format-time-string "%s")); flutter clean; flutter pub upgrade; flutter pub get; tool/test/deprecated_v1/run_all_tests.sh; ; setq d2 (string-to-number (format-time-string "%s")); echo "TOOK $(- d2 d1) seconds"

# No clean: Run one example:
# tool/test/deprecated_v1/run_all_tests.sh ex31SomeNegativeValues

set -o errexit

# Run Dart tests (still as 'flutter test') and Flutter widget tests 'flutter test'
tool/test/run_core_dart_and_flutter_widget_tests.sh

# Run tests using old layouter
echo
echo -------------------------------------
echo -------------------------------------
echo Running screenshot differences tests screenshots validation
echo This runs an integration [drive] screenshot create test first, followed by widget test that compares screenshots actual/expected
echo First argument is $1

tool/test/deprecated_v1/integration_test_create_then_validate_screenshots.sh firstRun ex900ErrorFixUserDataAllZero
tool/test/deprecated_v1/integration_test_create_then_validate_screenshots.sh nextRun

# Run tests using the new layouter
tool/test/deprecated_v1/run_core_new_integration_tests.sh
