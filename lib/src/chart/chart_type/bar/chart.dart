import 'package:flutter/widgets.dart' as widgets;

// base libraries
import 'package:flutter_charts/src/chart/chart.dart';
import 'package:flutter_charts/src/chart/painter.dart' show FlutterChartPainter;
import 'package:flutter_charts/src/chart/view_model/view_model.dart' show ChartViewModel;

/// Provides paint for the vertical bar chart.
///
/// It extends [CustomPaint] which is the flutter widget
/// that provides a canvas on which to draw during the paint phase.
/// The core override is to set the concrete [ChartContainer], and
/// it's [ChartContainer.isStacked] setting.
class BarChart extends FlutterChart {
  /// Default constructor accepts size
  BarChart({
    widgets.Key? key,
    required FlutterChartPainter flutterChartPainter,
    required ChartViewModel chartViewModel,
    widgets.CustomPainter? foregroundPainter,
    widgets.Size size = widgets.Size.zero,
    widgets.Widget? child,
  }) : super(
          key: key,
          flutterChartPainter: flutterChartPainter,
          chartViewModel: chartViewModel,
          foregroundPainter: foregroundPainter,
          size: size,
          child: child,
        );
}
