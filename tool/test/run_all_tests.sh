#!/bin/bash

# Usage example:
#   tool/test/run_all_tests.sh \
#   --auto_layout="chartsGalleryNew layoutsGalleryNew convertedToNew"
#   --coded_layout="oldFailingInNew"

# This script runs all unit tests in this 'flutter_charts' library,
# as well as the integration tests named in arguments values of '--auto_layout' and '--coded_layout'.
# The argument values can be either individual test names, or names of test groups.
#   - The test group names must be defined in 'example_descriptor.dart'
#     - Possible group names:
#       - 'minimumNew'
#       - 'chartsGalleryNew'
#       - 'layoutsGalleryNew'
#       - 'minimumOld'
#       - 'origAllTestedOld'
#       - 'minimum'
#       - 'allSupported'
#   - The individual test names must adhere to naming convention. A few examples:
#     - 'ex31_barChart_column_stacked_newAutoLayouter'
#     - 'ex75_lineChart_row_nonStacked_newAutoLayouter'

# See 'tool/test/run_screenshots_create_then_validate_integration_test.sh' for detail
# description of the integration tests structure.

# This script can be used as part of other bash commands.
# A few useful examples of this:
#
# In bash with clean: Run all tests of all examples:
#   d1=$(date +%s); flutter clean; flutter pub upgrade; flutter pub get; tool/test/run_all_tests.sh absoluteMinimumNew; echo TOOK $(($(date +%s) - $d1)) seconds
#
# In eshell with clean: Run all tests of all examples:
#   setq d1 (string-to-number (format-time-string "%s")); flutter clean; flutter pub upgrade; flutter pub get; tool/test/run_all_tests.sh absoluteMinimumNew; ; setq d2 (string-to-number (format-time-string "%s")); echo "TOOK $(- d2 d1) seconds"
#
# In bash, no clean: Run one example:
# tool/test/run_all_tests.sh ex31_barChart_column_stacked_newAutoLayouter ex75_lineChart_row_nonStacked_newAutoLayouter

set -o errexit

# Run Dart tests (still as 'flutter test') and Flutter widget tests 'flutter test'
tool/test/run_core_dart_and_flutter_widget_tests.sh

# Run on-device-driven    'flutter drive' integration test 'screenshot_create_test.dart',
# followed by on-computer 'flutter test'  unit test        'screenshot_validate_test.dart'.
tool/test/run_screenshots_create_then_validate_integration_test.sh "$@"


