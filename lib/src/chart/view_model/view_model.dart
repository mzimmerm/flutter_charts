import 'dart:math' as math show min, max;
import 'dart:ui' as ui show Canvas, Size, Color;
import 'package:logger/logger.dart' as logger;
import 'package:flutter/cupertino.dart' show immutable;
// import 'dart:developer' as dart_developer;

// this level
import 'package:flutter_charts/src/chart/view_model/label_model.dart' as util_labels show DataRangeTicksAndLabelsDescriptor, extendToOrigin;
import 'package:flutter_charts/src/chart/view_model/label_model.dart';

import 'package:flutter_charts/src/util/util_flutter.dart' show FromTransposing2DValueRange;

// morphic
import 'package:flutter_charts/src/morphic/ui2d/point.dart' show PointOffset;
import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart';
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';
import 'package:flutter_charts/src/morphic/container/morphic_dart_enums.dart';
import 'package:flutter_charts/src/morphic/container/constraints.dart' as constraints show BoxContainerConstraints;

import 'package:flutter_charts/src/chart/painter.dart';
import 'package:flutter_charts/src/chart/chart.dart';
import 'package:flutter_charts/src/chart/options.dart' as options show ChartOptions, outputValueToLabel, inputValueToLabel;
import 'package:flutter_charts/src/chart/cartesian/container/data_container.dart' as data_container show DataContainer, BasePointContainer;
import 'package:flutter_charts/src/chart/cartesian/container/container_common.dart' as container_common;
import 'package:flutter_charts/src/chart/cartesian/container/root_container.dart' as root_container show ChartRootContainer;
import 'package:flutter_charts/src/chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy, DefaultIterativeLabelLayoutStrategy;
import 'package:flutter_charts/src/chart/model/data_model.dart' as model show ChartModel, LegendItem;
import 'package:flutter_charts/src/util/util_dart.dart' as util_dart show Interval, assertDoubleResultsSame;
import 'package:flutter_charts/src/util/extensions_dart.dart';

/// Type definition for closures returning a function from model [model.PointModel] 
/// to container [data_container.PointContainer].
typedef ClsPointToNullableContainer = data_container.BasePointContainer? Function (PointModel);

/// Abstract base class for chart view models.
///
/// See [FlutterChart] documentation for chart classes' structure and their lifecycle.
///
/// Roles of this class:
///   1. Provides all data needed for the chart view hierarchy.
///      Data are provided both by pulling from the member [_chartModel] of type [model.ChartModel],
///      but can contain, (or pull, or be notified about), additional view-specific information.
///      One example of such view-specific information is member [chartOrientation], which
///      is not held by [model.ChartModel].
///   2. Creates (produces, generates) the chart view hierarchy,
///      starting with a concrete [root_container.ChartRootContainer].
///
/// This base view model has access to [model.ChartModel] through private [_chartModel].
///
/// This base view model holds as members:
///   - the model in [_chartModel]. It's member [model.ChartModel.chartOptions] provides access to [options.ChartOptions]
///   - the chart orientation in [chartOrientation]
///   - the information whether the chart is presented as stacked values in [chartStacking].
///   - the label layout strategy in [inputLabelLayoutStrategyInst]
///   - [chartRootContainer], the view container hierarchy root. It is created and bound late,
///     in the [chartRootContainerCreateBuildLayoutPaint] invoked during the constructor body of
///     this [ChartViewModel] class. All the above members must be ready and needed for
///     the [chartRootContainer] late creation.
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
    required this.chartType,
    required this.chartOrientation,
    required this.chartStacking,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) : chartOptions = chartModel.chartOptions,
       _chartModel = chartModel {
    logger.Logger().d('Constructing ChartViewModel');

    // Create one [PointsBarModel] for each data column, and add to member [pointsBarModels]
    int columnIndex = 0;
    for (List<double> valuesColumn in chartModel.dataColumns) {
      pointsBarModels.add(
        PointsBarModel(
          valuesColumn: valuesColumn,
          outerChartViewModel: this,
          columnIndex: columnIndex,
        ),
      );

      columnIndex++;
    }

    // Set label layout strategy on member
    inputLabelLayoutStrategy ??= strategy.DefaultIterativeLabelLayoutStrategy(options: _chartModel.chartOptions);
    inputLabelLayoutStrategyInst = inputLabelLayoutStrategy;

    // Create [outputRangeDescriptor] which depends on both ChartModel and ChartRootContainer.
    // We can construct the generator here in [ChartViewModel] constructor or later
    // (e.g. [ChartRootContainer], [VerticalAxisContainer]). But here, in [ChartViewModel] is the first time we can
    // create the [inputRangeDescriptor] and [inputRangeDescriptor] instance of [DataRangeTicksAndLabelsDescriptor], so do that.
    outputRangeDescriptor = util_labels.DataRangeTicksAndLabelsDescriptor(
      chartOrientation: chartOrientation,
      chartStacking: chartStacking,
      chartViewModel: this,
      dataDependency: DataDependency.outputData,
      extendAxisToOrigin: extendAxisToOrigin,
      valueToLabel: options.outputValueToLabel,
      inverseTransform: chartOptions.dataContainerOptions.yInverseTransform,
      userLabels: _chartModel.outputUserLabels,
    );

    // See comment in VerticalAxisContainer constructor
    inputRangeDescriptor = util_labels.DataRangeTicksAndLabelsDescriptor(
      chartOrientation: chartOrientation,
      chartStacking: chartStacking,
      chartViewModel: this,
      dataDependency: DataDependency.inputData,
      extendAxisToOrigin: extendAxisToOrigin,
      valueToLabel: options.inputValueToLabel,
      inverseTransform: chartOptions.dataContainerOptions.xInverseTransform,
      userLabels: _chartModel.inputUserLabels,
    );

    // Convenience wrapper for ranges of input and output values of all chart data
    fromTransposing2DValueRange = FromTransposing2DValueRange(
      inputDataRange: inputRangeDescriptor.dataRange,
      outputDataRange: outputRangeDescriptor.dataRange,
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

  /// The methods [pointsBarModels], [numRows], [getLegendItemAt], [dataRangeWhenStringLabels]
  /// are legacy public views of [ChartViewModel] into [model.ChartModel] and may be removed.
  final List<PointsBarModel> pointsBarModels = [];

  /// For positive [sign], returns max of all columns (more precisely, of all [PointsBarModel]s),
  ///   or 0.0 if there are no positive columns;
  /// for negative [sign]. returns min of all columns or 0.0 if there are no negative columns
  ///
  /// The returned result is equivalent to data values minimum and maximum,
  /// with minimum extended down to 0.0 if there are no negative values,
  /// and maximum extended up to 0.0 if there are no positive values.
  ///
  /// The returned value represents [PointModel.outputValue]s if [isStacked] is false,
  /// their separately positive or negative values stacked if [isStacked] is true
  double extremeValueWithSign(Sign sign, ChartStacking chartStacking) {
    return pointsBarModels
        .map((pointsBarModel) => pointsBarModel.extremeValueWithSign(sign, chartStacking))
        .extremeValueWithSign(sign);
  }

  /// Returns the minimum and maximum transformed, not-extrapolated data values calculated from [ChartModel],
  /// specific for the passed [isStacked].
  ///
  /// The returned value is calculated from [ChartModel] by finding maximum and minimum of data values
  /// in [PointModel] instances, which are added up if the passed [isStacked] is `true`.
  ///
  /// The source data of the returned interval differs in stacked and not-Stacked data, determined by argument [isStacked] :
  ///   - For [chartStacking] == [ChartStacking.stacked],
  ///       the min and max is from [extremeValueWithSign] for positive and negative sign
  ///   - For [chartStacking] == [ChartStacking.nonStacked],
  ///       the min and max is from [_transformedValuesMin] and max.
  ///
  /// Implementation detail: maximum and minimum is calculated column-wise [PointsBarModel] first, but could go
  /// directly to the flattened list of [PointModel] (max and min over partitions is same as over whole set).
  ///
  util_dart.Interval valuesInterval({
    required ChartStacking chartStacking,
  }) {
    switch(chartStacking) {
      case ChartStacking.stacked:
      // Stacked values always start or end at 0.0.isStacked
        return util_dart.Interval(
          extremeValueWithSign(Sign.negative, chartStacking),
          extremeValueWithSign(Sign.positiveOr0, chartStacking),
        );
      case ChartStacking.nonStacked:
      // not-Stacked values can just use values from [ChartModel.dataRows] transformed values.
        return util_dart.Interval(
          _transformedValuesMin,
          _transformedValuesMax,
        );
    }
  }

  /// Returns the interval that envelopes all data values in [ChartModel.dataRows], possibly extended to 0.
  ///
  /// The [isStacked] controls whether the interval is created from values in [PointModel.outputValue]
  /// or their stacked values.
  ///
  /// Whether the resulting Interval is extended from the simple min/max of all data values
  /// is controlled by [extendAxisToOrigin]. If true, the interval is extended to zero
  /// if all values are positive or all values are negative.
  ///
  util_dart.Interval extendedValuesInterval({
    required ChartStacking chartStacking,
    required bool extendAxisToOrigin,
  }) {
    return util_labels.extendToOrigin(
      valuesInterval(chartStacking: chartStacking),
      extendAxisToOrigin,
    );
  }

  /// Data range used when labels are not-numeric.
  ///
  /// Motivation:
  ///   When labels for input values or output values are not-numeric or cannot be
  ///   converted to numeric, there must still be some way to affmap values to pixels.
  ///   This member provides a default 'from' range for such affmap-ing.
  ///
  final util_dart.Interval dataRangeWhenStringLabels = const util_dart.Interval(0.0, 100.0);

  List<double> get _flatten => _chartModel.flattenRows;

  double get _transformedValuesMin =>
      _flatten.map((value) => chartOptions.dataContainerOptions.yTransform(value).toDouble()).reduce(math.min);
  double get _transformedValuesMax =>
      _flatten.map((value) => chartOptions.dataContainerOptions.yTransform(value).toDouble()).reduce(math.max);

  int get numRows => _chartModel.numRows;

  model.LegendItem getLegendItemAt(index) => _chartModel.getLegendItemAt(index);

  /// The generator and holder of labels in the form of [LabelInfos],
  /// as well as the range of the axis values.
  ///
  /// Initialized late in this [ChartViewModel] constructor, and held as member
  /// for scaling to pixels in [data_container.DataContainer] and [axis_container.TransposingAxisContainer].
  ///
  /// The [rangeDescriptor]'s interval [DataRangeTicksAndLabelsDescriptor.dataRange]
  /// is the data range corresponding to the Y axis pixel range kept in [axisPixelsRange].
  ///
  /// Important note: This should NOT be part of model,
  ///                 as different views would have a different instance of it.
  ///                 Reason: Different views may have different labels, esp. on the output (Y) axis.
  late final util_labels.DataRangeTicksAndLabelsDescriptor outputRangeDescriptor;

  late final util_labels.DataRangeTicksAndLabelsDescriptor inputRangeDescriptor;

  /// Wraps the ranges of input values and output values this view model contains.
  late final FromTransposing2DValueRange fromTransposing2DValueRange;

  /// Options forwarded from [model.ChartModel] options during this [ChartViewModel]s construction.
  final options.ChartOptions chartOptions;

  final ChartOrientation chartOrientation;

  final ChartStacking chartStacking;

  final ChartType chartType;

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
    // depending on the concrete container. For example VerticalAxisContainer is populated with DataRangeTicksAndLabelsDescriptor.

    String isFirstStr = _debugPrintBegin();

    // Create the view [chartRootContainer] and set on member on this view model [ChartViewModel].
    // This happens even on re-paint, so can be done multiple times after state changes in the + button.
    chartRootContainer = makeChartRootContainer(chartViewModel: this); // also link from this ViewModel to ChartRootContainer.

    // todo-020 : No longer used, was use to init a 'ChartModel.late final chartViewModel' only once. But no longer needed.
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

  DataRangeTicksAndLabelsDescriptor rangeDescriptorFor(DataDependency dataDependency) {
    switch (dataDependency) {
      case DataDependency.inputData:
        return inputRangeDescriptor;
      case DataDependency.outputData:
        return outputRangeDescriptor;
    }
  }

  DataRangeTicksAndLabelsDescriptor crossRangeDescriptorFor(DataDependency dataDependency) {
    switch (dataDependency) {
      case DataDependency.inputData:
        return outputRangeDescriptor;
      case DataDependency.outputData:
        return inputRangeDescriptor;
    }
  }

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

/// Represents a list of cross-series data values in the [ChartModel], in another words, a column of data values,
/// each data value is a [PointModel].
///
/// As we consider the [ChartModel] to represent a 2D array 'rows first', in other words,
/// 'one data series is a row', with rows (each-series) ordered 'top-to-bottom',
/// columns (cross-series) oriented 'left-to-right', then:
///   - The list of data values in this object represent one column in the 2D array (cross-series values),
///     oriented 'top-to-bottom'.
///   - We can also consider the list of data values represented by
///     this object to be created by diagonal transpose of the [ChartModel.dataRows] and
///     looking at one row in the transpose, left-to-right.
///
/// Note: [PointsBarModel] replaces the [PointsColumn] in legacy layouter.
///
@immutable
class PointsBarModel {

  /// Constructs a model for one bar of points.
  ///
  /// The [valuesColumn] is a cross-series (column-wise) list of data values.
  /// The [outerChartViewModel] is the [ChartModel] underlying the [PointsBarModel] instance being created.
  /// The [columnIndex] is index of the [valuesColumn] in the [outerChartViewModel].
  /// The [numChartModelColumns] allows to later calculate this point's input value using [inputValueOnInputRange],
  ///   which assumes this point is on an axis with data range given by a [util_labels.DataRangeTicksAndLabelsDescriptor]
  ///   instance.
  PointsBarModel({
    required List<double> valuesColumn,
    required this.outerChartViewModel,
    required this.columnIndex,

  }) {
    // Construct data points from the passed [valuesRow] and add each point to member _points
    int rowIndex = 0;
    // Convert the positive/negative values of the passed [valuesColumn], into positive or negative [_dataColumnPoints]
    //   - positive and negative values of the [valuesColumn] are separated to their own [_dataColumnPoints].
    for (double outputValue in valuesColumn) {
      var point = PointModel(
        outputValue: outputValue,
        outerPointsBarModel: this,
        rowIndex: rowIndex,
      );
      pointModelList.add(point);
      rowIndex++;
    }
  }

  /// The full [ChartModel] from which data columns this [PointsBarModel] is created.
  final ChartViewModel outerChartViewModel;

  /// Index of this column (dataColumnPoints list) in the [ChartModel.pointsBarModels].
  ///
  /// Also indexes one column, top-to-bottom, in the two dimensional [ChartModel.].
  /// Also indexes one row, left-to-right, in the `transpose(ChartModel.dataRows)`.
  ///
  /// The data values of this column are stored in the [pointModelList] list,
  /// values and order as in top-to-bottom column in [ChartModel.dataRows].
  ///
  /// This is needed to access the legacy arrays such as:
  ///   -  [ChartModel.byRowLegends]
  ///   -  [ChartModel.byRowColors]
  final int columnIndex;

  /// Calculates inputValue-position (x-position, independent value position) of
  /// instances of this [PointsBarModel] and it's [PointModel] elements.
  ///
  /// The value is in the middle of the column - there are [ChartModel.numColumns] [_numChartModelColumns] columns that
  /// divide the [dataRange].
  ///
  /// Note: So this is offset from start and end of the Interval.
  ///
  /// Late, once [util_labels.DataRangeTicksAndLabelsDescriptor] is established in view model,
  /// we can use the [_numChartModelColumns] and the [util_labels.DataRangeTicksAndLabelsDescriptor.dataRange]
  /// to calculate this value
  double inputValueOnInputRange({
    required util_labels.DataRangeTicksAndLabelsDescriptor dataRangeLabelInfosGenerator,
  }) {
    util_dart.Interval dataRange = dataRangeLabelInfosGenerator.dataRange;
    double columnWidth = (dataRange.length / outerChartViewModel._chartModel.numColumns);
    return (columnWidth * columnIndex) + (columnWidth / 2);
  }

  /// Points in this column are points in one cross-series column.
  final List<PointModel> pointModelList = [];

  /// Returns the [PointsBarModel] for the next column from this [PointsBarModel] instance.
  ///
  /// Should be surrounded with [hasNextColumnModel].
  ///
  /// Throws [StateError] if not such column exists.
  ///
  /// 'Next column' refers to the column with [columnIndex] one more than this [PointsBarModel]s [columnIndex].
  PointsBarModel get nextColumnModel =>
      hasNextColumnModel
          ?
      outerChartViewModel.pointsBarModels[columnIndex + 1]
          :
      throw StateError('No next column for column $this. Use hasNextColumnModel');

  /// Returns true if there is a next column after this [PointsBarModel] instance.
  ///
  /// Should be used before invoking [nextColumnModel].
  bool get hasNextColumnModel => columnIndex < outerChartViewModel._chartModel.numColumns - 1 ? true : false;

  /// Returns minimum or maximum of [PointModel.outputValue]s in me.
  ///
  /// In more detail:
  ///   - For [chartStacking] == [ChartStacking.stacked],  returns added (accumulated) [PointModel.outputValue]s
  ///     for all [PointModel]s in this [PointsBarModel] instance, that have the passed [sign].
  ///   - For [chartStacking] == [ChartStacking.nonStacked]
  ///     - For [sign] positive, returns max of positive [PointModel.outputValue]s
  ///       for all positive [PointModel]s in this [PointsBarModel] instance.
  ///     - For [sign] negative, returns min of negative [PointModel.outputValue]s
  ///       for all negative [PointModel]s in this [PointsBarModel] instance.
  double extremeValueWithSign(Sign sign, ChartStacking chartStacking) {
    switch(chartStacking) {
      case ChartStacking.stacked:
        return _pointsWithSign(sign)
            .map((pointModel) => pointModel.outputValue)
            .fold(0, (prevValue, thisOutputValue) => prevValue + thisOutputValue);
      case ChartStacking.nonStacked:
        return _pointsWithSign(sign)
            .map((pointModel) => pointModel.outputValue)
            .extremeValueWithSign(sign);
    }
  }

  /// Return iterable of my points with the passed sign.
  Iterable<PointModel> _pointsWithSign(Sign sign) {
    if (sign == Sign.any) throw StateError('Method _pointsWithSign is not applicable for Sign.any');

    return pointModelList
        .where((pointModel) => pointModel.sign == sign);
  }
}


/// Base point model serves as a base class for both the actual [PointModel] as well as [FillerPointModel].
///
/// Only needs methods and members invoked in code commonly used by [PointModel] mixed in [FillerPointModel],
/// notably [PointContainer.paint].
///
/// Does NOT need fields (added in [PointModel]):
///   - outputValue
///   - outerPointsBarModel
///   - rowIndex
///   - columnIndex
///
/// Note: @immutable prevented by [pointContainer], see comments there.
abstract class BasePointModel {

  /// The view which presents this [PointModel].
  ///
  /// Important note (design):
  ///   - Container -> ViewModel: We already keep a reference from views (containers) to ViewModels; for example,
  ///     [PointContainer] holds on [PointModel] in [PointContainer.pointModel].
  ///     This reference is created on every [FlutterChartPainter.paint]
  ///     in [ChartViewModel.chartRootContainerCreateBuildLayoutPaint] by the act of rebuilding the
  ///     whole containers hierarchy (view) from the [ChartViewModel] instance.
  ///   - ViewModel -> Container: By holding on the container [pointContainer] in this instance of view model [BasePointModel],
  ///     we also hold on the reversed reference.
  ///     Because the ViewModel lives longer than the container, this reference need to be re-set every time
  ///     the containers hierarchy (view) is rebuild, while the ViewModel [BasePointModel] remains the same.
  ///     As a result, this reference cannot be final.
  ///
  ///
  /// todo-02-design: Ideally, [pointContainer] is final or late final. But that is NOT possible currently,
  ///   because the [ChartViewModel], living as [FlutterChart.chartViewModel]
  ///   (with all it's components ([PointsBarModel], [PointModel] etc)
  ///   lives longer than views/containers ([PointContainer], [PointContainersBar]) which are placed
  ///   on this [pointContainer] reference. So code must be able to set a new [pointContainer]
  ///   during [FlutterChartPainter.paint].
  ///   One way to achieve for [pointContainer] to be final would be to make almost all members
  ///   of [ChartViewModel] non-final, and provide a method ChartViewModel.updateFromModel(ChartModel),
  ///   and call it in [FlutterChartPainter.paint] just before
  ///   ```dart
  ///   chart.chartViewModel.chartRootContainerCreateBuildLayoutPaint(canvas, size);
  ///   ```
  ///   This may be needed anyway, to allow chart rebuild when [model.ChartModel] changes asynchronyously.
  ///
  data_container.BasePointContainer? pointContainer;

  /// Abstract method; implementations should get or calculate the inputValue-position of this [PointModel] instance.
  ///
  /// Delegated to the same name method on [outerPointsBarModel] - the [PointsBarModel.inputValueOnInputRange] -
  /// given the passed [inputDataRangeTicksAndLabelsDescriptor].
  ///
  /// The delegated method divides the input data range into the number of columns,
  /// and places this instance input value in the middle of the column at which this [PointModel] lives.
  ///
  /// See documentation of the delegated  [PointsBarModel.inputValueOnInputRange].
  ///
  /// Motivation:
  ///
  ///   [PointModel]'s inputValue (x values, independent values) is often not-numeric,
  ///   defined by [ChartModel.inputUserLabels] or similar approach, so to get inputValue
  ///   of this instance seems irrelevant or incorrect to ask for.
  ///   However, when positioning a [PointContainer] representing a [PointModel],
  ///   we need to place the [PointModel] an some inputValue, which can be affmap-ed to
  ///   it's pixel display position.  Assigning an inputValue by itself would not help;
  ///   To affmap the inputValue to some pixel value, we need to affix the inputValue
  ///   to a range. This method, [inputValueOnInputRange] does just that:
  ///   Given the passed [inputDataRangeTicksAndLabelsDescriptor], using its data range
  ///   [util_labels.DataRangeTicksAndLabelsDescriptor.dataRange], we can assign an inputValue
  ///   to this [PointModel] by dividing the data range into equal portions,
  ///   and taking the center of the corresponding portion as the returned inputValue.
  ///
  double inputValueOnInputRange({
    required util_labels.DataRangeTicksAndLabelsDescriptor inputDataRangeTicksAndLabelsDescriptor,
  });

  /// Converts this [PointModel] to [PointOffset] with the same output value (the [PointModel.outputValue]
  /// is copied to [PointOffset.outputValue]), and the [PointOffset]'s [PointOffset.inputValue]
  /// created by evenly dividing the passed input range of the passed [inputDataRangeTicksAndLabelsDescriptor].
  PointOffset toPointOffsetOnInputRange({
    required util_labels.DataRangeTicksAndLabelsDescriptor inputDataRangeTicksAndLabelsDescriptor,
  });

  /// Abstract indicates sign of value; intended to be defined in some extensions.
  Sign get sign;

  /// Abstract indicates color representing this point; intended to be defined in some extensions.
  ui.Color get color;

  /// Abstract, implementations should return true if there is a next column after this [PointModel] instance.
  ///
  /// Should be used before invoking [nextPointModel].
  bool get hasNextPointModel;

  /// Abstract, implementations should return the [PointModel]
  /// in the next column of the same row as this [PointModel] instance.
  ///
  /// Call should be surrounded with [hasNextPointModel].
  ///
  /// Throws [StateError] if not such column exists.
  BasePointModel get nextPointModel;

}

/// Represents one data point in the chart data model [ChartModel] and related model classes.
///
/// Notes:
///   - [PointModel] replaces the [StackableValuePoint] in legacy layouter.
///   - Has private access to the outer [ChartModel] to which it belongs through it's member [outerPointsBarModel],
///     which in turn has access to [ChartModel] through it's private [PointsBarModel]
///     member `PointsBarModel._chartModel`.
///     This access is used for model colors and row and column indexes to [ChartModel.dataRows].
///
/// Note: @immutable prevented by [BasePointModel.pointContainer], see comments there.
class PointModel extends BasePointModel {

  // ===================== CONSTRUCTOR ============================================
  /// Constructs instance and from [PointsBarModel] instance [outerPointsBarModel],
  /// and [rowIndex], the index in where the point value [outputValue] is located.
  ///
  /// Important note: The [outerPointsBarModel] value on [rowIndex], IS NOT [outputValue],
  ///                 as the [outerPointsBarModel] is split from [ChartModel.dataColumns] so
  ///                 [rowIndex] can only be used to reach `outerPointsBarModel.chartModel.valuesRows`.
  PointModel({
    required double outputValue,
    required this.outerPointsBarModel,
    required this.rowIndex,
  })
      : outputValue = outerPointsBarModel.outerChartViewModel.chartOptions.dataContainerOptions.yTransform(outputValue).toDouble(),
        sign = outputValue >= 0.0 ? Sign.positiveOr0 : Sign.negative
  {
    util_dart.assertDoubleResultsSame(
      outerPointsBarModel.outerChartViewModel.chartOptions.dataContainerOptions
          .yTransform(outerPointsBarModel.outerChartViewModel._chartModel.dataRows[rowIndex][columnIndex])
          .toDouble(),
      this.outputValue,
    );
  }

  // ===================== NEW CODE ============================================

  /// The *transformed, not-extrapolated* data value from one data item
  /// in the 2D, rows first, [ChartModel.valuesRows] at position [rowIndex].
  ///
  /// This instance of [PointModel] has [outputValue] of the [ChartModel.valuesRows] using the indexes:
  ///   - row at index [rowIndex]
  ///   - column at index [columnIndex], which is also the [outerPointsBarModel]'s
  ///     index [PointsBarModel.columnIndex].
  ///  Those indexes are also a way to access the original for comparisons and asserts in the algorithms.
  final double outputValue;

  /// [Sign] of the [outputValue].
  @override
  final Sign sign;

  /// References the data column (dataColumnPoints list) this point belongs to
  final PointsBarModel outerPointsBarModel;

  /// Refers to the row index in [ChartModel.valuesRows] from which this point was created.
  ///
  /// Also, this point object is kept in [PointsBarModel.pointModelList] at index [rowIndex].
  ///
  /// See [outputValue] for details of the column index from which this point was created.
  final int rowIndex;

  /// Getter of the column index in the [outerPointsBarModel].
  ///
  /// Delegated to [outerPointsBarModel] index [PointsBarModel.columnIndex].
  int get columnIndex => outerPointsBarModel.columnIndex;

  /// See [BasePointModel.nextPointModel] documentation.
  ///
  /// Forwarded to it's member [outerPointsBarModel] method[PointsBarModel.hasNextColumnModel].
  @override
  bool get hasNextPointModel => outerPointsBarModel.hasNextColumnModel;

  /// See [BasePointModel.nextPointModel] documentation.
  ///
  /// 'Next column' refers to the column with [columnIndex] one more than this [PointModel]s [columnIndex].
  @override
  BasePointModel get nextPointModel =>
      hasNextPointModel
          ?
      outerPointsBarModel.nextColumnModel.pointModelList[rowIndex]
          :
      throw StateError('No next column for column $this. Use hasNextPointModel before invoking nextPointModel.');

  /// Once the x labels are established, either as [inputUserLabels] or generated, clients can
  ///  ask for the label.
  Object get inputUserLabel => outerPointsBarModel.outerChartViewModel._chartModel.inputUserLabels[columnIndex];

  @override
  ui.Color get color => outerPointsBarModel.outerChartViewModel.getLegendItemAt(rowIndex).color;

  @override
  double inputValueOnInputRange({
    required util_labels.DataRangeTicksAndLabelsDescriptor inputDataRangeTicksAndLabelsDescriptor,
  }) {
    return outerPointsBarModel.inputValueOnInputRange(
      dataRangeLabelInfosGenerator: inputDataRangeTicksAndLabelsDescriptor,
    );
  }

  @override
  PointOffset toPointOffsetOnInputRange({
    required util_labels.DataRangeTicksAndLabelsDescriptor inputDataRangeTicksAndLabelsDescriptor,
  }) =>
      PointOffset(
        inputValue: inputValueOnInputRange(
          inputDataRangeTicksAndLabelsDescriptor: inputDataRangeTicksAndLabelsDescriptor,
        ),
        outputValue: outputValue,
      );
}


/// A view model used for the [FillerPointContainer].
///
/// See the [FillerPointContainer] documentation.
///
/// Note: @immutable or const (desired here) is prevented by [pointContainer], see comments there.

class FillerPointModel extends BasePointModel {

  @override
  bool get hasNextPointModel => false;

  @override
  BasePointModel get nextPointModel => throw UnsupportedError(
      '$runtimeType: "nextPointModel" should never be invoked. Use "hasNextPointModel" to check before invocation.');

  @override
  Sign get sign => throw UnsupportedError(
      '$runtimeType: "sign" should never be invoked.');

  @override
  ui.Color get color => throw UnsupportedError(
      '$runtimeType: "color" should never be invoked.');

  @override
  double inputValueOnInputRange({
    required util_labels.DataRangeTicksAndLabelsDescriptor inputDataRangeTicksAndLabelsDescriptor,
  }) => throw UnsupportedError(
      '$runtimeType: "inputValueOnInputRange" should never be invoked.');

  @override
  PointOffset toPointOffsetOnInputRange({
    required util_labels.DataRangeTicksAndLabelsDescriptor inputDataRangeTicksAndLabelsDescriptor,
  }) =>throw UnsupportedError(
      '$runtimeType: "toPointOffsetOnInputRange" should never be invoked.');
}