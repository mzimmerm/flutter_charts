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

if [[ $isFirstRun == true ]]; then
  tool/test/start_emulator.sh

# todo-00-done  # This is the AVD emulator we request to exist
# todo-00-done  emulator_used="Nexus_6_API_33"
# todo-00-done  # old: emulator_used="Nexus_6_API_29_2"
# todo-00-done
# todo-00-done  echo Check if emulator exists
# todo-00-done  if ! flutter emulators  2>/dev/null | grep --quiet "$emulator_used "; then
# todo-00-done    echo "Emulator $emulator_used does not exist. Please create it, our integration tests depend on it. Exiting"
# todo-00-done    exit 1
# todo-00-done  fi
# todo-00-done
# todo-00-done  echo Check if the emulator named $emulator_used is connected to a running device.
# todo-00-done  # The only way to find out if the emulator is connected is to run ps, searching for the device name.
# todo-00-done  # The potential alternative "flutter devices" lists only the short device name such as e3565.
# todo-00-done  if ! ps -alef | grep "$emulator_used" | grep -v grep ; then
# todo-00-done    echo No AVD devices running using the emulator $emulator_used. Launching the emulator.
# todo-00-done    flutter emulators --launch "$emulator_used"
# todo-00-done    echo Sleep 22 on server to give the emulator time to start fully. Sleep 40 on laptop.
# todo-00-done    sleep 22
# todo-00-done    echo The AVD emulator $emulator_used succesfully launched.
# todo-00-done  else
# todo-00-done    echo The emulator $emulator_used appears running and connected.
# todo-00-done  fi
# todo-00-done
# todo-00-done  # Sleep for a bit and check that SOME device is running
# todo-00-done  sleep 1
# todo-00-done  if ! flutter devices  2>/dev/null | grep --quiet "emulator-"; then
# todo-00-done    echo "Unexpected error: flutter devices is telling us that no emulators are connected to a device. Exiting"
# todo-00-done    exit 1
# todo-00-done  fi
# todo-00-done
# todo-00-done  echo Checking processes for running emulator name.
# todo-00-done  device_id=$(flutter devices 2>/dev/null | grep "emulator-" | sed 's/.*\(emulator\-[0-9]\+\).*/\1/')
# todo-00-done  echo Emulator $emulator_used is running as device_id="$device_id".
fi

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




