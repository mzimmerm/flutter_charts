import 'package:flutter/widgets.dart' as widgets;

import '../bar/painter.dart' as painter;

import '../bar/layouters.dart' as bar_layouters;

/// Provides paint for the vertical bar chart.
///
/// It extends [CustomPaint] which is the flutter widget
/// that provides a canvas on which to draw during the paint phase.
/// The core override is to set the concrete [ChartLayouter], and
/// it's [ChartLayouter.isStacked] setting.
class VerticalBarChart extends widgets.CustomPaint {
  /// Default constructor accepts size
  VerticalBarChart({
    widgets.Key key,
    painter.VerticalBarChartPainter painter,
    widgets.CustomPainter foregroundPainter,
    widgets.Size size: widgets.Size.zero,
    widgets.Widget child,
    bar_layouters.VerticalBarChartLayouter layouter,
  })
      : super(
    key: key,
    painter: painter,
    foregroundPainter: foregroundPainter,
    size: size,
    child: child,
  ) {
    layouter.isStacked = true;
    painter.setLayouter(layouter);
  }
}

