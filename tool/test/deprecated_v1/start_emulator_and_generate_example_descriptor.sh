#!/bin/bash

# Generates a program that can be used to run or test all examples 
#   defined in enum 'ExampleEnum'.
#
# Should be 'sourced', as it results in setting an environment variable which contains a program name,
#   which the calling script can run.
#
# In more detail, this script does the following:
#   - If Android AVD emulator is not running, starts one.
#   - Next, uses the program 
#     'dart run lib/src/chart/util/example_descriptor.dart'
#   to generate a temp script, which name is placed in the variable named
#     'example_descriptor_generated_program'
#   The program $example_descriptor_generated_program
#     can be executed from the script sourcing this script, 
#     to run the or tests all examples declared in ExampleEnum.

# Input $1: ExampleEnum value, for example ex10RandomData.
#           If empty or not set, all examples are included in the generated run.
# Output: variable name 'example_descriptor_generated_program', which contains the name of the
#          generated program 

isFirstRun=$1
exampleEnum=$2
chartTypeEnum=$3
chartOrientation=$4
chartStacking=$5
isUseOldLayouter=$6

# if [[ $isFirstRun == true ]]; then
tool/test/start_emulator.sh
# fi

# Define the name of the program which the scripts sourcing this file can execute.
example_descriptor_generated_program=test/tmp/example_descriptor_generated_program_$RANDOM.sh

# Dart run example_descriptor.dart which generates a script with dart_defines.
echo Running \"dart run lib/src/chart/util/example_descriptor.dart \'"$exampleEnum"\' \'"$chartTypeEnum"\'  \'"$chartOrientation"\' \'"$chartStacking"\' \'"$isUseOldLayouter"\'\"
echo   which creates $example_descriptor_generated_program

echo "# Sample of how this runs:"  > $example_descriptor_generated_program
echo "# flutter drive \
  --dart-define=EXAMPLE_TO_RUN=ex75 \
  --dart-define=CHART_TYPE=barChart \
  --dart-define=CHART_ORIENTATION=row \
  --dart-define=CHART_STACKING=stacked \
  --dart-define=CHART_LAYOUTER=newAutoLayouter \
  --driver=test_driver/integration_test.dart --target=integration_test/deprecated_v1/screenshot_create_deprecated_v1_test.dart"  >> $example_descriptor_generated_program

dart run lib/src/chart/util/example_descriptor.dart \
  "$exampleEnum" \
  "$chartTypeEnum" \
  "$chartOrientation" \
  "$chartStacking" \
  "$isUseOldLayouter" >> $example_descriptor_generated_program

chmod u+x $example_descriptor_generated_program




