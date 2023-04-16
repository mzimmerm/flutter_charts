#!/bin/bash

# Runs representative tests - dart unit tests, flutter widget tests (both in directory 'test'),
#   and a minimum set of flutter integration tests (=driver tests) (in directory 'integration_test'

# Copied from run_all_tests.sh

# Run mini set of flutter integration tests in bash using:
#   d1=$(date +%s); tool/test/run_representative_mini_tests.sh; echo TOOK $(($(date +%s) - $d1)) seconds

# Run mini set of flutter integration tests in eshell using:
#   setq d1 (string-to-number (format-time-string "%s")); tool/test/run_representative_mini_tests.sh ; setq d2 (string-to-number (format-time-string "%s")); echo "TOOK $(- d2 d1) seconds"

# with clean, add before tool/test/run: ; flutter clean; flutter pub upgrade; flutter pub get;

# To run one example:
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
echo RERUNNING All Flutter tests, showing all names
flutter test --reporter expanded

echo
echo -------------------------------------
echo -------------------------------------
echo Running representative MINI screenshot validations
echo Runs an integration [drive] screenshot create test first, followed by widget test that compares screenshots actual/expected
echo   firstRun does --pub, nextRun ignores it.

tool/test/integration_test_validate_screenshots.sh firstRun ex900ErrorFixUserDataAllZero
tool/test/integration_test_validate_screenshots.sh nextRun ex30AnimalsBySeasonWithLabelLayoutStrategy
tool/test/integration_test_validate_screenshots.sh nextRun ex35AnimalsBySeasonNoLabelsShown
tool/test/integration_test_validate_screenshots.sh nextRun ex40LanguagesWithYOrdinalUserLabelsAndUserColors
tool/test/integration_test_validate_screenshots.sh nextRun ex52AnimalsBySeasonLogarithmicScale
# tool/test/integration_test_validate_screenshots.sh nextRun ex60LabelsIteration2 #
tool/test/integration_test_validate_screenshots.sh nextRun ex60LabelsIteration3
# tool/test/integration_test_validate_screenshots.sh nextRun ex60LabelsIteration4
tool/test/integration_test_validate_screenshots.sh nextRun ex70AnimalsBySeasonLegendIsColumnStartLooseItemIsRowStartLoose
# tool/test/integration_test_validate_screenshots.sh nextRun ex71AnimalsBySeasonLegendIsColumnStartTightItemIsRowStartTight #
tool/test/integration_test_validate_screenshots.sh nextRun ex72AnimalsBySeasonLegendIsRowCenterLooseItemIsRowEndLoose
# tool/test/integration_test_validate_screenshots.sh nextRun ex73AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTight #
# tool/test/integration_test_validate_screenshots.sh nextRun ex74AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightSecondGreedy #
# tool/test/integration_test_validate_screenshots.sh nextRun ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded #
tool/test/integration_test_validate_screenshots.sh nextRun ex76AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenAligned

echo
echo -------------------------------------
echo -------------------------------------
echo Running screenshot actual/expected test for NEW LAYOUT
USE_OLD_DATA_CONTAINER=false tool/test/integration_test_validate_screenshots.sh nextRun ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded
USE_OLD_DATA_CONTAINER=false tool/test/integration_test_validate_screenshots.sh nextRun ex31SomeNegativeValues    verticalBarChart

# todo-00-last : Add everywhere, --dart-define=CHART_ORIENTATION=column, row
#  - search all places --dart-define=CHART_TYPE_TO_SHOW=verticalBarChart is used
# How to run: USE THE SAME METHOD AS USE_OLD_DATA_CONTAINER, pick up the same way in scripts and code??? code is questionable - needs to be available in viewMaker.
# I suppose, if set as --dart-define, override what user set as argument in ViewMakre constructor??