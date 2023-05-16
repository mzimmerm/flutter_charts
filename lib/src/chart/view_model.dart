import 'dart:ui' as ui show Canvas, Size;

import 'package:flutter_charts/src/chart/chart.dart';
import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart';
import 'package:flutter_charts/src/util/util_flutter.dart' show FromTransposing2DValueRange;

import 'painter.dart';
import 'package:logger/logger.dart' as logger;

// import 'dart:developer' as dart_developer;

import '../morphic/container/chart_support/chart_style.dart';
import '../morphic/container/morphic_dart_enums.dart';
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

/// Abstract base class for chart view models.
///
/// See [FlutterChart] documentation for chart classes' structure and their lifecycle.
///
/// Roles of this class:
///   1. Provides all data needed for the chart view hierarchy.
///      Data are provided both by pulling from the member [_chartModel],
///      but can contain, (or pull, or be notified about), additional view-specific information.
///      One example of such view-specific information is member [chartOrientation].
///   2. Creates (produces, generates) the chart view hierarchy,
///      starting with a concrete [root_container.ChartRootContainer].
///
/// This base view model has access to [model.ChartModel] through private [_chartModel].
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
/// [ChartViewModel] instance provides a 'reference link' between the [ChartModel],
///   and the chart root [BoxContainer], the [root_container.ChartRootContainer],
///   through it's members:
///   - [_chartModel], reference -> to [ChartModel]
///   - [chartRootContainer], reference -> to [root_container.ChartRootContainer]
///
/// Core methods of [ChartViewModel] are
///   - [chartRootContainerCreateBuildLayoutPaint], which should be called in [FlutterChartPainter.paint];
///     this method creates, builds, lays out, and paints
///     the root of the chart container hierarchy, the [chartRootContainer].
///   - abstract [makeChartRootContainer]; from it, the extensions of [ChartViewModel]
///     (for example, [LineChartViewModel]) should create and return an instance of the concrete [chartRootContainer]
///     (for example [LineChartRootContainer]).
///
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

    // Convenience wrapper for ranges of input and output values of all chart data
    fromTransposing2DValueRange = FromTransposing2DValueRange(
      inputDataRange: inputLabelsGenerator.dataRange,
      outputDataRange: outputLabelsGenerator.dataRange,
      chartOrientation: chartOrientation,
    );
  }

  /// Privately held chart model through which every instance of this [ChartViewModel] should obtain data
  /// and data updates. Must be initialized before member [chartRootContainer] is created.
  ///
  /// See top doc for [ChartViewModel] and doc for [FlutterChart] for chart structure and lifecycle.
  final model.ChartModel _chartModel;

  @Deprecated('Only use in legacy coded_layout')
  model.ChartModel get chartModelInLegacy => _chartModel;

  /// The methods [dataColumnModels], [numRows], [getLegendItemAt], [dataRangeWhenStringLabels]
  /// are legacy public views of [ChartViewModel] into [model.ChartModel] and may be removed.
  List<model.DataColumnModel> get dataColumnModels => List.from(_chartModel.dataColumnModels);

  int get numRows => _chartModel.numRows;

  model.LegendItem getLegendItemAt(index) => _chartModel.getLegendItemAt(index);

  util_dart.Interval get dataRangeWhenStringLabels => _chartModel.dataRangeWhenStringLabels;

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
  ///                 // todo-010 : rename to outputTicksAndLabelsDefiner
  late final util_labels.DataRangeLabelInfosGenerator outputLabelsGenerator;

  ///                 // todo-010 : rename to inputTicksAndLabelsDefiner
  late final util_labels.DataRangeLabelInfosGenerator inputLabelsGenerator;

  /// Wraps the ranges of input values and output values this view model contains.
  late final FromTransposing2DValueRange fromTransposing2DValueRange;

  /// Options forwarded from [model.ChartModel] options during this [ChartViewModel]s construction.
  final options.ChartOptions chartOptions;

  final ChartOrientation chartOrientation;

  final ChartStacking chartStacking;

  /// The root container (view) is created by this view model [ChartViewModel]
  /// on every [FlutterChartPainter] paint and repaint.
  ///
  /// While the owner [ChartViewModel] instance survives repaint,
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

  /// Should create a concrete instance of [root_container.ChartRootContainer],
  /// which is the view of this [ChartViewModel].
  ///
  /// Caller should bind the returned value to member [chartRootContainer].
  ///
  /// Generally, the created [root_container.ChartRootContainer]'s immediate children and deeper
  /// children of the [root_container.ChartRootContainer] may be created either in this method,
  /// as part of [root_container.ChartRootContainer]'s creation, or hierarchically,
  /// in [BoxContainer.buildAndReplaceChildren] which is invoked later, during [layout].
  ///
  /// In the default implementations, the [chartRootContainer]'s children created are
  /// [root_container.ChartRootContainer.legendContainer],  [root_container.ChartRootContainer.verticalAxisContainer],
  ///  [root_container.ChartRootContainer.horizontalAxisContainer],
  ///  and [root_container.ChartRootContainer.dataContainer].
  ///
  /// If an extension uses an implementation that does not adhere to the above
  /// description, the [ChartRootContainer.layout] should be overridden.
  ///
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
