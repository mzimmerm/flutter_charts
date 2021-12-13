/// todo-00-document 
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart' show IntegrationTestWidgetsFlutterBinding;
import 'package:tuple/tuple.dart';
import 'dart:io';

import 'test_util.dart';

// todo-00 pull the enums and descriptor to main.
import '../example1/lib/ExamplesChartTypeEnum.dart';
import '../example1/lib/ExamplesEnum.dart';
import '../example1/lib/examples_descriptor.dart';
import '../example1/lib/main.dart' as app;


void main() {
  
  test('after screenshot integration, test for sameness', () {
    // Find the command-line provided enums which define chart data, options and type to use in the example app.
    // The app find the enums transiently, here we need it to generate consistent screenshot filename. 
    // todo-00-now convert this to one method and place on test_util.dart
    Tuple2<ExamplesEnum, ExamplesChartTypeEnum> exampleComboToRun = app.requestedExampleToRun();
    String screenshotPath = relativePath(screenshotDirName(), exampleComboToRun);
    String expectedScreenshotPath = relativePath(expectedScreenshotDirName(), exampleComboToRun);

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
