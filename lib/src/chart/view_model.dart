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
import 'container/axis_container.dart' as axis_container;
import 'container/container_common.dart' as container_common;
import 'container/root_container.dart' as root_container;
import 'iterative_layout_strategy.dart' as strategy;
import 'model/label_model.dart' as util_labels;
import '../util/util_dart.dart' as util_dart;

/// Type definition for closures returning a function from model [model.PointModel] 
/// to container [data_container.PointContainer].
typedef ClsPointToNullableContainer = data_container.PointContainer? Function (model.PointModel);

/// Abstract base class for view models.
///
/// A view model is a class that makes (creates, produces, generates) a chart view hierarchy,
/// starting with a concrete [root_container.ChartRootContainer], with the help of [model.ChartModel].
///
/// This base view model has access to [model.ChartModel]
///
/// This base view model holds as members:
///   - the model in [_chartModel]. It's member [model.ChartModel.chartOptions] provides access to [options.ChartOptions]
///   - the chart orientation in [chartOrientation]
///   - the definition whether the chart is stacked in [chartStacking].
///   - the label layout strategy in [inputLabelLayoutStrategyInst]
///
/// All the members above are needed to construct the view container hierarchy root, the [chartRootContainer],
/// which is also a late member after it is constructed.
///
/// [ChartViewModel] is not a BoxContainer, it provides a 'link' between [FlutterChartPainter]
/// which [FlutterChartPainter.paint] method is called by the Flutter framework,
/// and the root of the chart container hierarchy, the [root_container.ChartRootContainer] which it
/// creates in its [makeChartRootContainer].
///
/// Core methods of [ChartViewModel] are
///   - [chartRootContainerCreateBuildLayoutPaint], which should be called in [FlutterChartPainter.paint];
///     this method creates, builds, lays out, and paints
///     the root of the chart container hierarchy, the [chartRootContainer].
///   - abstract [makeChartRootContainer]; from it, the extensions of [ChartViewModel]
///     (for example, [LineChartViewModel]) should create and return an instance of the concrete [chartRootContainer]
///     (for example [LineChartRootContainer]).
///   - [container.ChartBehavior.extendAxisToOrigin] is on this [ChartViewModel],
///     as it controls how views behave (although does not control view making).
abstract class ChartViewModel extends Object with container_common.ChartBehavior {
  ChartViewModel({
    required model.ChartModel chartModel,
    required this.chartOrientation,
    required this.chartStacking,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) : chartOptions = chartModel.chartOptions,
       _chartModel = chartModel {
    logger.Logger().d('Constructing ChartViewModel');

    inputLabelLayoutStrategy ??= strategy.DefaultIterativeLabelLayoutStrategy(options: _chartModel.chartOptions);
    inputLabelLayoutStrategyInst = inputLabelLayoutStrategy;

    // Create [outputLabelsGenerator] which depends on both ChartModel and ChartRootContainer.
    // We can construct the generator here in [ChartViewModel] constructor or later
    // (e.g. [ChartRootContainer], [VerticalAxisContainer]). But here, in [ChartViewModel] is the first time we can
    // create the [inputLabelsGenerator] and [inputLabelsGenerator] instance of [DataRangeLabelInfosGenerator], so do that.
    outputLabelsGenerator = util_labels.DataRangeLabelInfosGenerator(
      chartOrientation: chartOrientation,
      chartStacking: chartStacking,
      chartModel: _chartModel,
      dataDependency: DataDependency.outputData,
      extendAxisToOrigin: extendAxisToOrigin,
      valueToLabel: options.outputValueToLabel,
      inverseTransform: chartOptions.dataContainerOptions.yInverseTransform,
      userLabels: _chartModel.outputUserLabels,
    );

    // See comment in VerticalAxisContainer constructor
    inputLabelsGenerator = util_labels.DataRangeLabelInfosGenerator(
      chartOrientation: chartOrientation,
      chartStacking: chartStacking,
      chartModel: _chartModel,
      dataDependency: DataDependency.inputData,
      extendAxisToOrigin: extendAxisToOrigin,
      valueToLabel: options.inputValueToLabel,
      inverseTransform: chartOptions.dataContainerOptions.xInverseTransform,
      userLabels: _chartModel.inputUserLabels,
    );
  }

  /// ChartData held before member [chartRootContainer] is created.
  ///
  /// After [chartRootContainer] is created, this member
  /// should be placed on the member [chartRootContainer.ownerChartModel]. todo-010-document this is not right
  ///
  /// Model for this chart. Created before chart, set in concrete [ChartViewModel] in constructor. todo-010-document this is not right
  final model.ChartModel _chartModel;

  @Deprecated('Only use in legacy coded_layout')
  model.ChartModel get chartModelInLegacy => _chartModel;

  // ------------- Public view into ChartModel
  List<model.DataColumnModel> get dataColumnModels => List.from(_chartModel.dataColumnModels);

  int get numRows => _chartModel.numRows;

  model.LegendItem getLegendItemAt(index) => _chartModel.getLegendItemAt(index);

  util_dart.Interval get dataRangeWhenStringLabels => _chartModel.dataRangeWhenStringLabels;
  // -------------

  /// The generator and holder of labels in the form of [LabelInfos],
  /// as well as the range of the axis values.
  ///
  /// Initialized late in this [ChartViewModel] constructor, and held as member
  /// for scaling to pixels in [data_container.DataContainer] and [axis_container.TransposingAxisContainer].
  ///
  /// The [labelsGenerator]'s interval [DataRangeLabelInfosGenerator.dataRange]
  /// is the data range corresponding to the Y axis pixel range kept in [axisPixelsRange].
  ///
  /// Important note: This should NOT be part of model,
  ///                 as different views would have a different instance of it.
  ///                 Reason: Different views may have different labels, esp. on the output (Y) axis.
  late util_labels.DataRangeLabelInfosGenerator outputLabelsGenerator; // todo-010 : can this be late final?

  late util_labels.DataRangeLabelInfosGenerator inputLabelsGenerator; // todo-010 : can this be late final?

  /// Options forwarded from [model.ChartModel] options during this [ChartViewModel]s construction.
  final options.ChartOptions chartOptions;

  final ChartOrientation chartOrientation;

  final ChartStacking chartStacking;

  /// The root container (view) is created by this view model [ChartViewModel]
  /// on every [FlutterChartPainter] paint and repaint.
  ///
  /// While the owner view model survives repaint,
  /// it's member, this [chartRootContainer] is recreated on each repaint in
  /// the following code in [FlutterChartPainter.paint]:
  ///
  /// ```dart
  ///         chartViewModel.chartRootContainerCreateBuildLayoutPaint(canvas, size);
  /// ```
  ///
  /// Because it can be recreated and re-set in [paint], it is not final;
  ///   it's children, [legendContainer], etc are also not final.
  late root_container.ChartRootContainer chartRootContainer;

  /// Layout strategy, necessary to create the concrete view [ChartRootContainer].
  late final strategy.LabelLayoutStrategy inputLabelLayoutStrategyInst;

  /// Keep track of first run. As this [ChartViewModel] survives re-paint (but not first paint),
  /// this can be used to initialize 'late final' members on first paint.
  bool _isFirst = true;

  void chartRootContainerCreateBuildLayoutPaint(ui.Canvas canvas, ui.Size size) {
    // Create the concrete [ChartRootContainer] for this concrete [ChartViewModel].
    // After this invocation, the created root container is populated with children
    // HorizontalAxisContainer, VerticalAxisContainer, DataContainer and LegendContainer. Their children are partly populated,
    // depending on the concrete container. For example VerticalAxisContainer is populated with DataRangeLabelInfosGenerator.

    String isFirstStr = _debugPrintBegin();

    // Create the view [chartRootContainer] and set on member on this view model [ChartViewModel].
    // This happens even on re-paint, so can be done multiple times after state changes in the + button.
    chartRootContainer = makeChartRootContainer(chartViewModel: this); // also link from this ViewModel to ChartRootContainer.

    // Only set `_chartModel.chartViewModel = this` ONCE. Reason: member _chartModel is created ONCE, same as this ANCHOR.
    // To have _chartModel late final, we have to keep track to only initialize _chartModel.chartViewModel = this on first run.
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
  ///  [ChartRootContainer.horizontalAxisContainer], and  [chartRootContainer.chartModelContainer]. // todo-010-doc this is not right?
  ///
  /// If an extension uses an implementation that does not adhere to the above
  /// description, the [ChartRootContainer.layout] should be overridden.
  ///
  /// Important notes:
  ///   - This controller (ViewModel) can access both on ChartRootContainer and ChartModel.
  root_container.ChartRootContainer makeChartRootContainer({
    required covariant ChartViewModel chartViewModel,
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
