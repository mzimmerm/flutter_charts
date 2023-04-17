#!/bin/bash

set -o errexit

echo
echo -------------------------------------
echo -------------------------------------
echo Running representative MINI screenshot validations
echo Runs an integration [drive] screenshot create test first, followed by widget test that compares screenshots actual/expected
echo   firstRun does --pub, nextRun ignores it.


echo
echo -------------------------------------
echo -------------------------------------
echo Running screenshot actual/expected test for NEW LAYOUT
IS_USE_OLD_LAYOUTER=false CHART_ORIENTATION=column tool/test/integration_test_create_then_validate_screenshots.sh firstRun ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded  verticalBarChart
IS_USE_OLD_LAYOUTER=false CHART_ORIENTATION=row    tool/test/integration_test_create_then_validate_screenshots.sh nextRun  ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded  verticalBarChart
IS_USE_OLD_LAYOUTER=false CHART_ORIENTATION=column tool/test/integration_test_create_then_validate_screenshots.sh nextRun  ex31SomeNegativeValues                                                         verticalBarChart
IS_USE_OLD_LAYOUTER=false CHART_ORIENTATION=row    tool/test/integration_test_create_then_validate_screenshots.sh nextRun  ex31SomeNegativeValues                                                         verticalBarChart
