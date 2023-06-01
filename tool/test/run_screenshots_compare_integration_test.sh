#!/bin/bash

# Run test which generates screenshots of all examples named in the passed arguments
# followed by screenshot expected/actual comparison for the same set of examples.

set -o errexit

if [[ $# -eq 0 ]]; then
  echo 'Specify at least one example or group from the command line, exiting'
  exit 1
fi

examplesDescriptors="$@"

# Start emulator
tool/test/start_emulator.sh

flutter drive \
  --dart-define=EXAMPLES_DESCRIPTORS="$examplesDescriptors" \
  --driver=test_driver/integration_test.dart  \
  --target=integration_test/screenshot_create_test.dart

flutter test \
  --dart-define=EXAMPLES_DESCRIPTORS="$examplesDescriptors" \
  test/screenshot_validate_test.dart
