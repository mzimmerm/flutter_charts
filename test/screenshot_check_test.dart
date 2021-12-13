/// todo-00 document 
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
    // todo-00 rename comboToRun to exampleToRun everywhere
    // todo-00 convert this to one method and place on test_util.dart
    Tuple2<ExamplesEnum, ExamplesChartTypeEnum> exampleToRun = app.requestedExampleComboToRun();
    String screenshotPath = relativePath(screenshotDirName(), exampleToRun);
    String expectedScreenshotPath = relativePath(expectedScreenshotDirName(), exampleToRun);

    // Flag controls if this test runs 'expect'. 
    // Set to false to generate initial validated screenshots.
    bool runExpect = true;

    // todo-00 THIS CODE RUNS ON THE DEVICE. SO, ANY FILE OPERATIONS ARE ON THE DEVICE. THIS MUST BE MOVED TO ANOTHER TEST WHICH IS REGULAR FLUTTER WIDGET TEST. 
    if (runExpect && !isExampleWithRandomData(exampleToRun)) {
      // todo-00 figure out how to start flutter drive in project. current dir says /
      // print('Directory is ${Directory.current}');
      // String path = '/home/mzimmermann/dev/my-projects-source/public-on-github/flutter_charts_v2/';
      //File expectedFile = File(path + expectedScreenshotPath);
      //File actualFile = File(path + screenshotPath);

      File expectedFile = File(expectedScreenshotPath);
      File actualFile = File(screenshotPath);
      
/*
      var contents = File(path + expectedScreenshotPath).readAsBytesSync();

      File expectedFile = File(path + expectedScreenshotPath);
      File actualFile = File(path + screenshotPath);

      expectedFile.readAsString().then((String contents) {
        print('Expected File Contents\n---------------');
        print(contents);
      });

      actualFile.readAsString().then((String contents) {
        print('ActualFile File Contents\n---------------');
        print(contents);
      });

      if (expectedFile.existsSync()) {
        if (actualFile.existsSync()) {
*/
      expectSync(
        expectedFile.readAsBytesSync(),
        actualFile.readAsBytesSync(),
      );
/*
        } else {
          throw StateError('Could not await for actual file');
        }
      } else {
        throw StateError('Could not await for expected file');
      }
*/
    }
  });
}
/*
// todo-00 create util/util_dart.dart in test directory and use it in test and integration_test.  
/// Path to screenshot file the test uses for each test.
String relativePath(String screenshotDirName, Tuple2 <ExamplesEnum, ExamplesChartTypeEnum> comboToRun) {
  return '$screenshotDirName/${screenshotFileName(comboToRun)}';
}

/// Path to screenshot file which this test generates. 
/// 
/// Generated from enum values. 
/// Example: 'ex10RandomData-lineChart.png'.
String screenshotFileName(Tuple2<ExamplesEnum, ExamplesChartTypeEnum> comboToRun) {
  return '${enumName(comboToRun.item1)}_${enumName(comboToRun.item2)}.png';
}

/// The name of the directory where screenshots are placed.
/// 
/// This test is assumed to run from project's root.
String screenshotDirName() {
  return 'integration_test/screenshots_tested';
}

String expectedScreenshotDirName() {
  return 'integration_test/screenshots_expected';
}
*/
