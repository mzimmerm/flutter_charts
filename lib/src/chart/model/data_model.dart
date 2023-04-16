import 'dart:math' as math show Random, pow, min, max;
import 'dart:ui' as ui show Color;
// import 'package:flutter/cupertino.dart';
import 'package:flutter_charts/src/morphic/ui2d/point.dart';
import 'package:logger/logger.dart' as logger;
import 'package:flutter/material.dart' as material show Colors;

// this level or equivalent
import '../../morphic/container/container_layouter_base.dart';
import '../options.dart';

import '../../util/extensions_dart.dart';
import '../../util/util_labels.dart' as util_labels;
import '../../util/util_dart.dart';


// todo-doc-01 document Copied from [ChartData], it is a replacement for both legacy [ChartData], [PointsColumns],
//                   and various holders of Y data values, including some parts of [DataRangeLabelInfosGenerator]
/// Notes:
///   - DATA MODEL SHOULD NOT HAVE ACCESS TO ANY OBJECTS THAT HAVE TO DO WITH
///     - Extrapolating OF MODEL VALUES (does not)
///     - COLORS   (currently does)
///     - LABELS   (currently does)
///     - LEGENDS  (currently does)
///     - OPTIONS  (currently does)
///     THOSE OBJECTS SHOULD BE ACCESSED FROM CONTAINER EXTENSIONS FOR extrapolating, OFFSET AND PAINTING.
///
/// Important lifecycle notes:
///   - When [ChartModel] is constructed, the [ChartRootContainerCL] is not available.
///     So in constructor, [ChartModel] cannot be given access to the root container, and it's needed members
///     such as [ChartRootContainerCL.labelsGenerator].
class ChartModel {

  // ================ CONSTRUCTOR NEEDS SOME OLD MEMBERS FOR NOW ====================

  ChartModel({
    required this.valuesRows,
    required this.xUserLabels,
    required this.byRowLegends,
    required this.chartOptions,
    this.yUserLabels,
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
    int numDataModelColumns = valuesColumns.length;
    int columnIndex = 0;
    for (List<double> valuesColumn in valuesColumns) {
      crossPointsModelPositiveList.add(
        CrossPointsModel(
          valuesColumn: valuesColumn,
          dataModel: this,
          columnIndex: columnIndex,
          numDataModelColumns: numDataModelColumns,
          pointsSign: CrossPointsModelPointsSign.positiveOr0,
        ),
      );
      crossPointsModelNegativeList.add(
        CrossPointsModel(
          valuesColumn: valuesColumn,
          dataModel: this,
          columnIndex: columnIndex,
          numDataModelColumns: numDataModelColumns,
          pointsSign: CrossPointsModelPointsSign.negative,
        ),
      );

    columnIndex++;
    }
  }

  // NEW CODE =============================================================

  /// List of crossPoints in the model.
  ///
  /// Represents one bar-set in the chart. The bar-set is a single bar in stacked bar chart,
  /// several grouped bars for non-stacked bar chart.
  final List<CrossPointsModel> crossPointsModelPositiveList = [];
  final List<CrossPointsModel> crossPointsModelNegativeList = [];

  /// Returns the minimum and maximum non-extrapolated, transformed data values calculated from [ChartModel],
  /// specific for the passed [isStacked].
  ///
  /// The returned value is calculated from [ChartModel] by finding maximum and minimum of data values
  /// in [PointModel] instances, which are added up if the passed [isStacked] is `true`.
  ///
  /// The source data of the returned interval differs in stacked and non-stacked data, determined by argument [isStacked] :
  ///   - For [isStacked] true, the min and max is taken from [PointModel._stackedPositiveOutputValue] and
  ///     [PointModel._stackedNegativeOutputValue] is used.
  ///   - For  [isStacked] false, the min and max is taken from [PointModel.outputValue] is used.
  ///
  /// Implementation detail: maximum and minimum is calculated column-wise [CrossPointsModel] first, but could go
  /// directly to the flattened list of [PointModel] (max and min over partitions is same as over whole set).
  ///
  Interval valuesInterval({
    required bool isStacked,
  }) {
    if (isStacked) {
      // Stacked values always start or end at 0.0. 
      return Interval(
        crossPointsModelNegativeList.map((pointsColumn) => pointsColumn._stackedValue).reduceOrElse(math.min, orElse: () => 0.0),
        crossPointsModelPositiveList.map((pointsColumn) => pointsColumn._stackedValue).reduceOrElse(math.max, orElse: () => 0.0),
      );
    } else {
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
  /// or the stacked values [PointModel._stackedPositiveOutputValue] and
  /// [PointModel._stackedNegativeOutputValue]
  ///
  /// Whether the resulting Interval is extended from the simple min/max of all data values
  /// is controlled by [extendAxisToOrigin]. If [true] the interval is extended to zero
  /// if all values are positive or all are negative.
  ///
  Interval extendedValuesInterval({
    required bool isStacked,
    required bool extendAxisToOrigin,
  }) {
    return util_labels.extendToOrigin(
      valuesInterval(isStacked: isStacked),
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

  /// Labels on independent (X) axis.
  ///
  /// It is assumed labels are defined, by the client
  /// and their number is the same as number of points
  /// in each row in [_valuesRows].
  final List<String> xUserLabels;

  /// The legends for each row in [_valuesRows].
  ///
  /// One Legend String per row.
  /// Alternative name would be "series names".
  final List<String> byRowLegends;

  /// User defined labels to be used by the chart, instead of labels auto-generated from data.
  ///
  /// Can be Strings or numbers.
  /// If not null, a "manual" layout is used in the [YContainerCL].
  /// If null, a "auto" layout is used in the [YContainerCL].
  ///
  final List<String>? yUserLabels;

  /// Colors representing each data row (series) in [ChartModel].
  final List<ui.Color> byRowColors;

  /// Chart options of this [ChartModel].
  ///
  /// Motivation: [ChartModel] needs this member as options
  /// affect data transforms and validations.
  final ChartOptions chartOptions;

  // todo-011-performance : cache valuesMax/Min ond also _flatten
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

}

/// On behalf of [CrossPointsModel], represents the sign of the values of [PointModel] points
/// which should be added to the [CrossPointsModel].
///
/// Motivation: In order to display both negative and positive values on the bar chart or line chart,
///             the [ChartModel] manages the positive and negative values separately in
///             [ChartModel.crossPointsModelPositiveList] and [ChartModel.crossPointsModelNegativeList].
///             This enum supports creating and later using (processing, view making) the positive and negative
///             bars separately.
enum CrossPointsModelPointsSign {
  positiveOr0,
  negative,
  // todo-00-refactoring : remove 'any', not used in any sensible way.
  any,
}

/// Represents a list of cross-series data values in the [ChartModel], in another words, a column of data values,
/// which are all either positive (non-negative to be precise) or negative, depending on the
/// passed [pointsSign].
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
/// Note: [CrossPointsModel] replaces [PointsColumn].
///
class CrossPointsModel extends Object with DoubleLinkedOwner<PointModel> {

  /// Constructs a model for one bar of points.
  ///
  /// The [valuesColumn] is a cross-series (column-wise) list of data values.
  /// The [dataModel] is the [DataModel] underlying the [CrossPointsModel] instance being created.
  /// The [columnIndex] is index of the [valuesColumn] in the [dataModel].
  /// The [numDataModelColumns] allows to later calculate this point's input value using [inputValueOnInputRange],
  ///   which assumes this point is on an axis with data range given by a [util_labels.DataRangeLabelInfosGenerator]
  ///   instance.
  /// The [pointsSign] specifies whether positive or negative values
  ///   are placed in the [CrossPointsModel] instance being created.
  CrossPointsModel({
    required List<double> valuesColumn,
    required this.dataModel,
    required this.columnIndex,
    required numDataModelColumns,
    required this.pointsSign
  }) : _numDataModelColumns = numDataModelColumns {
    // Construct data points from the passed [valuesRow] and add each point to member _points
    int rowIndex = 0;
    // Convert the positive/negative values of the passed [valuesColumn], into positive or negative [_crossPoints]
    //   - positive and negative values of the [valuesColumn] are separated to their own [_crossPoints].
    for (double outputValue in valuesColumn) {
      if (__isValueMySign(
        value: outputValue,
      )) {
        var point = PointModel(
          outputValue: outputValue,
          ownerCrossPointsModel: this,
          rowIndex: rowIndex,
        );
        _crossPoints.add(point);
      }
      rowIndex++;
    }
    // Now all values in [valuesColumn] are converted to [PointModel]s and models added
    // to [_crossPoints] (which back [allElements]), we can double-link the [_crossPoints].
    // We just need one point to start linking - we use this [DoubleLinkedOwner.firstLinked].
    if (_crossPoints.isNotEmpty) {
      firstLinked().linkAll();
      // Once the owned DoubleLinked data points are linked, we can do iteration operations of them, such as stacking.

      // Calculate and initialize stacked point values of this column of points.
      applyOnAllElements(
        __stackPoints,
        this,
      );
    }
  }

  /// Owner [ChartModel] to which this [CrossPointsModel] bar belongs by existence in
  ///  [ChartModel.crossPointsModelPositiveList] AND the [ChartModel.crossPointsModelNegativeList].
  ///
  final ChartModel dataModel;

  /// Index of this column (crossPoints list) in the [ChartModel.crossPointsModelPositiveList] AND
  /// the  [ChartModel.crossPointsModelNegativeList].
  ///
  /// Also indexes one column, top-to-bottom, in the two dimensional [ChartModel.valuesRows].
  /// Also indexes one row, left-to-right, in the `transpose(ChartModel.valuesRows)`.
  ///
  /// The data values of this column are stored in the [_crossPoints] list,
  /// values and order as in top-to-bottom column in [ChartModel.valuesRows].
  ///
  /// This is needed to access the legacy arrays such as:
  ///   -  [ChartModel.byRowLegends]
  ///   -  [ChartModel.byRowColors]
  final int columnIndex;

  /// Number of column-wise elements the owner [ChartModel] has.
  ///
  /// Same as size of [ChartModel.crossPointsModelPositiveList] AND the [ChartModel.crossPointsModelNegativeList].
  /// It is provided early in constructor of this [CrossPointsModel],
  /// so it can be used before these two lists are fully constructed and populated with
  /// instances of [CrossPointsModel].
  ///
  /// This is also accessible by [PointModel]
  final int _numDataModelColumns;

  /// Calculates inputValue-position (x-position, independent value position) of
  /// instances of this [CrossPointsModel] and it's [PointModel] elements.
  ///
  /// The value is in the middle of the column - there are [_numDataModelColumns] columns that
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
    double columnWidth = (dataRange.length / _numDataModelColumns);
    return (columnWidth * columnIndex) + (columnWidth / 2);
  }

  /// Sign that all [PointModel]s in this [CrossPointsModel] must have.
  ///
  /// Sign is represented by [CrossPointsModelPointsSign].
  ///
  /// Motivation: The model of any chart maintains separate member for positive and negative values
  ///             in the same cross-series data column in [ChartModel] - the [crossPointsModelPositiveList]
  ///             and the [crossPointsModelNegativeList]. This member allows to separate
  ///             values in each cross-series data column into the positives and negatives.
  late final CrossPointsModelPointsSign pointsSign;

  /// Points of this positive or negative column (crossPoints).
  ///
  /// The points are needed to provide the [allElements] method, which answers the list of
  /// all [DoubleLinked] elements owned by this [DoubleLinkedOwner].
  /// At the same time, the points are all [PointModel] in this positive or negative column
  /// (crossPoints list).
  final List<PointModel> _crossPoints = [];

  /// Implements the [DoubleLinkedOwner] abstract method which provides all elements for
  /// the owned [DoubleLinked] instances of [PointModel].
  @override
  Iterable<PointModel> allElements() => _crossPoints;

  /// Checks if the sign of a the passed [value] is the sign required by this instance of [CrossPointsModel].
  ///
  /// Motivation: In the context of a charting framework, any series positive and negative
  ///             values are split and kept separate in model and in view containers,
  ///             using separate instances of positive and negative [CrossPointsModel]s,
  ///             in [ChartModel.crossPointsModelPositiveList] and [ChartModel.crossPointsModelNegativeList].
  ///             This method is a helper to performs the separation based on [pointsSign].
  bool __isValueMySign({
    required double value,
  }) {
    switch (pointsSign) {
      case CrossPointsModelPointsSign.any:
        return true;
      case CrossPointsModelPointsSign.positiveOr0:
        return (value >= 0.0);
      case CrossPointsModelPointsSign.negative:
        return (value < 0.0);
    }
  }

  /// Calculates and initializes the final stacked positive and negative values on points.
  ///
  /// Assumes that [DoubleLinked.linkAll] has been called on first element on the [_crossPoints],
  /// which is the backing list of this [DoubleLinkedOwner]'s  [allElements].
  ///
  /// Only makes practical sense if all [_crossPoints] are either positive or negative,
  /// see [CrossPointsModelPointsSign].
  __stackPoints(PointModel point, unused) {
    assert(pointsSign != CrossPointsModelPointsSign.any);

    if (point.hasPrevious) {
      point._stackedOutputValue = point.previous._stackedOutputValue + point.outputValue;
    } else {
      // first element
      point._stackedOutputValue = point.outputValue;
    }
  }

  /// Returns value-height of this column from (transformed, non-extrapolated) data values of points.
  double get _stackedValue {
    switch (pointsSign) {
      case CrossPointsModelPointsSign.any:
        throw StateError('Cannot stack value on CrossPointsModel with mixed signs');
      case CrossPointsModelPointsSign.positiveOr0:
        return __maxOnPoints((PointModel point) => point._stackedOutputValue);
      case CrossPointsModelPointsSign.negative:
        return __minOnPoints((PointModel point) => point._stackedOutputValue);
    }
  }

  double __maxOnPoints(double Function(PointModel) getNumFromPoint) {
    return __applyFolderOnPoints(getNumFromPoint, math.max);
  }

  double __minOnPoints(double Function(PointModel) getNumFromPoint) {
    return __applyFolderOnPoints(getNumFromPoint, math.min);
  }

  /// Apply the fold performed by [folder] (double, double) => double function,
  /// on some double values from the owned [allElements] which are [DoubleLinked] and [PointModel]s.
  ///
  /// The double values are pulled from each [PointModel]
  /// using the [getNumFromPoint] (PointModel) => double function.
  ///
  double __applyFolderOnPoints(
    double Function(PointModel) getNumFromPoint,
    double Function(double, double) folder,
  ) {
    _DoubleValue result = _DoubleValue();
    applyOnAllElements(
      (PointModel point, result) {
        if (!point.hasPrevious) {
          result.value = getNumFromPoint(point);
        } else {
          result.value = folder(result.value as double, getNumFromPoint(point));
        }
        // print('result = ${result.value}');
      },
      result,
    );
    return result.value;
  }

  /*
  double get _stackedPositiveValue => __maxOnPoints((PointModel point) => point._stackedPositiveOutputValue);
  double get _stackedNegativeValue => __minOnPoints((PointModel point) => point._stackedNegativeOutputValue);
  double get _minPointValue         => __minOnPoints((PointModel point) => point.outputValue);
  double get _maxPointValue         => __maxOnPoints((PointModel point) => point.outputValue);

  late final double _stackedPositiveOutputValue;
  late final double _stackedNegativeOutputValue;

  __stackPoints(PointModel point, unused) {
    if (point.hasPrevious) {
      if (point.outputValue < 0.0) {
        point._stackedNegativeOutputValue = point.previous._stackedNegativeOutputValue + point.outputValue;
        point._stackedPositiveOutputValue = point.previous._stackedPositiveOutputValue;
      } else {
        point._stackedPositiveOutputValue = point.previous._stackedPositiveOutputValue + point.outputValue;
        point._stackedNegativeOutputValue = point.previous._stackedNegativeOutputValue;
      }
    } else {
      // first element
      if (point.outputValue < 0.0) {
        point._stackedNegativeOutputValue = point.outputValue;
        point._stackedPositiveOutputValue = 0.0;
      } else {
        point._stackedNegativeOutputValue = 0.0;
        point._stackedPositiveOutputValue = point.outputValue;
      }
    }
  }
  */

}

/// Represents one data point in the chart data model [ChartModel] and related model classes.
///
/// Replaces the legacy [StackableValuePoint].
///
/// Notes:
///   - Has private access to the owner [ChartModel] to which it belongs through it's member [ownerCrossPointsModel],
///     which in turn has access to [ChartModel] through it's member [CrossPointsModel._dataModel].
///     This access is used for model colors and row and column indexes to [ChartModel.valuesRows].
///
class PointModel extends Object with DoubleLinked {

  // ===================== CONSTRUCTOR ============================================
  /// Constructs instance from the owner [CrossPointsModel] instance [ownerCrossPointsModel],
  /// and [rowIndex], the index in where the point value [outputValue] is located.
  ///
  /// Important note: The [ownerCrossPointsModel] value on [rowIndex], IS NOT [outputValue],
  ///                 as the [ownerCrossPointsModel] is split from [ChartModel.dataColumns] so
  ///                 [rowIndex] can only be used to reach `ownerCrossPointsModel.dataModel.valuesRows`.
  PointModel({
    // required this.outputValue,
    required double outputValue,
    required this.ownerCrossPointsModel,
    required this.rowIndex,
  }) {
    // The ownerSeries is ChartModelSeries which is DoubleLinkedOwner
    // of all [PointModel]s, managed by [DoubleLinkedOwner.allElements]
    doubleLinkedOwner = ownerCrossPointsModel;
    this.outputValue = ownerCrossPointsModel.dataModel.chartOptions.dataContainerOptions.yTransform(outputValue).toDouble();
    // By the time a PointModel is constructed, DataModel and it's ownerCrossPointsList INDEXES are configured

    assertDoubleResultsSame(
      ownerCrossPointsModel.dataModel.chartOptions.dataContainerOptions
          .yTransform(ownerCrossPointsModel.dataModel.valuesRows[rowIndex][columnIndex])
          .toDouble(),
      this.outputValue,
    );

    /* KEEP - BUT NOT TRUE: After splitting each data column to positive and negative, the
                             ownerCrossPointsModel._crossPoints[rowIndex] can NOT be used: _crossPoints may be shorter or empty
    assertDoubleResultsSame(
      ownerCrossPointsModel.dataModel.chartOptions.dataContainerOptions
          .yTransform(ownerCrossPointsModel._crossPoints[rowIndex].outputValue)
          .toDouble(),
      outputValue,
    );
    */
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

  /// References the data column (crossPoints list) this point belongs to
  CrossPointsModel ownerCrossPointsModel;

  /// Refers to the row index in [ChartModel.valuesRows] from which this point was created.
  ///
  /// Also, this point object is kept in [CrossPointsModel._crossPoints] at index [rowIndex].
  ///
  /// See [outputValue] for details of the column index from which this point was created.
  final int rowIndex;

  /// Stacked (transformed, not-extrapolated) data value.
  /// 
  /// Calculated assuming this [PointModel] is a unique member of [DoubleLinkedOwner] such as [CrossPointsModel].
  late final double _stackedOutputValue;

  /// Getter of the column index in the owner [ownerCrossPointsModel].
  ///
  /// Delegated to [ownerCrossPointsModel] index [CrossPointsModel.columnIndex].
  int get columnIndex => ownerCrossPointsModel.columnIndex;

  int get numDataModelColumns => ownerCrossPointsModel._numDataModelColumns;

  /// Calculates inputValue-position (x value) of this [PointModel] instance.
  ///
  /// Motivation:
  ///
  ///   Input values (x values) of data model [PointModel] are ofter non-numeric,
  ///   and are defined by [ChartModel.xUserLabels] or similar approach.
  ///   However, for the purpose of displaying a container representing a [PointModel],
  ///   we want to assign the [PointModel] an inputValue, which can be lextr-ed to
  ///   it's pixel position.  However, assigning an inputValue by itself does not help;
  ///   To lextr inputValue to some pixel value, we need to affix the inputValue
  ///   to a range. This method, [inputValueOnInputRange] does just that:
  ///   Given the passed [dataRangeLabelInfosGenerator], using its data range
  ///   [util_labels.DataRangeLabelInfosGenerator.dataRange], we can assign an inputValue
  ///   of this [PointModel] by dividing the data range into equal portions,
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

  /// Once the x labels are established, either as [xUserLabels] or generated, clients can
  ///  ask for the label.
  Object get xUserLabel => ownerCrossPointsModel.dataModel.xUserLabels[columnIndex];

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

// -------------------- Helper classes

class _DoubleValue {
  double value = 0.0;
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
