#!/bin/bash

# Runs one screenshot test, with the name given in input.

# ONLY a wrapper for tool/test/integration_test_create_then_validate_screenshots.sh

# Input $1: ExamplesEnum value, for example ex10RandomData. 
if [[ $# -ne 1 ]]; then
  echo Expected one argument, an ExamplesEnum value, for example ex10RandomData. Exiting.
  exit 1
fi

exampleEnum=$1

echo
echo -------------------------------------
echo -------------------------------------
echo Running wrapper around Flutter integration tests for screenshots validation
echo This runs an integration [drive] screenshot create test first, followed by widget test that compares screenshots actual/expected
tool/test/integration_test_create_then_validate_screenshots.sh "firstRun" "$exampleEnum"

# Example of new/old, running only screenshot-create test:
#   IS_USE_OLD_LAYOUTER=true tool/test/run_one_create_then_validate_screenshot_test.sh ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded