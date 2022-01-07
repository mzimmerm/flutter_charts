import '../bar/container.dart' as bar_containers;

import '../painter.dart';

/// This concrete [CustomPainter] only provides a constructor,
/// specifically requiring [bar_containers.VerticalBarChartTopContainer],
/// and setting [verticalBarChartContainer.isStacked] to true,
/// as bars are stacked by default.
///
/// See [ChartPainter] for more information.
class VerticalBarChartPainter extends ChartPainter {
  /// Constructor ensures the [VerticalBarChartPainter] is initialized with
  /// the [VerticalBarChartContainer].
  VerticalBarChartPainter({
    required bar_containers.VerticalBarChartTopContainer verticalBarChartContainer,
  }) : super(chartTopContainer: verticalBarChartContainer) {
    verticalBarChartContainer.isStacked = true;
  }
}
