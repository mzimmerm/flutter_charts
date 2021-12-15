#!/bin/bash

# If Android AVD emulator is not running, starts one.
# Then, uses the program 
#    dart run example1/lib/src/util/examples_descriptor.dart
# to generate a temp script, which name is placed to variable named
#    $examples_descriptor_generated_program
# $examples_descriptor_generated_program can be called from another script to repeatedly run the example app for data in ExamplesEnum.

# Input $1: ExamplesEnum value, for example ex10RandomData. 
#           If empty or not set, all example screenshots are tested.
# Output: variable examples_descriptor_generated_program

exampleEnum=$1

# This is the AVD emulator we request to exist
emulator_used="Nexus_6_API_29_2"

echo Check if emulator exists
if ! flutter emulators  2>/dev/null | grep --quiet "$emulator_used "; then
  echo "Emulator $emulator_used does not exist. Please create it, our integration tests depend on it. Exiting"
  exit 1
fi

echo Check if the emulator named $emulator_used is connected to a running device.
# The only way to find out is to run ps, searching for the device name,
#   as "flutter devices" list only the short device name such as e3565
if ! ps -alef | grep "$emulator_used" | grep -v grep ; then
  echo No AVD devices running using the emulator $emulator_used. Launching the emulator.
  flutter emulators --launch "$emulator_used"
  echo Sleep 20 to give the emulator time to start fully.
  sleep 20
  echo The AVD emulator $emulator_used succesfully launched.
else
  echo The emulator $emulator_used appears running and connected.
fi

# Sleep for a bit and check that SOME device is running
sleep 1
if ! flutter devices  2>/dev/null | grep --quiet "emulator-"; then
  echo "Unexpected error: flutter devices is telling us that no emulators are connected to a device. Exiting"
  exit 1
fi

echo Checking processes for running emulator name.
device_id=$(flutter devices 2>/dev/null | grep "emulator-" | sed 's/.*\(emulator\-[0-9]\+\).*/\1/')
echo Emulator $emulator_used is running as device_id="$device_id".

# Define the name of the program which the scripts sourcing this file can execute.
examples_descriptor_generated_program=test/tmp/examples_descriptor_generated_program_$RANDOM.sh

# Dart run examples_descriptor.dart which generates a script with dart_defines.
echo Running dart run example1/lib/src/util/examples_descriptor.dart 
echo   to create $examples_descriptor_generated_program
dart run example1/lib/src/util/examples_descriptor.dart "$exampleEnum" > $examples_descriptor_generated_program

chmod u+x $examples_descriptor_generated_program

# Generated script $examples_descriptor_generated_program contains list of lines, one line looks like this
#    $1 --dart-define=EXAMPLE_TO_RUN=ex_1_0_RandomData --dart-define=CHART_TYPE_TO_SHOW=LineChart $2




