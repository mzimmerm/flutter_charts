import 'dart:ui' as ui show Canvas, Size;

import 'painter.dart';
import 'package:logger/logger.dart' as logger;

// import 'dart:developer' as dart_developer;

import '../morphic/container/chart_support/chart_style.dart';
import '../morphic/container/morphic_dart_enums.dart';
//import '../morphic/container/container_edge_padding.dart';
//import '../morphic/container/container_layouter_base.dart' as container_base;
//import '../morphic/container/layouter_one_dimensional.dart';
import '../morphic/container/constraints.dart' as constraints;

// this level or equivalent
import 'model/data_model.dart' as model;
import 'options.dart' as options;
import 'container/data_container.dart' as data_container;
import 'container/container_common.dart' as container_common;
import 'container/root_container.dart' as root_container;
import 'iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
import 'model/label_model.dart' as util_labels;

/// Type definition for closures returning a function from model [model.PointModel] 
/// to container [data_container.PointContainer].
typedef ClsPointToNullableContainer = data_container.PointContainer? Function (model.PointModel);

/// Abstract base class for view makers.
///
/// A view maker is a class that makes (creates, produces, generates) a chart view hierarchy,
/// starting with a concrete [root_container.ChartRootContainer], with the help of [model.ChartModel].
///
/// This base view maker has access to [model.ChartModel]
///
/// This base view maker holds as members:
///   - the model in [chartModel]. It's member [model.ChartModel.chartOptions] provides access to [options.ChartOptions]
///   - the chart orientation in [chartOrientation]
///   - the definition whether the chart is stacked in [chartStacking].
///   - the label layout strategy in [inputLabelLayoutStrategy]
///
/// All the members above are needed to construct the view container hierarchy root, the [chartRootContainer],
/// which is also a late member after it is constructed.
///
/// [ChartViewMaker] is not a BoxContainer, it provides a 'link' between [FlutterChartPainter]
/// which [FlutterChartPainter.paint] method is called by the Flutter framework,
/// and the root of the chart container hierarchy, the [root_container.ChartRootContainer] which it
/// creates in its [makeChartRootContainer].
///
/// Core methods of [ChartViewMaker] are
///   - [chartRootContainerCreateBuildLayoutPaint], which should be called in [FlutterChartPainter.paint];
///     this method creates, builds, lays out, and paints
///     the root of the chart container hierarchy, the [chartRootContainer].
///   - abstract [makeChartRootContainer]; from it, the extensions of [ChartViewMaker]
///     (for example, [LineChartViewMaker]) should create and return an instance of the concrete [chartRootContainer]
///     (for example [LineChartRootContainer]).
///   - [container.ChartBehavior.extendAxisToOrigin] is on this Maker,
///     as it controls how views behave (although does not control view making).
abstract class ChartViewMaker extends Object with container_common.ChartBehavior {
  ChartViewMaker({
    required this.chartModel,
    required this.chartOrientation,
    required this.chartStacking,
    this.inputLabelLayoutStrategy,
  }) {
    logger.Logger().d('Constructing ChartViewMaker');
    // Copy options also on this [ViewMaker] from Model.options
    chartOptions = chartModel.chartOptions;

    // Create [outputLabelsGenerator] which depends on both ChartModel and ChartRootContainer.
    // We can construct the generator here in [ChartViewMaker] constructor or later
    // (e.g. [ChartRootContainer], [VerticalAxisContainer]). But here, in [ChartViewMaker] is the first time we can
    // create the [inputLabelsGenerator] and [inputLabelsGenerator] instance of [DataRangeLabelInfosGenerator], so do that.
    outputLabelsGenerator = util_labels.DataRangeLabelInfosGenerator(
      chartOrientation: chartOrientation,
      chartStacking: chartStacking,
      chartModel: chartModel,
      dataDependency: DataDependency.outputData,
      extendAxisToOrigin: extendAxisToOrigin,
      valueToLabel: options.outputValueToLabel,
      inverseTransform: chartOptions.dataContainerOptions.yInverseTransform,
      userLabels: chartModel.outputUserLabels,
    );

    // See comment in VerticalAxisContainer constructor
    inputLabelsGenerator = util_labels.DataRangeLabelInfosGenerator(
      chartOrientation: chartOrientation,
      chartStacking: chartStacking,
      chartModel: chartModel,
      dataDependency: DataDependency.inputData,
      extendAxisToOrigin: extendAxisToOrigin,
      valueToLabel: options.inputValueToLabel,
      inverseTransform: chartOptions.dataContainerOptions.xInverseTransform,
      userLabels: chartModel.inputUserLabels,
    );
  }

  /// ChartData to hold on before member [chartRootContainer] is created late.
  ///
  /// After [chartRootContainer] is created and set, This [ChartModel] type member [chartModel]
  /// should be placed on the member [chartRootContainer.ownerChartModel].

  /// Model for this chart. Created before chart, set in concrete [ChartViewMaker] in constructor.
  final model.ChartModel chartModel;

  /// Options set from model options in [FlutterChartPainter] constructor from [FlutterChartPainter.chartViewMaker]'s
  /// [ChartViewMaker.chartModel]'s [ChartOptions].
  late final options.ChartOptions chartOptions;

  final ChartOrientation chartOrientation;

  final ChartStacking chartStacking;

  /// The root container (view) is created by this maker [ChartViewMaker]
  /// on every [FlutterChartPainter] paint and repaint.
  ///
  /// While the owner maker survives repaint,
  /// it's member, this [chartRootContainer] is recreated on each repaint in
  /// the following code in [FlutterChartPainter.paint]:
  ///
  /// ```dart
  ///         chartViewMaker.chartRootContainerCreateBuildLayoutPaint(canvas, size);
  /// ```
  ///
  /// Because it can be recreated and re-set in [paint], it is not final;
  ///   it's children, [legendContainer], etc are also not final.
  late root_container.ChartRootContainer chartRootContainer;

  /// The generator and holder of labels in the form of [LabelInfos],
  /// as well as the range of the axis values.
  ///
  /// The [labelsGenerator]'s interval [DataRangeLabelInfosGenerator.dataRange]
  /// is the data range corresponding to the Y axis pixel range kept in [axisPixelsRange].
  ///
  /// Important note: This should NOT be part of model, as different views would have a different instance of it.
  ///                 Reason: Different views may have different labels, esp. on the Y axis.
  late util_labels.DataRangeLabelInfosGenerator outputLabelsGenerator;

  late util_labels.DataRangeLabelInfosGenerator inputLabelsGenerator;

  /// Layout strategy, necessary to create the concrete view [ChartRootContainer].
  strategy.LabelLayoutStrategy? inputLabelLayoutStrategy;

  /// Keep track of first run. As this [ChartViewMaker] survives re-paint (but not first paint),
  /// this can be used to initialize 'late final' members on first paint.
  bool _isFirst = true;

  void chartRootContainerCreateBuildLayoutPaint(ui.Canvas canvas, ui.Size size) {
    // Create the concrete [ChartRootContainer] for this concrete [ChartViewMaker].
    // After this invocation, the created root container is populated with children
    // HorizontalAxisContainer, VerticalAxisContainer, DataContainer and LegendContainer. Their children are partly populated,
    // depending on the concrete container. For example VerticalAxisContainer is populated with DataRangeLabelInfosGenerator.

    String isFirstStr = _debugPrintBegin();

    // Create the view [chartRootContainer] and set on member on this maker [ChartViewMaker].
    // This happens even on re-paint, so can be done multiple times after state changes in the + button.
    chartRootContainer = makeChartRootContainer(chartViewMaker: this); // also link from this ViewMaker to ChartRootContainer.

    // Only set `chartModel.chartViewMaker = this` ONCE. Reason: member chartModel is created ONCE, same as this ANCHOR.
    // To have chartModel late final, we have to keep track to only initialize chartModel.chartViewMaker = this on first run.
    if (_isFirst) {
      _isFirst = false;
    }

    // e.g. set background: canvas.drawPaint(ui.Paint()..color = material.Colors.green);

    // Apply constraints on root. Layout size and constraint size of the [ChartRootContainer] are the same, and
    // are equal to the full 'size' passed here from the framework via [FlutterChartPainter.paint].
    // This passed 'size' is guaranteed to be the same area on which the painter will paint.

    chartRootContainer.applyParentConstraints(
      chartRootContainer,
      constraints.BoxContainerConstraints.insideBox(
        size: ui.Size(
          size.width,
          size.height,
        ),
      ),
    );

    chartRootContainer.layout();

    chartRootContainer.paint(canvas);

    _debugPrintEnd(isFirstStr);
  }

  /// Should create a concrete instance of [ChartRootContainer], bind it to member [chartRootContainer],
  /// and return it.
  ///
  /// Generally, the created [ChartRootContainer]'s immediate children should also be created and added to it,
  /// but deeper children may or may not be created.
  ///
  /// In the default implementations, the [chartRootContainer]'s children created are
  /// [ChartRootContainer.legendContainer],  [ChartRootContainer.verticalAxisContainer],
  ///  [ChartRootContainer.horizontalAxisContainer], and  [chartRootContainer.chartModelContainer].
  ///
  /// If an extension uses an implementation that does not adhere to the above
  /// description, the [ChartRootContainer.layout] should be overridden.
  ///
  /// Important notes:
  ///   - This controller (ViewMaker) can access both on ChartRootContainer and ChartModel.
  root_container.ChartRootContainer makeChartRootContainer({
    required covariant ChartViewMaker chartViewMaker,
  });

  String _debugPrintBegin() {
    String isFirstStr = _isFirst ? '=== IS FIRST ===' : '=== IS SECOND ===';

    /* KEEP
    dart_developer.log(
        '    ========== In $runtimeType.chartRootContainerCreateBuildLayoutPaint BEGIN BEGIN BEGIN, $isFirstStr',
        name: 'charts.debug.log');
    */

    return isFirstStr;
  }

  void _debugPrintEnd(String isFirstStr) {
    /* KEEP
    dart_developer.log(
        '    ========== In $runtimeType.chartRootContainerCreateBuildLayoutPaint END END END, $isFirstStr',
        name: 'charts.debug.log');
    */
  }
}
