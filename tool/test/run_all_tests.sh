#!/bin/bash

# Runs all tests - dart unit tests, flutter widget tests (both in directory 'test'), 
#   and flutter integration tests (=driver tests) (in directory 'integration_test'

set -e

echo
echo -------------------------------------
echo Running Dart files testing, which is still run with Flutter
flutter test test/util/y_labels_test.dart
flutter test test/util/string_extension_test.dart
flutter test test/util/util_dart_test.dart

echo
echo -------------------------------------
echo Running Flutter widget tests
flutter test test/widget_test.dart

echo
echo -------------------------------------
echo Running wrapper around Flutter integration tests for screenshots
echo This runs an integration [drive] screenshot create test first, followed by widget screenshot check test
tool/test/integration_test_validate_screenshots.sh
