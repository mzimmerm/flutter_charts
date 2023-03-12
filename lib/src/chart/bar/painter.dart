// base libraries
import '../painter.dart';
import '../view_maker.dart'; // NEW BASE

// this level

/// This concrete [FlutterChartPainter] is also the [CustomPainter]; provides a constructor,
/// requiring [VerticalBarChartViewMaker] which generates (makes)
/// the view, the [ChartRootContainer] hierarchy.
///
/// See [FlutterChartPainter] for more information.
class VerticalBarChartPainter extends FlutterChartPainter {
  /// Constructor ensures the [VerticalBarChartPainter] is initialized with
  /// the [VerticalBarChartContainer].
  VerticalBarChartPainter({
    required ChartViewMaker verticalBarChartViewMaker,
  }) : super(
          chartViewMaker: verticalBarChartViewMaker,
        );
}
