// base libraries
import '../painter.dart';
import '../view_maker.dart'; // NEW BASE

// this level


/// This concrete [FlutterChartPainter] is also the [CustomPainter]; provides a constructor,
/// requiring [line_containers.LineChartViewMaker]which generates (makes)
/// the view, the [ChartRootContainer] hierarchy.
///
/// See [FlutterChartPainter] for more information.
class LineChartPainter extends FlutterChartPainter {
  /// Constructor ensures the [LineChartPainter] is initialized with
  /// the [LineChartContainer]
  LineChartPainter({
    // todo-00-last-last-last-last : required LineChartViewMaker lineChartViewMaker,
    required ChartViewMaker lineChartViewMaker,
  }) : super(
          chartViewMaker: lineChartViewMaker,
        );
}
