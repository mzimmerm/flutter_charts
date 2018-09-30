import 'package:flutter/widgets.dart' as widgets;

import '../line/container.dart' as line_containers;
import '../line/painter.dart' as painter show LineChartPainter;

/// Provides paint for the line chart.
///
/// It extends [CustomPaint] which is the flutter widget
/// that provides a canvas on which to draw during the paint phase.
/// The core override is to set the concrete [ChartContainer], and
/// it's [ChartContainer.isStacked] setting.
///
/// Note: The [LineChart] constructor shows how to call a super
///       with named parameters. The super's [CustomPaint] single constructor is
///         `const CustomPaint({ Key key, this.painter, this.foregroundPainter,
///                              this.size: Size.zero, Widget child })`
///       and syntax of a constructor with named parameters
///       can be seen in the [LineChart] constructor.
class LineChart extends widgets.CustomPaint {
  /// Default constructor accepts size
  LineChart({
    widgets.Key key,
    painter.LineChartPainter painter,
    widgets.CustomPainter foregroundPainter,
    widgets.Size size: widgets.Size.zero,
    widgets.Widget child,
    line_containers.LineChartContainer container,
  }) : super(
          key: key,
          painter: painter,
          foregroundPainter: foregroundPainter,
          size: size,
          child: child,
        ) {
    container.isStacked = false;
    painter.setContainer(container);
  }
}
