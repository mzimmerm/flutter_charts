/// todo-00-document 
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart' show IntegrationTestWidgetsFlutterBinding;
import 'package:tuple/tuple.dart';
import 'dart:io';

import 'test_util.dart';

import '../example1/lib/src/util/examples_descriptor.dart';
import '../example1/lib/main.dart' as app;


void main() {
  
  test('after screenshot integration, test for sameness', () {
    // Find the command-line provided enums which define chart data, options and type to use in the example app.
    // The app find the enums transiently, here we need it to generate consistent screenshot filename. 
    Tuple2<ExamplesEnum, ExamplesChartTypeEnum> exampleComboToRun = app.requestedExampleToRun();
    var screenshotPaths = screenshotPathsFor(exampleComboToRun);
    String expectedScreenshotPath = screenshotPaths.item1;
    String screenshotPath = screenshotPaths.item2;

    // Flag controls if this test runs 'expect'. 
    // Set to false to generate initial validated screenshots.
    bool runExpect = true;

    if (runExpect && !isExampleWithRandomData(exampleComboToRun)) {
      File expectedFile = File(expectedScreenshotPath);
      File actualFile = File(screenshotPath);
      
      expectSync(
        expectedFile.readAsBytesSync(),
        actualFile.readAsBytesSync(),
      );
    }
  });
}
