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

/// @Deprecated test that compares expected and actual example screenshots taken from the example app.
void main() {
  test('after screenshot integration, test for sameness', () {

    ExampleDescriptor exampleDescriptor = ExampleDescriptor.requestedExampleToRun();

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
  });
}
