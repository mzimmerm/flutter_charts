import '../line/container.dart' as line_containers;

import '../painter.dart';

/// This concrete [FlutterChartPainter] is also the [CustomPainter]; provides a constructor,
/// requiring [line_containers.LineChartAnchor] which anchors the [ChartRootContainer] hierarchy.
///
/// See [FlutterChartPainter] for more information.
class LineChartPainter extends FlutterChartPainter {
  /// Constructor ensures the [LineChartPainter] is initialized with
  /// the [LineChartContainer]
  LineChartPainter({
    required line_containers.LineChartAnchor lineChartAnchor,
  }) : super(chartAnchor: lineChartAnchor);
}
