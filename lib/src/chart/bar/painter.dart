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
// todo-00-last    required bar_containers.VerticalBarChartRootContainer verticalBarChartRootContainer,
    required bar_containers.VerticalBarChartAnchor verticalBarChartAnchor,
// todo-00-last  }) : super(chartRootContainer: verticalBarChartRootContainer) {
  }) : super(chartAnchor: verticalBarChartAnchor) {
    // todo-00-last-last-last : set this where needed : verticalBarChartRootContainer.isStacked = true;
  }
}
