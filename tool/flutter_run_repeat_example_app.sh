#!/bin/bash

# If Android AVD emulator is not running, starts one.
# Then, repeatedly runs the example app for data specified in ExamplesEnum.
# More precisely, for all values in ExamplesEnum, runs
#   flutter run --device-id=$device_id" "example1/lib/main.dart"

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

# # Run the examples one after another. Ignore errors, as manual device-swipe-up of program would exist script
# while read example; do
#   echo Running chart for "$example"
#   # flutter run --device-id="$device_id" --dart-define=EXAMPLE_TO_RUN=ex_5_0_StocksRankedOnYWithNegatives_DataYLabels_UserColors --dart-define=CHART_TYPE_TO_SHOW=VerticalBarChart example1/lib/main.dart
#   echo Running command: flutter run --device-id="$device_id" $example example1/lib/main.dart 
#   flutter run --device-id="$device_id" $example  example1/lib/main.dart
#   echo Next chart
#   set +e
# done < <(dart run example1/lib/examples_descriptor.dart)

# todo-00 make tmp a tmp file
dart run example1/lib/examples_descriptor.dart > ~/tmp/run_examples.sh
chmod u+x ~/tmp/run_examples.sh
bash -x ~/tmp/run_examples.sh "flutter run --device-id=$device_id" "example1/lib/main.dart"




