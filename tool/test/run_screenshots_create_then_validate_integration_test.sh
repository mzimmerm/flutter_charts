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

# Run the main() in target screenshot_create_test.dart, in context of driver integration_test.dart.
# The main() runs all chart example enums from the EXAMPLES_DESCRIPTORS group (group name passed in "$@").
# The group is expanded to example enums before running each example enum.

flutter drive \
  --dart-define=EXAMPLES_DESCRIPTORS="$examplesDescriptors" \
  --driver=test_driver/integration_test.dart  \
  --target=integration_test/screenshot_create_test.dart

# Run the main() in screenshot_validate_test.dart.
# The main() runs all chart example enums from the group - see above drive test for details of expansion.
flutter test \
  --dart-define=EXAMPLES_DESCRIPTORS="$examplesDescriptors" \
  test/screenshot_validate_test.dart
