import '../bar/container.dart' as bar_containers;
import '../painter.dart';

/// This concrete [CustomPainter] only provides a constructor,
/// specifically requiring [bar_containers.VerticalBarChartRootContainer],
/// and setting [verticalBarChartContainer.isStacked] to true,
/// as bars are stacked by default.
///
/// See [FlutterChartPainter] for more information.
class VerticalBarChartPainter extends FlutterChartPainter {
  /// Constructor ensures the [VerticalBarChartPainter] is initialized with
  /// the [VerticalBarChartContainer].
  VerticalBarChartPainter({
    required bar_containers.VerticalBarChartRootContainer verticalBarChartRootContainer,
  }) : super(chartRootContainer: verticalBarChartRootContainer) {
    verticalBarChartRootContainer.isStacked = true;
  }
}
