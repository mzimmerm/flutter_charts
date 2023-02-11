import '../line/container.dart' as line_containers;

import '../painter.dart';

/// This concrete [FlutterChartPainter] is also the [CustomPainter]; provides a constructor,
/// requiring [line_containers.LineChartViewMaker]which generates (makes)
/// the view, the [ChartRootContainer] hierarchy.
///
/// See [FlutterChartPainter] for more information.
class LineChartPainter extends FlutterChartPainter {
  /// Constructor ensures the [LineChartPainter] is initialized with
  /// the [LineChartContainer]
  LineChartPainter({
    required line_containers.LineChartViewMaker lineChartViewMaker,
  }) : super(chartViewMaker: lineChartViewMaker);
}
