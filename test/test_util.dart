/// Utilities used in tests and integration tests.
///

import 'package:tuple/tuple.dart';

import 'package:flutter_charts/src/morphic/container/chart_support/chart_orientation.dart';
import 'package:flutter_charts/flutter_charts.dart' show enumName;
import '../example/lib/src/util/examples_descriptor.dart';

/// Path to screenshot file the test uses for each test.
String relativePath(
  String screenshotDirName,
  Tuple4<ExamplesEnum, ExamplesChartTypeEnum, ChartSeriesOrientation, bool> exampleComboToRun,
) {
  return '$screenshotDirName/${screenshotFileName(exampleComboToRun)}';
}

/// Path to screenshot file which this test generates.
///
/// Generated from enum values.
/// Examples:
///   - 'ex10RandomData_lineChart.png'     (for old layout)
///   - 'ex10RandomData_lineChart_NEW.png' (for new layout)
String screenshotFileName(
  Tuple4<ExamplesEnum, ExamplesChartTypeEnum, ChartSeriesOrientation, bool> exampleComboToRun,
) {
  bool isUseOldDataContainer = exampleComboToRun.item4;
  String newLayout = '';
  if (!isUseOldDataContainer) {
    newLayout = '_NEW_orientation_${exampleComboToRun.item3.name}';
  }

  return '${enumName(exampleComboToRun.item1)}_${enumName(exampleComboToRun.item2)}$newLayout.png';
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
Tuple2<String, String> screenshotPathsFor(
  Tuple4<ExamplesEnum, ExamplesChartTypeEnum, ChartSeriesOrientation, bool> exampleComboToRun,
) {
  String expectedScreenshotPath = relativePath(expectedScreenshotDirName(), exampleComboToRun);
  String actualScreenshotPath = relativePath(screenshotDirName(), exampleComboToRun);
  return Tuple2(expectedScreenshotPath, actualScreenshotPath);
}
