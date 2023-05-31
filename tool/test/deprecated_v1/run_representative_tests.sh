#!/bin/bash

set -o errexit

# Run Dart tests (still as 'flutter test') and Flutter widget tests 'flutter test'
tool/test/run_core_dart_and_flutter_widget_tests.sh

echo
echo -------------------------------------
echo -------------------------------------
echo Running representative screenshot validations
echo Runs an integration [drive] screenshot create test first, followed by widget test that compares screenshots actual/expected
echo   firstRun does --pub, nextRun ignores it.

tool/test/deprecated_v1/integration_test_create_then_validate_screenshots.sh firstRun ex900ErrorFixUserDataAllZero
tool/test/deprecated_v1/integration_test_create_then_validate_screenshots.sh nextRun ex30AnimalsBySeasonWithLabelLayoutStrategy
tool/test/deprecated_v1/integration_test_create_then_validate_screenshots.sh nextRun ex35AnimalsBySeasonNoLabelsShown
tool/test/deprecated_v1/integration_test_create_then_validate_screenshots.sh nextRun ex40LanguagesWithYOrdinalUserLabelsAndUserColors
tool/test/deprecated_v1/integration_test_create_then_validate_screenshots.sh nextRun ex52AnimalsBySeasonLogarithmicScale
tool/test/deprecated_v1/integration_test_create_then_validate_screenshots.sh nextRun ex60LabelsIteration2 #
tool/test/deprecated_v1/integration_test_create_then_validate_screenshots.sh nextRun ex60LabelsIteration3
tool/test/deprecated_v1/integration_test_create_then_validate_screenshots.sh nextRun ex60LabelsIteration4
tool/test/deprecated_v1/integration_test_create_then_validate_screenshots.sh nextRun ex70AnimalsBySeasonLegendIsColumnStartLooseItemIsRowStartLoose
tool/test/deprecated_v1/integration_test_create_then_validate_screenshots.sh nextRun ex71AnimalsBySeasonLegendIsColumnStartTightItemIsRowStartTight #
tool/test/deprecated_v1/integration_test_create_then_validate_screenshots.sh nextRun ex72AnimalsBySeasonLegendIsRowCenterLooseItemIsRowEndLoose
tool/test/deprecated_v1/integration_test_create_then_validate_screenshots.sh nextRun ex73AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTight #
tool/test/deprecated_v1/integration_test_create_then_validate_screenshots.sh nextRun ex74AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightSecondGreedy #
tool/test/deprecated_v1/integration_test_create_then_validate_screenshots.sh nextRun ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded #
tool/test/deprecated_v1/integration_test_create_then_validate_screenshots.sh nextRun ex76AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenAligned

# Run tests using the new layouter
tool/test/deprecated_v1/run_core_new_integration_tests.sh
