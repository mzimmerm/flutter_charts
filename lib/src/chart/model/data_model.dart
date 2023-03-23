import 'dart:math' as math show Random, pow, min, max;
import 'dart:ui' as ui show Color;
// import 'package:flutter/cupertino.dart';
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
    required valuesRows,
    required this.xUserLabels,
    required byRowLegends,
    required this.chartOptions,
    this.yUserLabels,
    List<ui.Color>? byRowColors,
  })  :
        // Initializing of non-nullable _byRowColors which is a non-required argument
        // must be in the initializer list by a non-member function (member methods only in constructor)
        _valuesRows = valuesRows,
        _byRowLegends = byRowLegends,
        _byRowColors = byRowColors ?? byRowDefaultColors(valuesRows.length) {
    logger.Logger().d('Constructing ChartModel');
    validate();

    _valuesColumns = transposeRowsToColumns(_valuesRows);

    // Construct the full [ChartModel] as well, so we can use it, and also gradually
    // use it's methods and members in OLD DataContainer.
    // Here, create one [ChartModelSeries] for each data row, and add to member [crossPointsList]
    int columnIndex = 0;
    for (List<double> valuesColumn in _valuesColumns) {
      crossPointsModelPositiveList.add(
        CrossPointsModel(
          valuesColumn: valuesColumn,
          dataModel: this,
          columnIndex: columnIndex,
          crossPointsModelPointsSigns: CrossPointsModelPointsSigns.positiveOr0,
        ),
      );
      crossPointsModelNegativeList.add(
        CrossPointsModel(
          valuesColumn: valuesColumn,
          dataModel: this,
          columnIndex: columnIndex,
          crossPointsModelPointsSigns: CrossPointsModelPointsSigns.negative,
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
  ///   - For [isStacked] true, the min and max is taken from [PointModel._stackedPositiveDataValue] and
  ///     [PointModel._stackedNegativeDataValue] is used.
  ///   - For  [isStacked] false, the min and max is taken from [PointModel._dataValue] is used.
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
        transformedValuesMin,
        transformedValuesMax,
      );
    }
  }

  /// Returns the interval that envelopes all data values in [ChartModel.valuesRows], possibly extended to 0.
  ///
  /// The [isStacked] controls whether the interval is created from values in [PointModel._dataValue]
  /// or the stacked values [PointModel._stackedPositiveDataValue] and
  /// [PointModel._stackedNegativeDataValue]
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

  // OLD CODE =============================================================
  // Legacy stuff below

  // _valuesRows[columnIndex][rowIndex]
  /// Data in rows.
  ///
  /// Each row of data represents one data series.
  /// Legends per row are managed by [_byRowLegends].
  ///
  final List<List<double>> _valuesRows;
  List<List<double>> get valuesRows => _valuesRows;

  /// Data reorganized from rows to columns.
  late final List<List<double>> _valuesColumns;
  List<List<double>> get valuesColumns => _valuesColumns;

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
  final List<String> _byRowLegends;
  List<String> get byRowLegends => _byRowLegends;

  /// User defined labels to be used by the chart, instead of labels auto-generated from data.
  ///
  /// Can be Strings or numbers.
  /// If not null, a "manual" layout is used in the [YContainerCL].
  /// If null, a "auto" layout is used in the [YContainerCL].
  ///
  final List<String>? yUserLabels;

  /// Colors corresponding to each data row (series) in [ChartModel].
  final List<ui.Color> _byRowColors;
  List<ui.Color> get byRowColors => _byRowColors;

  /// Chart options which may affect data validation.
  final ChartOptions chartOptions;

  // todo-00-last-00-performance : cache valuesMax/Min
  // todo-00-last-last : make all methods private if possible
  List<double> get flatten => _valuesRows.expand((element) => element).toList();
  double get valuesMin => flatten.reduce(math.min);
  double get valuesMax => flatten.reduce(math.max);

  double get transformedValuesMin =>
      flatten.map((value) => chartOptions.dataContainerOptions.yTransform(value).toDouble()).reduce(math.min);
  double get transformedValuesMax =>
      flatten.map((value) => chartOptions.dataContainerOptions.yTransform(value).toDouble()).reduce(math.max);


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
      if (!(valuesMin > 0.0)) {
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
enum CrossPointsModelPointsSigns {
  positiveOr0,
  negative,
  any,
}

/// Represents a list of cross-series data values in the [ChartModel], in another words, a column of data values,
/// which are all either positive (non-negative to be precise) or negative, depending on the
/// passed [crossPointsModelPointsSigns].
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

  /// Constructor. todo-doc-01
  CrossPointsModel({
    required List<double> valuesColumn,
    // todo-00-last-last : make dataModel final and get replace _dataModel with dataModel
    required ChartModel dataModel,
    // todo-00-last-last : make columnIndex final and get replace _columnIndex with columnIndex
    required int columnIndex,
    required this.crossPointsModelPointsSigns
  })
      : _dataModel = dataModel,
        _columnIndex = columnIndex {
    // Construct data points from the passed [valuesRow] and add each point to member _points
    int rowIndex = 0;
    // Convert the positive/negative values of the passed [valuesColumn], into positive or negative [_crossPoints]
    //   - positive and negative values of the [valuesColumn] are separated to their own [_crossPoints].
    for (double dataValue in valuesColumn) {
      if (__isValueMySign(
        // crossPointsModelPointsSigns: crossPointsModelPointsSigns,
        value: dataValue,
      )) {
        var point = PointModel(
          dataValue: dataValue,
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

  /// Checks if the sign of a double is the required sign.
  bool __isValueMySign({
    // required CrossPointsModelPointsSigns crossPointsModelPointsSigns,
    required double value,
  }) {
    switch (crossPointsModelPointsSigns) {
      case CrossPointsModelPointsSigns.any:
        return true;
      case CrossPointsModelPointsSigns.positiveOr0:
        return (value >= 0.0);
      case CrossPointsModelPointsSigns.negative:
        return (value < 0.0);
    }
  }

  /// Calculates and initializes the final stacked positive and negative values on points.
  ///
  /// Assumes that [DoubleLinked.linkAll] has been called on first element on the [_crossPoints],
  /// which is the backing list of this [DoubleLinkedOwner]'s  [allElements].
  ///
  /// Only makes practical sense if all [_crossPoints] are either positive or negative,
  /// see [CrossPointsModelPointsSigns].
  __stackPoints(PointModel point, unused) {
      assert(crossPointsModelPointsSigns != CrossPointsModelPointsSigns.any);

      if (point.hasPrevious) {
        point._stackedDataValue = point.previous._stackedDataValue + point._dataValue;
      } else {
        // first element
        point._stackedDataValue = point._dataValue;
      }
    }

  /* KEEP for a bit
  double get _stackedPositiveValue => __maxOnPoints((PointModel point) => point._stackedPositiveDataValue);
  double get _stackedNegativeValue => __minOnPoints((PointModel point) => point._stackedNegativeDataValue);
  double get _minPointValue         => __minOnPoints((PointModel point) => point._dataValue);
  double get _maxPointValue         => __maxOnPoints((PointModel point) => point._dataValue);

  late final double _stackedPositiveDataValue;
  late final double _stackedNegativeDataValue;

  __stackPoints(PointModel point, unused) {
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
  */
    
  /// Get the stacked value of this column of points - the sum of all

  /// Owner [ChartModel] to which this [CrossPointsModel] belongs by existence in
  ///  [ChartModel.crossPointsModelPositiveList] AND
  ///  the  [ChartModel.crossPointsModelNegativeList] .
  ///
  final ChartModel _dataModel;
  ChartModel get dataModel => _dataModel;

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
  final int _columnIndex;

  /// todo-00-doc
  late final CrossPointsModelPointsSigns crossPointsModelPointsSigns;

  /// Points of this positive or negative column (crossPoints).
  ///
  /// The points are needed to provide the [allElements], the list of all [DoubleLinked] elements
  /// owned by this [DoubleLinkedOwner]. 
  /// At the same time, the points are all [PointModel] in this positive or negative column (crossPoints list).
  final List<PointModel> _crossPoints = [];

  /// Implements the [DoubleLinkedOwner] abstract method which provides all elements for
  /// the owned [DoubleLinked] instances of [PointModel].
  @override
  Iterable<PointModel> allElements() => _crossPoints;


  /// Returns value-height of this column from (transformed, non-extrapolated) data values of points.
  double get _stackedValue {
    switch (crossPointsModelPointsSigns) {
      case CrossPointsModelPointsSigns.any:
        throw StateError('Cannot stack value on CrossPointsModel with mixed signs');
      case CrossPointsModelPointsSigns.positiveOr0:
        return __maxOnPoints((PointModel point) => point._stackedDataValue);
      case CrossPointsModelPointsSigns.negative:
        return __minOnPoints((PointModel point) => point._stackedDataValue);
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

}

/// Represents one data point. Replaces the legacy [StackableValuePoint].
///
/// Notes:
///   - Has private access to the owner [ChartModel] to which it belongs through it's member [ownerCrossPointsModel]
///     which in turn has access to [ChartModel] through it's member [CrossPointsModel._dataModel].
///     THIS ACCESS IS CURRENTLY UNUSED
///
class PointModel extends Object with DoubleLinked {

  // ===================== CONSTRUCTOR ============================================
  // todo-doc-01
  PointModel({
    required double dataValue,
    required this.ownerCrossPointsModel,
    required int rowIndex,
  })  : _dataValue = ownerCrossPointsModel._dataModel.chartOptions.dataContainerOptions.yTransform(dataValue).toDouble(),
        _rowIndex = rowIndex {
    // The ownerSeries is ChartModelSeries which is DoubleLinkedOwner
    // of all [PointModel]s, managed by [DoubleLinkedOwner.allElements]
    doubleLinkedOwner = ownerCrossPointsModel;
    // By the time a PointModel is constructed, DataModel and it's ownerCrossPointsList INDEXES are configured
    // todo-00-last-last : add more asserts on values without the yTransform if possible. Maybe use reverse? Mayve this is too much?
    assertDoubleResultsSame(
      ownerCrossPointsModel._dataModel.chartOptions.dataContainerOptions
          .yTransform(ownerCrossPointsModel.dataModel._valuesRows[_rowIndex][_columnIndex])
          .toDouble(),
      _dataValue,
    );
  }

  // ===================== NEW CODE ============================================

  /// The original (transformed, not-extrapolated) data value from one data item
  /// in the two dimensional, rows first, [ChartModel.valuesRows].
  ///
  /// This [_dataValue] point is created from the [ChartModel.valuesRows] using the indexes:
  ///   - row at index [_rowIndex]
  ///   - column at the [ownerCrossPointsModel] index [CrossPointsModel._columnIndex].
  ///  Those indexes are also a way to access the original for comparisons and asserts in the algorithms.
  final double _dataValue;

  double get dataValue => _dataValue;

  /// Stacked (transformed, not-extrapolated) data value.
  /// 
  /// Calculated assuming this [PointModel] is a member of [DoubleLinkedOwner] such as [CrossPointsModel],
  /// uniquely either .
  late final double _stackedDataValue;

  /// Refers to the row index in [ChartModel.valuesRows] from which this point was created.
  ///
  /// Also, this point object is kept in [CrossPointsModel._crossPoints] index [_rowIndex].
  ///
  /// See [_dataValue] for details of the column index from which this point was created.
  final int _rowIndex;

  /// Getter of the column index in the owner [ownerCrossPointsModel].
  ///
  /// Delegated to [ownerCrossPointsModel] index [CrossPointsModel._columnIndex].
  int get _columnIndex => ownerCrossPointsModel._columnIndex;

  /// References the data column (crossPoints list) this point belongs to
  CrossPointsModel ownerCrossPointsModel;

  ui.Color get color => ownerCrossPointsModel._dataModel._byRowColors[_rowIndex];

}

// -------------------- Helper classes

class _DoubleValue {
  double value = 0.0;
}

enum DataDependency {
  independentData,
  dependentData,
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
