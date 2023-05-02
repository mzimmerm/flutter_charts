import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/chart/container/bar/root_container.dart';
import 'package:flutter_charts/src/chart/container/line/root_container.dart';
import 'package:logger/logger.dart' as logger;

import 'painter.dart' as painter;

/// Abstract base class of Flutter Charts.
///
abstract class FlutterChart extends widgets.CustomPaint {
  /// Default generative constructor of concrete extensions.
  ///
  /// giving it [chartViewMaker], which
  /// holds on [ownerChartModel] and other members needed for
  /// the late creation of [containers.ChartViewMaker.chartViewMaker].
  FlutterChart({
    widgets.Key? key,
    // Framework requirement that CustomPaint / FlutterChart holds on it's CustomPainter / FlutterChartPainter
    required painter.FlutterChartPainter painter,
    // Flutter_charts application requirement that [FlutterChart] holds on it's [ChartViewMaker],
    //   which must be a concrete extension such as [BarChartViewMaker]
    //   (that creates concrete view root [BarChartRootContainer]).
    required this.chartViewMaker,
    widgets.CustomPainter? foregroundPainter,
    widgets.Size size = widgets.Size.zero,
    widgets.Widget? child,
  }) : super(
          key: key,
          painter: painter,
          foregroundPainter: foregroundPainter,
          size: size,
          child: child,
        ) {
    logger.Logger().d('Constructing $runtimeType');
  }

  /// The maker of the root of the chart view (container) hierarchy, the concrete [ChartRootContainer]
  /// such as [BarChartRootContainer] and [LineChartRootContainer]
  ///
  /// This [chartViewMaker] object is created once per chart, on the FIRST invocation of [FlutterChartPainter.paint] ,
  /// BUT it is NOT recreated on each repaint - the follow up repaint [FlutterChartPainter.paint] invocation.
  /// That behavior is in contrast to concrete view, the [ChartRootContainer], which is created anew on every
  /// [FlutterChartPainter.paint] invocation, including the repaint invocation.
  final ChartViewMaker chartViewMaker;
}
