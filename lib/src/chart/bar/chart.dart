import 'package:flutter/widgets.dart' as widgets;

// base libraries
import '../chart.dart' as chart;

// this level
import 'painter.dart' as bar_painter;

/// Provides paint for the vertical bar chart.
///
/// It extends [CustomPaint] which is the flutter widget
/// that provides a canvas on which to draw during the paint phase.
/// The core override is to set the concrete [ChartContainer], and
/// it's [ChartContainer.isStacked] setting.
// todo-001-refactoring : rename this and all related, to BarChart - orientation defines 'vertical' and 'horizontal'
class VerticalBarChart extends chart.FlutterChart {
  /// Default constructor accepts size
  VerticalBarChart({
    widgets.Key? key,
    required bar_painter.VerticalBarChartPainter painter,
    widgets.CustomPainter? foregroundPainter,
    widgets.Size size = widgets.Size.zero,
    widgets.Widget? child,
  }) : super(
          key: key,
          painter: painter,
          foregroundPainter: foregroundPainter,
          size: size,
          child: child,
        );
}
