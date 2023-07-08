import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

import '../lib/test/src/util/test_util.dart';

import 'package:flutter_charts/src/chart/util/example_descriptor.dart'
    show ExampleDescriptor;

/// Flutter test compares expected screenshots to actual screenshots for all chart examples
/// defined by the '--dart-define' environment variable 'EXAMPLES_DESCRIPTORS',
/// and resolved in [ExampleDescriptor.extractExamplesDescriptorsFromDartDefine].
///
void main() {

  // Extract descriptors for examples to run. examplesDescriptors must be pushed via --dart-define=EXAMPLES_DESCRIPTORS.
  List<ExampleDescriptor> examplesDescriptors = ExampleDescriptor.extractExamplesDescriptorsFromDartDefine(
    message: 'main() of screenshot_validate_test.dart',
  );

  test('after screenshot integration, test for sameness', () {

    for (var exampleDescriptor in examplesDescriptors) {

      print(' \n\n######### Log.Info.Level1: screenshot_validate_test.dart: Will COMPARE SCREENSHOT of $exampleDescriptor');

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
