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

# ------------------------------------------
# ex75 - only positives : barChart
CHART_LAYOUTER=newAutoLayouter CHART_ORIENTATION=column CHART_STACKING=stacked    tool/test/integration_test_create_then_validate_screenshots.sh firstRun ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded  barChart
CHART_LAYOUTER=newAutoLayouter CHART_ORIENTATION=column CHART_STACKING=nonStacked tool/test/integration_test_create_then_validate_screenshots.sh nextRun  ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded  barChart

CHART_LAYOUTER=newAutoLayouter CHART_ORIENTATION=row    CHART_STACKING=stacked    tool/test/integration_test_create_then_validate_screenshots.sh nextRun  ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded  barChart
CHART_LAYOUTER=newAutoLayouter CHART_ORIENTATION=row    CHART_STACKING=nonStacked tool/test/integration_test_create_then_validate_screenshots.sh nextRun  ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded  barChart

# ex75 - only positives : lineChart, only nonStacked
# CHART_LAYOUTER=newAutoLayouter CHART_ORIENTATION=column CHART_STACKING=stacked    tool/test/integration_test_create_then_validate_screenshots.sh nextRun ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded  lineChart
CHART_LAYOUTER=newAutoLayouter CHART_ORIENTATION=column CHART_STACKING=nonStacked tool/test/integration_test_create_then_validate_screenshots.sh nextRun ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded  lineChart

# CHART_LAYOUTER=newAutoLayouter CHART_ORIENTATION=row    CHART_STACKING=stacked    tool/test/integration_test_create_then_validate_screenshots.sh nextRun  ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded  lineChart
CHART_LAYOUTER=newAutoLayouter CHART_ORIENTATION=row    CHART_STACKING=nonStacked tool/test/integration_test_create_then_validate_screenshots.sh nextRun  ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded  lineChart

# ------------------------------------------
# ex31 - positives and negatives - barChart
CHART_LAYOUTER=newAutoLayouter CHART_ORIENTATION=column CHART_STACKING=stacked    tool/test/integration_test_create_then_validate_screenshots.sh nextRun  ex31SomeNegativeValues                                                         barChart
CHART_LAYOUTER=newAutoLayouter CHART_ORIENTATION=column CHART_STACKING=nonStacked tool/test/integration_test_create_then_validate_screenshots.sh nextRun  ex31SomeNegativeValues                                                         barChart

CHART_LAYOUTER=newAutoLayouter CHART_ORIENTATION=row    CHART_STACKING=stacked    tool/test/integration_test_create_then_validate_screenshots.sh nextRun  ex31SomeNegativeValues                                                         barChart
CHART_LAYOUTER=newAutoLayouter CHART_ORIENTATION=row    CHART_STACKING=nonStacked tool/test/integration_test_create_then_validate_screenshots.sh nextRun  ex31SomeNegativeValues                                                         barChart

# ex31 - positives and negatives - lineChart, only nonStacked
# CHART_LAYOUTER=newAutoLayouter CHART_ORIENTATION=column CHART_STACKING=stacked    tool/test/integration_test_create_then_validate_screenshots.sh nextRun  ex31SomeNegativeValues                                                         lineChart
CHART_LAYOUTER=newAutoLayouter CHART_ORIENTATION=column CHART_STACKING=nonStacked tool/test/integration_test_create_then_validate_screenshots.sh nextRun  ex31SomeNegativeValues                                                         lineChart

# CHART_LAYOUTER=newAutoLayouter CHART_ORIENTATION=row    CHART_STACKING=stacked    tool/test/integration_test_create_then_validate_screenshots.sh nextRun  ex31SomeNegativeValues                                                         lineChart
CHART_LAYOUTER=newAutoLayouter CHART_ORIENTATION=row    CHART_STACKING=nonStacked tool/test/integration_test_create_then_validate_screenshots.sh nextRun  ex31SomeNegativeValues                                                         lineChart

