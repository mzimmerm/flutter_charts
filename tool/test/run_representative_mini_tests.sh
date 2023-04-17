#!/bin/bash

set -o errexit

# Run Dart tests (still as 'flutter test') and Flutter widget tests 'flutter test'
tool/test/run_core_dart_and_flutter_widget_tests.sh

# Run mini set of flutter integration tests in bash using:
#   d1=$(date +%s); tool/test/run_representative_mini_tests.sh; echo TOOK $(($(date +%s) - $d1)) seconds
# Run mini set of flutter integration tests in eshell using:
#   setq d1 (string-to-number (format-time-string "%s")); tool/test/run_representative_mini_tests.sh ; setq d2 (string-to-number (format-time-string "%s")); echo "TOOK $(- d2 d1) seconds"
# with clean, add before tool/test/run: ; flutter clean; flutter pub upgrade; flutter pub get;
# To run one example:
# tool/test/run_all_tests.sh ex31SomeNegativeValues

echo
echo -------------------------------------
echo -------------------------------------
echo Running representative MINI screenshot validations
echo Runs an integration [drive] screenshot create test first, followed by widget test that compares screenshots actual/expected
echo   firstRun does --pub, nextRun ignores it.

tool/test/integration_test_create_then_validate_screenshots.sh firstRun ex900ErrorFixUserDataAllZero
tool/test/integration_test_create_then_validate_screenshots.sh nextRun ex30AnimalsBySeasonWithLabelLayoutStrategy
tool/test/integration_test_create_then_validate_screenshots.sh nextRun ex35AnimalsBySeasonNoLabelsShown
tool/test/integration_test_create_then_validate_screenshots.sh nextRun ex40LanguagesWithYOrdinalUserLabelsAndUserColors
tool/test/integration_test_create_then_validate_screenshots.sh nextRun ex52AnimalsBySeasonLogarithmicScale
# tool/test/integration_test_create_then_validate_screenshots.sh nextRun ex60LabelsIteration2 #
tool/test/integration_test_create_then_validate_screenshots.sh nextRun ex60LabelsIteration3
# tool/test/integration_test_create_then_validate_screenshots.sh nextRun ex60LabelsIteration4
tool/test/integration_test_create_then_validate_screenshots.sh nextRun ex70AnimalsBySeasonLegendIsColumnStartLooseItemIsRowStartLoose
# tool/test/integration_test_create_then_validate_screenshots.sh nextRun ex71AnimalsBySeasonLegendIsColumnStartTightItemIsRowStartTight #
tool/test/integration_test_create_then_validate_screenshots.sh nextRun ex72AnimalsBySeasonLegendIsRowCenterLooseItemIsRowEndLoose
# tool/test/integration_test_create_then_validate_screenshots.sh nextRun ex73AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTight #
# tool/test/integration_test_create_then_validate_screenshots.sh nextRun ex74AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightSecondGreedy #
# tool/test/integration_test_create_then_validate_screenshots.sh nextRun ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded #
tool/test/integration_test_create_then_validate_screenshots.sh nextRun ex76AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenAligned

# Run tests using the new layouter
tool/test/run_core_new_integration_tests.sh
