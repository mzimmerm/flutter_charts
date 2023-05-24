#!/bin/bash

# Runs all tests except screenshot tests

set -o errexit

echo
echo -------------------------------------
echo -------------------------------------
echo Running Dart files testing, which is still run with Flutter: flutter test test/util/util_labels_test.dart - etc..
flutter test test/util/extensions_dart_test.dart
flutter test test/util/util_dart_test.dart
flutter test test/util/util_flutter_test.dart
flutter test test/util/util_labels_test.dart
flutter test test/chart/layouter_one_dimensional_test.dart
flutter test test/util/vector/vector_test.dart
flutter test test/util/function_test.dart

echo
echo -------------------------------------
echo -------------------------------------
echo Running Flutter widget tests: flutter test test/widget_test.dart
flutter test test/widget_test.dart

echo
echo -------------------------------------
echo -------------------------------------
echo RERUNNING All Flutter widget tests, showing all names: flutter test --reporter expanded
flutter test --reporter expanded
