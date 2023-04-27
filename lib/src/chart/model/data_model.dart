import 'dart:math' as math show Random, pow, min, max;
import 'dart:ui' as ui show Color;
import 'package:flutter/cupertino.dart' show immutable;
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';
import 'package:logger/logger.dart' as logger;
import 'package:flutter/material.dart' as material show Colors;

// this level or equivalent
import '../../morphic/container/morphic_dart_enums.dart' show Sign;
import '../../morphic/ui2d/point.dart';
import '../options.dart';

import '../../util/extensions_dart.dart';
import 'label_model.dart' as util_labels;
import '../../util/util_dart.dart';


/// Immutable data viewed in chart.
///
/// Important lifecycle notes:
///   - When [ChartModel] is constructed, the [ChartRootContainerCL] is not available.
///     So in constructor, [ChartModel] cannot be given access to the root container, and it's needed members
///     such as [ChartRootContainerCL.labelsGenerator].
///
/// Legacy Note: Replacement for legacy [ChartData], [PointsColumns],
///              and various holders of dependent data values, including parts of [DataRangeLabelInfosGenerator]
@immutable
class ChartModel {

  // ================ CONSTRUCTOR NEEDS SOME OLD MEMBERS FOR NOW ====================

  ChartModel({
    required this.valuesRows,
    required this.inputUserLabels,
    required this.byRowLegends,
    required this.chartOptions,
    this.outputUserLabels,
    List<ui.Color>? byRowColors,
  })  :
        // Initializing of non-nullable final byRowColors which is a non-required argument
        // must be done in initialized by a non-member function (member methods only in constructor body)
        byRowColors = byRowColors ?? byRowDefaultColors(valuesRows.length) {
    logger.Logger().d('Constructing ChartModel');
    validate();

    valuesColumns = transposeRowsToColumns(valuesRows);

    // Construct the full [ChartModel] as well, so we can use it, and also gradually
    // use it's methods and members in OLD DataContainer.
    // Here, create one [ChartModelSeries] for each data row, and add to member [crossPointsList]
    int columnIndex = 0;
    for (List<double> valuesColumn in valuesColumns) {
      crossPointsModelList.add(
        CrossPointsModel(
          valuesColumn: valuesColumn,
          dataModel: this,
          columnIndex: columnIndex,
        ),
      );

    columnIndex++;
    }
  }

  // NEW CODE =============================================================

  /// List of crossPoints in the model.
  final List<CrossPointsModel> crossPointsModelList = [];

  /// Returns the minimum and maximum transformed, non-extrapolated data values calculated from [ChartModel],
  /// specific for the passed [isStacked].
  ///
  /// The returned value is calculated from [ChartModel] by finding maximum and minimum of data values
  /// in [PointModel] instances, which are added up if the passed [isStacked] is `true`.
  ///
  /// The source data of the returned interval differs in stacked and Non-Stacked data, determined by argument [isStacked] :
  ///   - For [chartStacking] == [ChartStacking.stacked],
  ///       the min and max is from [extremeValueWithSign] for positive and negative sign
  ///   - For [chartStacking] == [ChartStacking.nonStacked],
  ///       the min and max is from [_transformedValuesMin] and max.
  ///
  /// Implementation detail: maximum and minimum is calculated column-wise [CrossPointsModel] first, but could go
  /// directly to the flattened list of [PointModel] (max and min over partitions is same as over whole set).
  ///
  Interval valuesInterval({
    required ChartStacking chartStacking,
  }) {
    switch(chartStacking) {
      case ChartStacking.stacked:
        // Stacked values always start or end at 0.0.isStacked
        return Interval(
          extremeValueWithSign(Sign.negative, chartStacking),
          extremeValueWithSign(Sign.positiveOr0, chartStacking),
        );
      case ChartStacking.nonStacked:
        // Non-Stacked values can just use values from DataModel [_valuesRows] transformed values.
        return Interval(
          _transformedValuesMin,
          _transformedValuesMax,
        );
    }
  }

  /// Returns the interval that envelopes all data values in [ChartModel.valuesRows], possibly extended to 0.
  ///
  /// The [isStacked] controls whether the interval is created from values in [PointModel.outputValue]
  /// or their stacked values.
  ///
  /// Whether the resulting Interval is extended from the simple min/max of all data values
  /// is controlled by [extendAxisToOrigin]. If true, the interval is extended to zero
  /// if all values are positive or all values are negative.
  ///
  Interval extendedValuesInterval({
    required ChartStacking chartStacking,
    required bool extendAxisToOrigin,
  }) {
    return util_labels.extendToOrigin(
      valuesInterval(chartStacking: chartStacking),
      extendAxisToOrigin,
    );
  }

  /// Data range used when labels are non-numeric.
  ///
  /// Motivation:
  ///   When labels for input values or output values are non-numeric or cannot be
  ///   converted to numeric, there must still be some way to lextr values to pixels.
  ///   This member provides a default 'from' range for such lextr-ing.
  ///
  final Interval dataRangeWhenStringLabels = const Interval(0.0, 100.0);

  // OLD CODE =============================================================
  // Legacy stuff below

  // _valuesRows[columnIndex][rowIndex]
  /// Data in rows.
  ///
  /// Each row of data represents one data series.
  /// Legends per row are managed by [byRowLegends].
  ///
  final List<List<double>> valuesRows;

  /// Data reorganized from rows to columns.
  late final List<List<double>> valuesColumns;

  int get numColumns => valuesColumns.length;

  /// Labels on input axis (also named independent axis, x axis).
  ///
  /// It is assumed labels are defined, by the client
  /// and their number is the same as number of points
  /// in each row in [_valuesRows].
  final List<String> inputUserLabels;

  /// The legends for each row in [_valuesRows].
  ///
  /// One Legend String per row.
  /// Alternative name would be "series names".
  final List<String> byRowLegends;

  /// User defined labels to be used by the chart, instead of labels auto-generated from data.
  ///
  /// Can be freehand Strings or numbers converted to Strings.
  /// If not null, a "manual" layout is used in the axis container where it is displayed -
  ///   in the [VerticalAxisContainer] or [HorizontalAxisContainer].
  /// If null, a "auto" layout is used in the axis container where it is displayed.
  ///
  final List<String>? outputUserLabels;

  /// Colors representing each data row (series) in [ChartModel].
  final List<ui.Color> byRowColors;

  /// Chart options of this [ChartModel].
  ///
  /// Motivation: [ChartModel] needs this member as options
  /// affect data transforms and validations.
  final ChartOptions chartOptions;

  // todo-013-performance : cache valuesMax/Min ond also _flatten
  List<double> get _flatten => valuesRows.expand((element) => element).toList();
  double get _valuesMin => _flatten.reduce(math.min);
  // double get _valuesMax => _flatten.reduce(math.max);

  double get _transformedValuesMin =>
      _flatten.map((value) => chartOptions.dataContainerOptions.yTransform(value).toDouble()).reduce(math.min);
  double get _transformedValuesMax =>
      _flatten.map((value) => chartOptions.dataContainerOptions.yTransform(value).toDouble()).reduce(math.max);

  void validate() {
    //                      But that would require ChartOptions available in ChartModel.
    if (!(valuesRows.length == byRowLegends.length)) {
      throw StateError('The number of legend labels provided in parameter "byRowLegends", '
          'does not equal the number of data rows provided in parameter "valuesRows":\n'
          'Detail reason: Row legend labels must be provided in parameter "byRowLegends", '
          'and their number must be the same as number of data rows. '
          'However, in your data definition, that is not the case:\n'
          '   [number of valuesRows: ${valuesRows.length}] != [number of byRowLegends: ${byRowLegends.length}].\n'
          'To fix this: provide ${valuesRows.length} "byRowLegends".');
    }
    if (!(valuesRows.length == byRowColors.length)) {
      throw StateError('The number of legend colors provided in parameter "byRowColors", '
          'does not equal the number of data rows provided in parameter "valuesRows":\n'
          'Detail reason: If not provided in "byRowColors", legend colors are generated. '
          'If the parameter "byRowColors" is provided, '
          'the number of colors must be the same as number of data rows. '
          'However, in your data definition, that is not the case:\n'
          '   [number of valuesRows: ${valuesRows.length}] != [number of byRowColors: ${byRowColors.length}].\n'
          'To fix this: provide ${valuesRows.length} "byRowColors".');
    }
    // Check explicit log10 used in options. This test does not cover user's explicitly declared transforms.
    if (log10 == chartOptions.dataContainerOptions.yTransform) {
      if (!(_valuesMin > 0.0)) {
        throw StateError('Using logarithmic Y scale requires only positive Y data');
      }
    }
  }

  /// For positive [sign], returns max of all columns (more precisely, of all [CrossPointsModel]s),
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
    return crossPointsModelList
        .map((crossPointsModel) => crossPointsModel.extremeValueWithSign(sign, chartStacking))
        .extremeValueWithSign(sign);
  }

}

/// Represents a list of cross-series data values in the [ChartModel], in another words, a column of data values.
///
/// As we consider the [ChartModel] to represent a 2D array 'rows first', in other words,
/// 'one data series is a row', with rows (each-series) ordered 'top-to-bottom',
/// columns (cross-series) oriented 'left-to-right', then:
///   - The list of data values in this object represent one column in the 2D array (cross-series values),
///     oriented 'top-to-bottom'.
///   - We can also consider the list of data values represented by
///     this object to be created by diagonal transpose of the [ChartModel._valuesRows] and
///     looking at one row in the transpose, left-to-right.
///
/// Note: [CrossPointsModel] replaces the [PointsColumn] in legacy layouter.
///
class CrossPointsModel {

  /// Constructs a model for one bar of points.
  ///
  /// The [valuesColumn] is a cross-series (column-wise) list of data values.
  /// The [dataModel] is the [DataModel] underlying the [CrossPointsModel] instance being created.
  /// The [columnIndex] is index of the [valuesColumn] in the [dataModel].
  /// The [numDataModelColumns] allows to later calculate this point's input value using [inputValueOnInputRange],
  ///   which assumes this point is on an axis with data range given by a [util_labels.DataRangeLabelInfosGenerator]
  ///   instance.
  CrossPointsModel({
    required List<double> valuesColumn,
    required this.dataModel,
    required this.columnIndex,
  }) {
    // Construct data points from the passed [valuesRow] and add each point to member _points
    int rowIndex = 0;
    // Convert the positive/negative values of the passed [valuesColumn], into positive or negative [_crossPoints]
    //   - positive and negative values of the [valuesColumn] are separated to their own [_crossPoints].
    for (double outputValue in valuesColumn) {
      var point = PointModel(
        outputValue: outputValue,
        ownerCrossPointsModel: this,
        rowIndex: rowIndex,
      );
      crossPointsAllElements.add(point);
      rowIndex++;
    }
  }

  /// The full [ChartModel] from which data columns this [CrossPointsModel] is created.
  final ChartModel dataModel;

  /// Index of this column (crossPoints list) in the [ChartModel.crossPointsModelList].
  ///
  /// Also indexes one column, top-to-bottom, in the two dimensional [ChartModel.valuesRows].
  /// Also indexes one row, left-to-right, in the `transpose(ChartModel.valuesRows)`.
  ///
  /// The data values of this column are stored in the [crossPointsAllElements] list,
  /// values and order as in top-to-bottom column in [ChartModel.valuesRows].
  ///
  /// This is needed to access the legacy arrays such as:
  ///   -  [ChartModel.byRowLegends]
  ///   -  [ChartModel.byRowColors]
  final int columnIndex;

  /// Calculates inputValue-position (x-position, independent value position) of
  /// instances of this [CrossPointsModel] and it's [PointModel] elements.
  ///
  /// The value is in the middle of the column - there are [ChartModel.numColumns] [_numDataModelColumns] columns that
  /// divide the [dataRange].
  ///
  /// Note: So this is offset from start and end of the Interval.
  ///
  /// Late, once [util_labels.DataRangeLabelInfosGenerator] is established in view maker,
  /// we can use the [_numDataModelColumns] and the [util_labels.DataRangeLabelInfosGenerator.dataRange]
  /// to calculate this value
  double inputValueOnInputRange({
    required util_labels.DataRangeLabelInfosGenerator dataRangeLabelInfosGenerator,
  }) {
    Interval dataRange = dataRangeLabelInfosGenerator.dataRange;
    double columnWidth = (dataRange.length / dataModel.numColumns);
    return (columnWidth * columnIndex) + (columnWidth / 2);
  }

  /// Points of this positive or negative column (crossPoints).
  final List<PointModel> crossPointsAllElements = [];

  /// Returns data minimum or maximum.
  ///
  /// In more detail:
  ///   - For [chartStacking] == [ChartStacking.stacked],  returns added (accumulated) [PointModel.outputValue]s
  ///     for all [PointModel]s in this [CrossPointsModel] instance, that have the passed [sign].
  ///   - For [chartStacking] == [ChartStacking.nonStacked]
  ///     - For [sign] positive, returns max of positive [PointModel.outputValue]s
  ///       for all positive [PointModel]s in this [CrossPointsModel] instance.
  ///     - For [sign] negative, returns min of negative [PointModel.outputValue]s
  ///       for all negative [PointModel]s in this [CrossPointsModel] instance.
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

  /// Return iterable of my points with the passed sign
  Iterable<PointModel> _pointsWithSign(Sign sign) {
    if (sign == Sign.any) throw StateError('Method _pointsWithSign is not applicable for Sign.any');

    return crossPointsAllElements
        .where((pointModel) => pointModel.sign == sign);
  }
}

/// Represents one data point in the chart data model [ChartModel] and related model classes.
///
/// Notes:
///   - [PointModel] replaces the [StackableValuePoint] in legacy layouter.
///   - Has private access to the owner [ChartModel] to which it belongs through it's member [ownerCrossPointsModel],
///     which in turn has access to [ChartModel] through it's member [CrossPointsModel._dataModel].
///     This access is used for model colors and row and column indexes to [ChartModel.valuesRows].
///
class PointModel {

  // ===================== CONSTRUCTOR ============================================
  /// Constructs instance from the owner [CrossPointsModel] instance [ownerCrossPointsModel],
  /// and [rowIndex], the index in where the point value [outputValue] is located.
  ///
  /// Important note: The [ownerCrossPointsModel] value on [rowIndex], IS NOT [outputValue],
  ///                 as the [ownerCrossPointsModel] is split from [ChartModel.dataColumns] so
  ///                 [rowIndex] can only be used to reach `ownerCrossPointsModel.dataModel.valuesRows`.
  PointModel({
    required double outputValue,
    required this.ownerCrossPointsModel,
    required this.rowIndex,
  }) {
    this.outputValue = ownerCrossPointsModel.dataModel.chartOptions.dataContainerOptions.yTransform(outputValue).toDouble();

    if (outputValue >= 0.0) {
      sign = Sign.positiveOr0;
    } else {
      sign = Sign.negative;
    }

    assertDoubleResultsSame(
      ownerCrossPointsModel.dataModel.chartOptions.dataContainerOptions
          .yTransform(ownerCrossPointsModel.dataModel.valuesRows[rowIndex][columnIndex])
          .toDouble(),
      this.outputValue,
    );

  }

  // ===================== NEW CODE ============================================

  /// The original (transformed, not-extrapolated) data value from one data item
  /// in the 2D, rows first, list of (output) values [ChartModel.valuesRows].
  ///
  /// This instance of [PointModel] has [outputValue] of the [ChartModel.valuesRows] using the indexes:
  ///   - row at index [rowIndex]
  ///   - column at index [columnIndex], which is also the [ownerCrossPointsModel]'s
  ///     index [CrossPointsModel.columnIndex].
  ///  Those indexes are also a way to access the original for comparisons and asserts in the algorithms.
  late final double outputValue;

  /// [Sign] of the [outputValue].
  late final Sign sign;

  /// References the data column (crossPoints list) this point belongs to
  CrossPointsModel ownerCrossPointsModel;

  /// Refers to the row index in [ChartModel.valuesRows] from which this point was created.
  ///
  /// Also, this point object is kept in [CrossPointsModel.crossPointsAllElements] at index [rowIndex].
  ///
  /// See [outputValue] for details of the column index from which this point was created.
  final int rowIndex;

  /// Getter of the column index in the owner [ownerCrossPointsModel].
  ///
  /// Delegated to [ownerCrossPointsModel] index [CrossPointsModel.columnIndex].
  int get columnIndex => ownerCrossPointsModel.columnIndex;

  /// Gets or calculates the inputValue-position (x value) of this [PointModel] instance.
  ///
  /// Motivation:
  ///
  ///   [PointModel]'s inputValue (x values, independent values) is often non-numeric,
  ///   defined by [ChartModel.inputUserLabels] or similar approach, so to get inputValue
  ///   of this instance seems irrelevant or incorrect to ask for.
  ///   However, when positioning a [PointContainer] representing a [PointModel],
  ///   we need to place the [PointModel] an some inputValue, which can be lextr-ed to
  ///   it's pixel display position.  Assigning an inputValue by itself would not help;
  ///   To lextr the inputValue to some pixel value, we need to affix the inputValue
  ///   to a range. This method, [inputValueOnInputRange] does just that:
  ///   Given the passed [dataRangeLabelInfosGenerator], using its data range
  ///   [util_labels.DataRangeLabelInfosGenerator.dataRange], we can assign an inputValue
  ///   to this [PointModel] by dividing the data range into equal portions,
  ///   and taking the center of the corresponding portion as the returned inputValue.
  ///
  /// Delegated to [ownerCrossPointsModel].
  double inputValueOnInputRange({
    required util_labels.DataRangeLabelInfosGenerator dataRangeLabelInfosGenerator,
  }) {
    return ownerCrossPointsModel.inputValueOnInputRange(
      dataRangeLabelInfosGenerator: dataRangeLabelInfosGenerator,
    );
  }

  /// Once the x labels are established, either as [inputUserLabels] or generated, clients can
  ///  ask for the label.
  Object get inputUserLabel => ownerCrossPointsModel.dataModel.inputUserLabels[columnIndex];

  ui.Color get color => ownerCrossPointsModel.dataModel.byRowColors[rowIndex];

  PointOffset asPointOffsetOnInputRange({
    required util_labels.DataRangeLabelInfosGenerator dataRangeLabelInfosGenerator,
  }) =>
      PointOffset(
        inputValue: inputValueOnInputRange(
          dataRangeLabelInfosGenerator: dataRangeLabelInfosGenerator,
        ),
        outputValue: outputValue,
      );
}

// -------------------- Functions

// To initialize default colors with dynamic list that allows the colors NOT null, initialization must be done in
//  initializer list (it is too late in constructor, by then, the colors list would have to be NULLABLE).
/// Sets up colors for legends, first several explicitly, rest randomly.
///
/// This is used if user does not set colors.
List<ui.Color> byRowDefaultColors(int valuesRowsCount) {
  List<ui.Color> rowsColors = List.empty(growable: true);

  if (valuesRowsCount >= 1) {
    rowsColors.add(material.Colors.yellow);
  }
  if (valuesRowsCount >= 2) {
    rowsColors.add(material.Colors.green);
  }
  if (valuesRowsCount >= 3) {
    rowsColors.add(material.Colors.blue);
  }
  if (valuesRowsCount >= 4) {
    rowsColors.add(material.Colors.black);
  }
  if (valuesRowsCount >= 5) {
    rowsColors.add(material.Colors.grey);
  }
  if (valuesRowsCount >= 6) {
    rowsColors.add(material.Colors.orange);
  }
  if (valuesRowsCount > 6) {
    for (int i = 3; i < valuesRowsCount; i++) {
      int colorHex = math.Random().nextInt(0xFFFFFF);
      int opacityHex = 0xFF;
      rowsColors.add(ui.Color(colorHex + (opacityHex * math.pow(16, 6)).toInt()));
    }
  }
  return rowsColors;
}
