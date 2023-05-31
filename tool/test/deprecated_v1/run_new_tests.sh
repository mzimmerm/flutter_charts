#!/bin/bash

set -o errexit

# Run Dart tests - still as 'flutter test' - and Flutter widget tests 'flutter test'
tool/test/run_core_dart_and_flutter_widget_tests.sh

# Run tests using the new layouter
tool/test/run_core_new_integration_tests.sh
