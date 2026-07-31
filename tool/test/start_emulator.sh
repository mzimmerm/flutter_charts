#!/bin/bash

#  - If Android AVD emulator is not running, starts one.

  # This is the AVD emulator we request to exist
  # emulators_tested="Nexus_6_API_35"
  emulator_used="medium-phone" # "medium-phone" # "pixel-10-pro-xl" "emulator-5554"
  emulators_tested="medium-phone\|emulator-5554" # Sometimes, emulator_used is launched as emulator-5554

  echo Check if emulator is running
  if ! flutter emulators  2>/dev/null | grep --quiet "$emulators_tested "; then
    echo "No emulator in $emulators_tested exists. Please create one, our integration tests depend on it. Exiting"
    exit 1
  fi

  echo Check if the emulator named $emulator_used is connected to a running device.
  # The only way to find out if the emulator is connected is to run ps, searching for the device name.
  # The potential alternative "flutter devices" lists only the short device name such as e3565.
  # todo-00-delete: if ! ps -alef | grep "$emulators_tested" | grep -v grep ; then
  # if ! pgrep --ignore-case "$emulators_tested"; then # failes to find emulator. May need to change
  if ! ps -alef | grep "$emulators_tested" | grep -v grep ; then
    echo No AVD devices running using the emulator $emulators_tested. Launching the emulator.
    flutter emulators --launch "$emulator_used"
    emulator_wait_sleep=42 # 42 on laptop, 24 on server
    echo Sleeping $emulator_wait_sleep.
    sleep $emulator_wait_sleep
    echo The AVD emulator $emulator_used succesfully launched.
  else
    echo The emulator $emulator_used appears running and connected.
  fi

  # Sleep for a bit and check that SOME device is running
  sleep 5
  if ! flutter devices  2>/dev/null | grep --quiet "emulator-"; then
    echo "Unexpected error: flutter devices is telling us that no emulators are connected to a device. Exiting"
    exit 1
  fi

  echo Checking processes for running emulator name.
  device_id=$(flutter devices 2>/dev/null | grep "emulator-" | sed 's/.*\(emulator\-[0-9]\+\).*/\1/')
  echo Emulator $emulator_used is running as device_id="$device_id".
