import 'package:flutter/widgets.dart' as widgets;

// base libraries
import '../../chart.dart';
import '../../painter.dart' show FlutterChartPainter;
import '../../view_model.dart' show ChartViewModel;

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
class LineChart extends FlutterChart {
  /// Default constructor accepts size
  LineChart({
    widgets.Key? key,
    required FlutterChartPainter chartPainter,
    required ChartViewModel chartViewModel,
    widgets.CustomPainter? foregroundPainter,
    widgets.Size size = widgets.Size.zero,
    widgets.Widget? child,
  }) : super(
          key: key,
          chartPainter: chartPainter,
          chartViewModel: chartViewModel,
          foregroundPainter: foregroundPainter,
          size: size,
          child: child,
        )
  {
    // Late initialize [FlutterChartPainter.chart], which is used during [FlutterChartPainter.paint]
    // by the [chart] member [FlutterChart.chartViewModel] to create, layout and paint the chart using
    //    ```dart
    //          chart.chartViewModel.chartRootContainerCreateBuildLayoutPaint(canvas, size);
    //    ```
    chartPainter.chart = this;
  }
}
