/// Flutter test which compares expected screenshots to actual screenshots
/// for the requested example.
///
/// The requested example is given by the app method [requestedExampleToRun], which
/// in turn is given by the `--dart-define` passed environment to the `flutter test` command.
///
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

import 'test_util.dart';

import 'package:flutter_charts/src/chart/util/example_descriptor.dart'
    show ExampleDescriptor;

void main() {

  // Extract descriptors for examples to run. examplesDescriptors must be pushed via --dart-define=EXAMPLES_DESCRIPTORS.
  List<ExampleDescriptor> examplesDescriptors = ExampleDescriptor.extractExamplesDescriptorsFromDartDefine(
    message: 'main() of screenshot_validate_test_new.dart',
  );

  test('after screenshot integration, test for sameness', () {
    // Find the command-line provided enums which define chart data, options and type to run.
    // The app.requestedExampleToRun creates the enums from --dart-define arguments for
    //   EXAMPLE_TO_RUN, CHART_TYPE, CHART_ORIENTATION, and CHART_LAYOUTER.
    //   passed to 'flutter test this-file.dart', and returns them in Tuple5.

    for (var exampleDescriptor in examplesDescriptors) {
      // todo-00-next : add comments and cleanup, add printouts to make clear test progress.
      // todo-00-done : ExampleDescriptor exampleDescriptor = ExampleDescriptor.requestedExampleToRun();

      print(' ############ Running exampleDescriptor=$exampleDescriptor');

      var screenshotPaths = ScreenshotPaths(exampleDescriptor: exampleDescriptor);
      String expectedScreenshotPath = screenshotPaths.expectedScreenshotPath;
      String screenshotPath = screenshotPaths.actualScreenshotPath;

      // Flag controls if this test runs 'expect'.
      // Set to false to generate initial validated screenshots.
      bool runExpect = true;

      if (runExpect && !ExampleDescriptor.isExampleWithRandomData(exampleDescriptor)) {
        File expectedFile = File(expectedScreenshotPath);
        File actualFile = File(screenshotPath);

        // Compare the screenshot just generated with one that was stored as expected.
        expectSync(
          expectedFile.readAsBytesSync(),
          actualFile.readAsBytesSync(),
        );
      }
    }
  });
}
