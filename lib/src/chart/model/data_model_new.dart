import 'dart:math' as math show Random, pow, min, max;
import 'dart:ui' as ui show Color;
import 'package:logger/logger.dart' as logger;
import 'package:flutter/material.dart' as material show Colors;

// this level or equivalent
import '../../coded_layout/chart/container.dart';
import '../container_layouter_base.dart';

import '../../util/util_labels.dart' as util_labels;
import '../../util/util_dart.dart';

import '../options.dart';

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
///   - When [NewModel] is constructed, the [ChartRootContainerCL] is not available.
///     So in constructor, [NewModel] cannot be given access to the root container, and it's needed members
///     such as [ChartRootContainerCL.labelsGenerator].
class NewModel {

  // ================ CONSTRUCTOR NEEDS SOME OLD MEMBERS FOR NOW ====================

  NewModel({
    required dataRows,
    required this.xUserLabels,
    required dataRowsLegends,
    required this.chartOptions,
    this.yUserLabels,
    List<ui.Color>? dataRowsColors,
  })
      :
  // Initializing of non-nullable _dataRowsColors which is a non-required argument
  // must be in the initializer list by a non-member function (member methods only in constructor)
        _dataRows = dataRows,
        _dataRowsLegends = dataRowsLegends,
        _dataRowsColors = dataRowsColors ?? dataRowsDefaultColors(dataRows.length)
  {
    logger.Logger().d('Constructing NewModel');
    validate();

    _dataBars = transposeRowsToColumns(_dataRows);

    // Construct the full [NewModel] as well, so we can use it, and also gradually
    // use it's methods and members in OLD DataContainer.
    // Here, create one [NewModelSeries] for each data row, and add to member [crossSeriesPointsList]
    int columnIndex = 0;
    for (List<double> dataBar in _dataBars) {
      crossSeriesPointsList.add(
        NewCrossSeriesPointsModel(
          dataBar: dataBar,
          dataModel: this,
          columnIndex: columnIndex++,
        ),
      );
    }

  }

  // NEW CODE =============================================================

  /// List of crossSeriesPoints in the model .
  final List<NewCrossSeriesPointsModel> crossSeriesPointsList = [];

  /// Returns the minimum and maximum non-extrapolated, transformed data values calculated from [NewModel],
  /// specific for the passed [isStacked].
  ///
  /// The returned value is calculated from [NewModel] by finding maximum and minimum of data values
  /// in [NewPointModel] instances, which are added up if the passed [isStacked] is `true`.
  ///
  /// The source data of the returned interval differs in stacked and non-stacked data, determined by argument [isStacked] :
  ///   - For [isStacked] true, the min and max is taken from [NewPointModel._stackedPositiveDataValue] and
  ///     [NewPointModel._stackedNegativeDataValue] is used.
  ///   - For  [isStacked] false, the min and max is taken from [NewPointModel._dataValue] is used.
  ///
  /// Implementation detail: maximum and minimum is calculated column-wise [NewCrossSeriesPointsModel] first, but could go
  /// directly to the flattened list of [NewPointModel] (max and min over partitions is same as over whole set).
  ///
  Interval dataValuesInterval({
    required bool isStacked,
  }) {
    if (isStacked) {
      return Interval(
        // reduce, not fold: crossSeriesPointsList.fold(0.0, ((double previous, NewCrossSeriesPointsModel pointsColumn) => math.min(previous, pointsColumn._stackedNegativeValue))),
        crossSeriesPointsList.map((pointsColumn) => pointsColumn._stackedNegativeValue).toList().reduce(math.min),
        crossSeriesPointsList.map((pointsColumn) => pointsColumn._stackedPositiveValue).toList().reduce(math.max),
      );
    } else {
      return Interval(
        crossSeriesPointsList.map((pointsColumn) => pointsColumn._minPointValue).toList().reduce(math.min),
        crossSeriesPointsList.map((pointsColumn) => pointsColumn._maxPointValue).toList().reduce(math.max),
      );
    }
  }

  /// Returns the interval that envelopes all data values in [NewModel.dataRows], possibly extended to 0.
  ///
  /// The [isStacked] controls whether the interval is created from values in [NewPointModel._dataValue]
  /// or the stacked values [NewPointModel._stackedPositiveDataValue] and
  /// [NewPointModel._stackedNegativeDataValue]
  ///
  /// Whether the resulting Interval is extended from the simple min/max of all data values
  /// is controlled by [extendAxisToOrigin]. If [true] the interval is extended to zero
  /// if all values are positive or all are negative.
  ///
  Interval extendedDataValuesInterval({
    required bool isStacked,
    required bool extendAxisToOrigin,
  }) {
    return util_labels.extendToOrigin(
      dataValuesInterval(isStacked: isStacked),
      extendAxisToOrigin,
    );
  }

  // OLD CODE =============================================================
  // Legacy stuff below

  // _dataRows[columnIndex][rowIndex]
  /// Data in rows.
  ///
  /// Each row of data represents one data series.
  /// Legends per row are managed by [_dataRowsLegends].
  ///
  final List<List<double>> _dataRows;
  List<List<double>> get dataRows => _dataRows;

  /// Data reorganized from rows to columns.
  late final List<List<double>> _dataBars;
  List<List<double>> get dataBars => _dataBars;

  /// Labels on independent (X) axis.
  ///
  /// It is assumed labels are defined, by the client
  /// and their number is the same as number of points
  /// in each row in [_dataRows].
  final List<String> xUserLabels;

  /// The legends for each row in [_dataRows].
  ///
  /// One Legend String per row.
  /// Alternative name would be "series names".
  final List<String> _dataRowsLegends;
  List<String> get dataRowsLegends => _dataRowsLegends;

  /// User defined labels to be used by the chart, instead of labels auto-generated from data.
  ///
  /// Can be Strings or numbers.
  /// If not null, a "manual" layout is used in the [YContainerCL].
  /// If null, a "auto" layout is used in the [YContainerCL].
  ///
  final List<String>? yUserLabels;

  /// Colors corresponding to each data row (series) in [NewModel].
  final List<ui.Color> _dataRowsColors;
  List<ui.Color> get dataRowsColors => _dataRowsColors;

  /// Chart options which may affect data validation.
  final ChartOptions chartOptions;

  /// Keeps data values grouped in columns.
  ///
  /// This column grouped data instance is managed here in the [ChartRootContainerCL],
  /// (immediate owner of [YContainerCL] and [DataContainerCL])
  /// as their data points are needed both during [YContainerCL.layout]
  /// to calculate extrapolating, and also in [DataContainerCL.layout] to create
  /// [PointPresentersColumns] instance.
  late PointsColumns pointsColumns;

  List<double> get flatten => _dataRows.expand((element) => element).toList();
  double get dataYMax => flatten.reduce(math.max);
  double get dataYMin => flatten.reduce(math.min);

  void validate() {
    //                      But that would require ChartOptions available in NewModel.
    if (!(dataRows.length == dataRowsLegends.length)) {
      throw StateError('The number of legend labels provided in parameter "dataRowsLegends", '
          'does not equal the number of data rows provided in parameter "dataRows":\n'
          'Detail reason: Row legend labels must be provided in parameter "dataRowsLegends", '
          'and their number must be the same as number of data rows. '
          'However, in your data definition, that is not the case:\n'
          '   [number of dataRows: ${dataRows.length}] != [number of dataRowsLegends: ${dataRowsLegends.length}].\n'
          'To fix this: provide ${dataRows.length} "dataRowsLegends".');
    }
    if (!(dataRows.length == dataRowsColors.length)) {
      throw StateError('The number of legend colors provided in parameter "dataRowsColors", '
          'does not equal the number of data rows provided in parameter "dataRows":\n'
          'Detail reason: If not provided in "dataRowsColors", legend colors are generated. '
          'If the parameter "dataRowsColors" is provided, '
          'the number of colors must be the same as number of data rows. '
          'However, in your data definition, that is not the case:\n'
          '   [number of dataRows: ${dataRows.length}] != [number of dataRowsColors: ${dataRowsColors.length}].\n'
          'To fix this: provide ${dataRows.length} "dataRowsColors".');
    }
    // Check explicit log10 used in options. This test does not cover user's explicitly declared transforms.
    if (log10 == chartOptions.dataContainerOptions.yTransform) {
      if (!(dataYMin > 0.0)) {
        throw StateError('Using logarithmic Y scale requires only positive Y data');
      }
    }
  }

}

/// todo-done-last-3 : Note: NewCrossSeriesPointsModel replaces PointsColumn
///
/// Represents a list of cross-series data values, in the [NewModel].
///
/// As we consider the [NewModel] to represent a 2D array 'rows first', in other words,
/// 'one data series is a row', with rows (each-series) ordered 'top-to-bottom',
/// columns (cross-series) oriented 'left-to-right', then:
///   - The list of data values in this object represent one column in the 2D array (cross-series values),
///     oriented 'top-to-bottom'.
///   - We can also consider the list of data values represented by
///     this object to be created by diagonal transpose of the [NewModel._dataRows] and
///     looking at one row in the transpose, left-to-right.
class NewCrossSeriesPointsModel extends Object with DoubleLinkedOwner<NewPointModel> {

  /// Constructor. todo-doc-01
  NewCrossSeriesPointsModel({
    required List<double> dataBar,
    required NewModel dataModel,
    required int columnIndex,
  })
      : _dataModel = dataModel,
        _columnIndex = columnIndex {
    // Construct data points from the passed [dataRow] and add each point to member _points
    int rowIndex = 0;
    for (double dataValue in dataBar) {
      var point = NewPointModel(dataValue: dataValue, ownerCrossSeriesPointsList: this, rowIndex: rowIndex);
      _points.add(point);
      rowIndex++;
    }
    // When all points in this crossSeriesPoints are constructed and added to [_points], we can double-link the points.
    // We just need one point to start - provided by [DoubleLinkedOwner.firstLinked].
    if (_points.isNotEmpty) {
      firstLinked().linkAll();
    }
    // Once the owned DoubleLinked data points are linked, we can do iteration operations of them, such as stacking.

    // Calculate and initialize stacked point values of this column of points.
    applyOnAllElements(
      _stackPoints,
      this,
    );
  }

  /// Calculates and initializes the final stacked positive and negative values on points.
  _stackPoints(NewPointModel point, unused) {
      if (point.hasPrevious) {
        if (point._dataValue < 0.0) {
          point._stackedNegativeDataValue = point.previous._stackedNegativeDataValue + point._dataValue;
          point._stackedPositiveDataValue = point.previous._stackedPositiveDataValue;
        } else {
          point._stackedPositiveDataValue = point.previous._stackedPositiveDataValue + point._dataValue;
          point._stackedNegativeDataValue = point.previous._stackedNegativeDataValue;
        }
      } else {
        // first element
        if (point._dataValue < 0.0) {
          point._stackedNegativeDataValue = point._dataValue;
          point._stackedPositiveDataValue = 0.0;
        } else {
          point._stackedNegativeDataValue = 0.0;
          point._stackedPositiveDataValue = point._dataValue;
        }
      }
    }

  /// Get the stacked value of this column of points - the sum of all

  /// Owner [NewModel] to which this [NewCrossSeriesPointsModel] belongs by existence in
  /// [NewModel.crossSeriesPointsList].
  ///
  final NewModel _dataModel;
  NewModel get dataModel => _dataModel;

  /// Index of this column (crossSeriesPoints list) in the [NewModel.crossSeriesPointsList].
  ///
  /// Also indexes one column, top-to-bottom, in the two dimensional [NewModel.dataRows].
  /// Also indexes one row, left-to-right, in the `transpose(NewModel.dataRows)`.
  ///
  /// The data values of this column are stored in the [_points] list,
  /// values and order as in top-to-bottom column in [NewModel.dataRows].
  ///
  /// This is needed to access the legacy arrays such as:
  ///   -  [NewModel.dataRowsLegends]
  ///   -  [NewModel.dataRowsColors]
  final int _columnIndex;

  /// Points of this column (crossSeriesPoints).
  ///
  /// The points are needed to provide the [allElements], the list of all [DoubleLinked] elements
  /// owned by this [DoubleLinkedOwner]. 
  /// At the same time, the points are all [NewPointModel] in this column (crossSeriesPoints list).
  final List<NewPointModel> _points = [];

  /// Implements the [DoubleLinkedOwner] abstract method which provides all elements for
  /// the owned [DoubleLinked] instances of [NewPointModel].
  @override
  Iterable<NewPointModel> allElements() => _points;

  /// Returns height of this column in terms of data values on points, separately for positive and negative.
  ///
  /// Getters always recalculates, should be cached in new member on column
  double get _stackedPositiveValue => __maxOnPoints((NewPointModel point) => point._stackedPositiveDataValue);
  double get _stackedNegativeValue => __minOnPoints((NewPointModel point) => point._stackedNegativeDataValue);

  double get _minPointValue         => __minOnPoints((NewPointModel point) => point._dataValue);
  double get _maxPointValue         => __maxOnPoints((NewPointModel point) => point._dataValue);

  //double __stackedPositive(NewPointModel point) => point._stackedPositiveDataValue;
  //double __stackedNegative(NewPointModel point) => point._stackedNegativeDataValue;

  double __maxOnPoints(double Function(NewPointModel) getNumFromPoint) {
    return __applyFoldableOnPoints(getNumFromPoint, math.max);
  }

  double __minOnPoints(double Function(NewPointModel) getNumFromPoint) {
    return __applyFoldableOnPoints(getNumFromPoint, math.min);
  }

  /// Apply the fold performed by [foldable] (double, double) => double function,
  /// on some double values from the owned [allElements] which are [DoubleLinked] and [NewPointModel]s.
  ///
  /// The double values are pulled from each [NewPointModel]
  /// using the [getNumFromPoint] (NewPointModel) => double function.
  ///
  double __applyFoldableOnPoints(
    double Function(NewPointModel) getNumFromPoint,
    double Function(double, double) foldable,
  ) {
    _DoubleValue result = _DoubleValue();
    applyOnAllElements(
      (NewPointModel point, result) {
        if (!point.hasPrevious) {
          result.value = getNumFromPoint(point);
        } else {
          result.value = foldable(result.value as double, getNumFromPoint(point));
        }
        // print('result = ${result.value}');
      },
      result,
    );
    return result.value;
  }

}

/// Represents one data point. Replaces the legacy [StackableValuePoint].
///
/// Notes:
///   - Has private access to the owner [NewModel] to which it belongs through it's member [ownerCrossSeriesPointsList]
///     which in turn has access to [NewModel] through it's member [NewCrossSeriesPointsModel._dataModel].
///     THIS ACCESS IS CURRENTLY UNUSED
///
class NewPointModel extends Object with DoubleLinked {

  // ===================== CONSTRUCTOR ============================================
  // todo-doc-01
  NewPointModel({
    required double dataValue,
    required this.ownerCrossSeriesPointsList,
    required int rowIndex,
  })  : _dataValue = ownerCrossSeriesPointsList._dataModel.chartOptions.dataContainerOptions.yTransform(dataValue).toDouble(),
        _rowIndex = rowIndex {
    // The ownerSeries is NewModelSeries which is DoubleLinkedOwner
    // of all [NewPointModel]s, managed by [DoubleLinkedOwner.allElements]
    doubleLinkedOwner = ownerCrossSeriesPointsList;
    // By the time a NewPointModel is constructed, DataModel and it's ownerCrossSeriesPointsList INDEXES are configured
    assertDoubleResultsSame(
      ownerCrossSeriesPointsList._dataModel.chartOptions.dataContainerOptions
          .yTransform(ownerCrossSeriesPointsList.dataModel._dataRows[_rowIndex][ownerCrossSeriesPointsList._columnIndex])
          .toDouble(),
      _dataValue,
    );
  }

  // ===================== NEW CODE ============================================

  /// The original (transformed, not-extrapolated) data value from one data item
  /// in the two dimensional, rows first, [NewModel.dataRows].
  ///
  /// This [_dataValue] point is created from the [NewModel.dataRows] using the indexes:
  ///   - row at index [_rowIndex]
  ///   - column at the [ownerCrossSeriesPointsList] index [NewCrossSeriesPointsModel._columnIndex].
  ///  Those indexes are also a way to access the original for comparisons and asserts in the algorithms.
  final double _dataValue;

  double get dataValue => _dataValue;

  late final double _stackedPositiveDataValue;
  late final double _stackedNegativeDataValue;

  /// Refers to the row index in [NewModel.dataRows] from which this point was created.
  ///
  /// Also, this point object is kept in [NewCrossSeriesPointsModel._points] index [_rowIndex].
  ///
  /// See [_dataValue] for details of the column index from which this point was created.
  final int _rowIndex;

  /// References the data column (crossSeriesPoints list) this point belongs to
  NewCrossSeriesPointsModel ownerCrossSeriesPointsList;

  ui.Color get color => ownerCrossSeriesPointsList._dataModel._dataRowsColors[_rowIndex];

}

// -------------------- Helper classes

class _DoubleValue {
  double value = 0.0;
}

enum DataRangeDependency {
  independentData,
  dependentData,
}

// -------------------- Functions

// To initialize default colors with dynamic list that allows the colors NOT null, initialization must be done in
//  initializer list (it is too late in constructor, by then, the colors list would have to be NULLABLE).
/// Sets up colors for legends, first several explicitly, rest randomly.
///
/// This is used if user does not set colors.
List<ui.Color> dataRowsDefaultColors(int dataRowsCount) {
  List<ui.Color> rowsColors = List.empty(growable: true);

  if (dataRowsCount >= 1) {
    rowsColors.add(material.Colors.yellow);
  }
  if (dataRowsCount >= 2) {
    rowsColors.add(material.Colors.green);
  }
  if (dataRowsCount >= 3) {
    rowsColors.add(material.Colors.blue);
  }
  if (dataRowsCount >= 4) {
    rowsColors.add(material.Colors.black);
  }
  if (dataRowsCount >= 5) {
    rowsColors.add(material.Colors.grey);
  }
  if (dataRowsCount >= 6) {
    rowsColors.add(material.Colors.orange);
  }
  if (dataRowsCount > 6) {
    for (int i = 3; i < dataRowsCount; i++) {
      int colorHex = math.Random().nextInt(0xFFFFFF);
      int opacityHex = 0xFF;
      rowsColors.add(ui.Color(colorHex + (opacityHex * math.pow(16, 6)).toInt()));
    }
  }
  return rowsColors;
}
