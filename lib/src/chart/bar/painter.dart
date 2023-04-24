// base libraries
import '../painter.dart';
import '../view_maker.dart'; // NEW BASE

// this level

/// This concrete [FlutterChartPainter] is also the [CustomPainter]; provides a constructor,
/// requiring [BarChartViewMaker] which generates (makes)
/// the view, the [ChartRootContainer] hierarchy.
///
/// See [FlutterChartPainter] for more information.
class BarChartPainter extends FlutterChartPainter {
  /// Constructor ensures the [BarChartPainter] is initialized with
  /// the [BarChartContainer].
  BarChartPainter({
    required ChartViewMaker barChartViewMaker,
  }) : super(
          chartViewMaker: barChartViewMaker,
        );
}
