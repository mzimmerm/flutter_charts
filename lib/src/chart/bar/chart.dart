import 'package:flutter/widgets.dart' as widgets;

// base libraries
import '../chart.dart';
import '../painter.dart' show FlutterChartPainter;
import '../view_maker.dart' show ChartViewMaker;

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
    required FlutterChartPainter chartPainter,
    required ChartViewMaker chartViewMaker,
    widgets.CustomPainter? foregroundPainter,
    widgets.Size size = widgets.Size.zero,
    widgets.Widget? child,
  }) : super(
          key: key,
          painter: chartPainter,
          chartViewMaker: chartViewMaker,
          foregroundPainter: foregroundPainter,
          size: size,
          child: child,
        )
  {
    // Late initialize [FlutterChartPainter.chart], which is used during [FlutterChartPainter.paint]
    // by the [chart] member [FlutterChart.chartViewMaker] to create, layout and paint the chart using
    //    ```dart
    //          chart.chartViewMaker.chartRootContainerCreateBuildLayoutPaint(canvas, size);
    //    ```
    chartPainter.chart = this;
  }

}
