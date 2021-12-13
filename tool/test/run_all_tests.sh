#!/bin/bash

# Runs all tests - dart unit tests, flutter widget tests (both in directory 'test'), 
#   and flutter integration tests (=driver tests) (in directory 'integration_test'

echo
echo -------------------------------------
echo Running Dart files testing, which is still run with Flutter
flutter test test/src/util/range_test.dart
flutter test test/src/util/string_extension_test.dart

echo
echo -------------------------------------
echo Running Flutter widget tests
flutter test test/flutter_app_widget_test.dart

echo
echo -------------------------------------
echo Running wrapper around Flutter integration tests for screenshots
tool/test/integration_test_validate_screenshots.sh