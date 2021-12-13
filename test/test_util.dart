/// Utilities used in tests and integration tests.
/// 
import 'package:tuple/tuple.dart';

import 'package:flutter_charts/flutter_charts.dart' show enumName;

import '../example1/lib/ExamplesChartTypeEnum.dart';
import '../example1/lib/ExamplesEnum.dart';
import '../example1/lib/examples_descriptor.dart';
import '../example1/lib/main.dart' as app;

// todo-00 create util/util_dart.dart in test directory and use it in test and integration_test.  
/// Path to screenshot file the test uses for each test.
String relativePath(String screenshotDirName, Tuple2 <ExamplesEnum, ExamplesChartTypeEnum> exampleComboToRun) {
  return '$screenshotDirName/${screenshotFileName(exampleComboToRun)}';
}

/// Path to screenshot file which this test generates. 
/// 
/// Generated from enum values. 
/// Example: 'ex10RandomData-lineChart.png'.
String screenshotFileName(Tuple2<ExamplesEnum, ExamplesChartTypeEnum> exampleComboToRun) {
  return '${enumName(exampleComboToRun.item1)}_${enumName(exampleComboToRun.item2)}.png';
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
