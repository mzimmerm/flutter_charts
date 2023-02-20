#!/bin/bash

# Runs one screenshot test, with the name given in input

# Input $1: ExamplesEnum value, for example ex10RandomData. 
if [[ $# -ne 1 ]]; then
  echo Expected one argument, an ExamplesEnum value, for example ex10RandomData. Exiting.
  exit 1
fi

exampleEnum=$1

echo
echo -------------------------------------
echo Running wrapper around Flutter integration tests for screenshots
echo This runs an integration [drive] screenshot create test first, followed by widget screenshot check test
tool/test/integration_test_validate_screenshots.sh "$exampleEnum"
