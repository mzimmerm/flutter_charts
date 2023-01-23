import '../line/container.dart' as line_containers;

import '../painter.dart';

/// This concrete [CustomPainter] only provides a constructor,
/// specifically requiring [line_containers.LineChartRootContainer],
/// and setting [line_containers.LineChartContainer.isStacked] to false,
/// as lines can never be stacked.
///
/// See [FlutterChartPainter] for more information.
class LineChartPainter extends FlutterChartPainter {
  /// Constructor ensures the [LineChartPainter] is initialized with
  /// the [LineChartContainer]
  LineChartPainter({
    // todo-00-last required line_containers.LineChartRootContainer lineChartRootContainer,
    required line_containers.LineChartAnchor lineChartAnchor,
  // todo-00-last }) : super(chartRootContainer: lineChartRootContainer) {
  }) : super(chartAnchor: lineChartAnchor) {
    // todo-00-last-last-last : set this somewhere : lineChartRootContainer.isStacked = false;
  }
}
