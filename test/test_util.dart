/// Utilities used in tests and integration tests.
/// 
import 'package:tuple/tuple.dart';

import 'package:flutter_charts/flutter_charts.dart' show enumName;

import '../example1/lib/src/util/examples_descriptor.dart';

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

/// Extract paths to screenshots for tests. 
/// 
/// Paths include filename, and are relative to project root. 
Tuple2<String, String> screenshotPathsFor(Tuple2<ExamplesEnum, ExamplesChartTypeEnum> exampleComboToRun) {
  String expectedScreenshotPath = relativePath(expectedScreenshotDirName(), exampleComboToRun);
  String actualScreenshotPath = relativePath(screenshotDirName(), exampleComboToRun);
  return Tuple2(expectedScreenshotPath, actualScreenshotPath);
}
