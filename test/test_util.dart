/// Utilities used in tests and integration tests.
///

import 'package:tuple/tuple.dart';

import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';
import 'package:flutter_charts/flutter_charts.dart' show enumName;
import 'package:flutter_charts/src/chart/util/example_descriptor.dart' show ExampleDescriptor;

/// Path to screenshot file the test uses for each test.
String relativePath(String screenshotDirName, ExampleDescriptor exampleDescriptor) {
  return '$screenshotDirName/${screenshotFileName(exampleDescriptor)}';
}

/// Path to screenshot file which this test generates.
///
/// Generated from enum values.
/// Examples:
///   - 'ex10RandomData_lineChart.png'     (for old layout)
///   - 'ex10RandomData_lineChart_NEW.png' (for new layout)
String screenshotFileName(
  ExampleDescriptor exampleDescriptor,
) {
  ChartLayouter chartLayouter = exampleDescriptor.chartLayouter;
  String newLayoutSuffix = '';
  if (!(chartLayouter == ChartLayouter.oldManualLayouter)) {
    newLayoutSuffix =
        '_NEW_orientation_${exampleDescriptor.chartOrientation.name}_stacking_${exampleDescriptor.chartStacking.name}';
  }

  return '${enumName(exampleDescriptor.exampleEnum)}_${enumName(exampleDescriptor.chartType)}$newLayoutSuffix.png';
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
  ExampleDescriptor exampleDescriptor,
) {
  String expectedScreenshotPath = relativePath(expectedScreenshotDirName(), exampleDescriptor);
  String actualScreenshotPath = relativePath(screenshotDirName(), exampleDescriptor);

  return Tuple2(expectedScreenshotPath, actualScreenshotPath);
}
