import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_charts/src/chart/chart_type/bar/container/root_container.dart';
import 'package:flutter_charts/src/chart/chart_type/line/container/root_container.dart';
import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart';
import 'package:logger/logger.dart' as logger;
import 'package:flutter_charts/src/chart/view_model/view_model.dart' show ChartViewModel;

import 'package:flutter_charts/src/chart/painter.dart' as painter;

// doc-only
import 'package:flutter_charts/src/chart/model/data_model.dart' as doc_model;
import 'package:flutter_charts/src/chart/cartesian/container/root_container.dart' as doc_root_container;


/// Abstract base class of Flutter Charts.
///
/// Extensions instances are the Flutter [widgets.Widget]s that show charts.
///
/// Instances should be created as any widget in Flutter. To create concrete [FlutterChart] instances,
/// client needs to create instances of two other classes:
///
///   - Instance of the concrete [painter.FlutterChartPainter] (this is simple, just use the no-arg constructor)
///   - Instance of [ChartViewModel] or its' extension; this needs an instance of [doc_model.ChartModel].
///
/// Structure:
///   - [FlutterChart] extends [widgets.CustomPaint]
///     - 'references ->' the [painter.FlutterChartPainter] extends [widgets.CustomPainter]
///       via the [widgets.CustomPaint.painter] reference in the Flutter framework;
///       the reference is set in [FlutterChart] constructor.
///     - 'references ->' the [ChartViewModel] via the [FlutterChart.chartViewModel];
///       the reference is set in [FlutterChart] constructor.
///   - [painter.FlutterChartPainter]
///     - 'references ->' [FlutterChart] via [painter.FlutterChartPainter.chart];
///       the reference is set late in [FlutterChart] constructor
///
/// Code example documenting the structure:
///
///   ``` dart
///   SwitchChartViewModel lineChartViewModel = SwitchChartViewModel.lineChartViewModelFactory(
///     chartOrientation: ChartOrientation.column,
///     chartStacking: ChartStacking.nonStacked,
///     chartModel: chartModel,
///     inputLabelLayoutStrategy: inputLabelLayoutStrategy,
///   );
///
///   LineChart lineChart = LineChart(
///     chartViewModel: lineChartViewModel, // also makes instance of [LineChartRootContainer]
///     flutterChartPainter: FlutterChartPainter(),
///   );
///   ```
///
/// Lifecycle:
///
///   - In [widgets.runApp] :
///     - the [doc_model.ChartModel] is created.
///     - the [ChartViewModel] is created from the above [doc_model.ChartModel].
///     - [FlutterChart]  (extends [widgets.CustomPaint])  instance is created from the above [ChartViewModel].
///     - control is handed over to the Flutter framework to run the application.
///   - During the running application, it is the [painter.FlutterChartPainter.paint] which starts the chart process as follows:
///     - The [painter.FlutterChartPainter.paint] method is called by the Flutter framework,
///       in it, the [doc_root_container.ChartRootContainer] (the root of the chart container hierarchy) is created.
///       Below we describe the call hierarchy deeper:
///       - [FlutterChartPainter.paint] invokes, on the [FlutterChart] instance created in [runApp] :
///         - The [ChartViewModel.chartRootContainerCreateBuildLayoutPaint], as follows:
///           `chart.chartViewModel.chartRootContainerCreateBuildLayoutPaint(canvas, size);` invokes in order:
///           - [ChartViewModel.makeChartRootContainer] which creates the [doc_root_container.ChartRootContainer],
///              which is kept on this class as member [chartRootContainer].
///           - [doc_root_container.ChartRootContainer.applyParentConstraints] which sets the top level constraints
///             on the root container
///           - [doc_root_container.ChartRootContainer]'s [BoxLayouter.layout]
///           - [doc_root_container.ChartRootContainer]'s [BoxContainer.paint]
///     - When the above [BoxContainer.paint] is done, control is back to Flutter
///
abstract class FlutterChart extends widgets.CustomPaint {
  /// Default generative constructor of concrete extensions.
  ///
  /// The passed [chartViewModel], is the source of data and data updates for [FlutterChart] instances.
  FlutterChart({
    widgets.Key? key,
    // Framework requirement that CustomPaint / FlutterChart holds on it's CustomPainter / FlutterChartPainter
    required painter.FlutterChartPainter flutterChartPainter,
    // Flutter_charts application requirement that [FlutterChart] holds on it's [ChartViewModel],
    //   which must be a concrete extension such as [BarChartViewModel]
    //   (that creates concrete view root [BarChartRootContainer]).
    required this.chartViewModel,
    widgets.CustomPainter? foregroundPainter,
    widgets.Size size = widgets.Size.zero,
    widgets.Widget? child,
  }) : super(
          key: key,
          painter: flutterChartPainter,
          foregroundPainter: foregroundPainter,
          size: size,
          child: child,
        ) {
    logger.Logger().d('Constructing $runtimeType');
    // Late initialize [FlutterChartPainter.chart], which is used during [FlutterChartPainter.paint]
    // by the [chart] member [FlutterChart.chartViewModel] to create, layout and paint the chart using
    //    ```dart
    //          chart.chartViewModel.chartRootContainerCreateBuildLayoutPaint(canvas, size);
    //    ```
    flutterChartPainter.chart = this;
  }

  /// The model and maker of the root of the chart view (container) hierarchy, the concrete [ChartRootContainer]
  /// such as [BarChartRootContainer] and [LineChartRootContainer]
  ///
  /// This [chartViewModel] object is created once per chart, on the FIRST invocation of [FlutterChartPainter.paint] ,
  /// BUT it is NOT recreated on each repaint - the follow up repaint [FlutterChartPainter.paint] invocation.
  /// That behavior is in contrast to concrete view, the [ChartRootContainer], which is created anew on every
  /// [FlutterChartPainter.paint] invocation, including the repaint invocation.
  final ChartViewModel chartViewModel;
}
