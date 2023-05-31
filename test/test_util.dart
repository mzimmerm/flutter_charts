/// Utilities used in tests and integration tests.
///

import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';
import 'package:flutter_charts/flutter_charts.dart' show enumName;
import 'package:flutter_charts/src/chart/util/example_descriptor.dart' show ExampleDescriptor;


/* todo-00-done : remove
Tuple2<String, String> screenshotPathsFor(
  ExampleDescriptor exampleDescriptor,
) {
  String expectedScreenshotPath = relativePath(expectedScreenshotDirName(), exampleDescriptor);
  String actualScreenshotPath = relativePath(screenshotDirName(), exampleDescriptor);

  return Tuple2(expectedScreenshotPath, actualScreenshotPath);
}
*/

/// Extract paths to screenshots for tests.
///
/// Paths include filename, and are relative to project root.
class ScreenshotPaths {

  ScreenshotPaths({
    required this.exampleDescriptor,
  });

  final ExampleDescriptor exampleDescriptor;

  late final String _expectedScreenshotPath = _relativePath(_expectedScreenshotDirName(), exampleDescriptor);
  String get expectedScreenshotPath => _expectedScreenshotPath;
  late final String _actualScreenshotPath = _relativePath(_screenshotDirName(), exampleDescriptor);
  String get actualScreenshotPath => _actualScreenshotPath;

  /// Path to screenshot file the test uses for each test.
  String _relativePath(String screenshotDirName, ExampleDescriptor exampleDescriptor) {
    return '$screenshotDirName/${_screenshotFileName(exampleDescriptor)}';
  }

  /// Path to screenshot file which this test generates.
  ///
  /// Generated from enum values.
  /// Examples:
  ///   - 'ex10RandomData_lineChart.png'     (for old layout)
  ///   - 'ex10RandomData_lineChart_NEW.png' (for new layout)
  String _screenshotFileName(
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
  String _screenshotDirName() {
    return 'integration_test/screenshots_tested';
  }

  String _expectedScreenshotDirName() {
    return 'integration_test/screenshots_expected';
  }

}
