import '../bar/container.dart' as bar_containers;
import '../bar/view_maker.dart' as bar_view_maker;
import '../painter.dart';

/// This concrete [FlutterChartPainter] is also the [CustomPainter]; provides a constructor,
/// requiring [bar_containers.VerticalBarChartViewMaker] which generates (makes)
/// the view, the [ChartRootContainer] hierarchy.
///
/// See [FlutterChartPainter] for more information.
class VerticalBarChartPainter extends FlutterChartPainter {
  /// Constructor ensures the [VerticalBarChartPainter] is initialized with
  /// the [VerticalBarChartContainer].
  VerticalBarChartPainter({
    required bar_view_maker.VerticalBarChartViewMaker verticalBarChartViewMaker,
  }) : super(
          chartViewMaker: verticalBarChartViewMaker,
        );
}
