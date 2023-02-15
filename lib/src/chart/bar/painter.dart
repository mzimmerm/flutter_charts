// base libraries
import '../painter.dart';

// this level
import 'view_maker.dart';

/// This concrete [FlutterChartPainter] is also the [CustomPainter]; provides a constructor,
/// requiring [VerticalBarChartViewMaker] which generates (makes)
/// the view, the [ChartRootContainer] hierarchy.
///
/// See [FlutterChartPainter] for more information.
class VerticalBarChartPainter extends FlutterChartPainter {
  /// Constructor ensures the [VerticalBarChartPainter] is initialized with
  /// the [VerticalBarChartContainer].
  VerticalBarChartPainter({
    required VerticalBarChartViewMaker verticalBarChartViewMaker,
  }) : super(
          chartViewMaker: verticalBarChartViewMaker,
        );
}
