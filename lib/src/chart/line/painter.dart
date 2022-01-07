import '../line/container.dart' as line_containers;

import '../painter.dart';

/// This concrete [CustomPainter] only provides a constructor,
/// specifically requiring [line_containers.LineChartTopContainer],
/// and setting [line_containers.LineChartContainer.isStacked] to false,
/// as lines can never be stacked.
///
/// See [ChartPainter] for more information.
class LineChartPainter extends ChartPainter {
  /// Constructor ensures the [LineChartPainter] is initialized with
  /// the [LineChartContainer]
  LineChartPainter({
    required line_containers.LineChartTopContainer lineChartContainer,
  }) : super(chartTopContainer: lineChartContainer) {
    lineChartContainer.isStacked = false;
  }
}
