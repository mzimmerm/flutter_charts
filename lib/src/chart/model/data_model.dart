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
    required this.dataRows,
    required this.inputUserLabels,
    required this.chartOptions,
    this.outputUserLabels,
    required List<String> legendNames,
    List<ui.Color>? legendColors,
  })
  {
    logger.Logger().d('Constructing ChartModel');

    // Generate legend colors if not provided.
    legendColors ??= _byRowDefaultLegendColors(dataRows.length);

    // validate after late finals initialized as they are used in validate.
    validate(legendNames, legendColors);

    _byDataRowLegends = _ByDataRowLegends(legendNames, legendColors);

    _dataColumns = transposeRowsToColumns(dataRows);

    // Construct the full [ChartModel] as well, so we can use it, and
    // use it's methods and members in OLD DataContainer.
    // Here, create one [DataColumnModel] for each data column, and add to member [dataColumnModels]
    int columnIndex = 0;
    for (List<double> valuesColumn in _dataColumns) {
      dataColumnModels.add(
        DataColumnModel(
          valuesColumn: valuesColumn,
          outerChartModel: this,
          columnIndex: columnIndex,
        ),
      );

    columnIndex++;
    }

  }

  // NEW CODE =============================================================

  /// List of dataColumnPoints in this [ChartModel].
  ///
  /// Indexed and can be iterated using
  ///   ```dart
  ///   for (int col=0; col < this.numColumns; col++)
  ///   ```
  final List<DataColumnModel> dataColumnModels = [];

  /// The legends for each row of data.
  ///
  /// There is one Legend per data row. Alternative name would be "series names and colors".
  late final _ByDataRowLegends _byDataRowLegends;

  LegendItem getLegendItemAt(int index) => _byDataRowLegends.getItemAt(index);

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
  /// Implementation detail: maximum and minimum is calculated column-wise [DataColumnModel] first, but could go
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
        // not-Stacked values can just use values from [ChartModel.dataRows] transformed values.
        return Interval(
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
  Interval extendedValuesInterval({
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
  final Interval dataRangeWhenStringLabels = const Interval(0.0, 100.0);

  // OLD CODE =============================================================
  // Legacy stuff below

  /// Data in rows.
  ///
  /// Legacy use should be removed when legacy layout is removed.
  ///
  /// Each row of data represents one data series.
  /// Legends per row are managed by [byRowLegends].
  ///
  final List<List<double>> dataRows;

  int get numRows => dataRows.length;

  /// Data reorganized from rows to columns.
  late final List<List<double>> _dataColumns;

  int get numColumns => _dataColumns.length;

  /// Labels on input axis (also named independent axis, x axis).
  ///
  /// It is assumed labels are defined, by the client
  /// and their number is the same as number of points
  /// in each row in [dataRows].
  final List<String> inputUserLabels;

  /// User defined labels to be used by the chart, instead of labels auto-generated from data.
  ///
  /// Can be freehand Strings or numbers converted to Strings.
  /// If not null, a "manual" layout is used in the axis container where it is displayed -
  ///   in the [VerticalAxisContainer] or [HorizontalAxisContainer].
  /// If null, a "auto" layout is used in the axis container where it is displayed.
  ///
  final List<String>? outputUserLabels;

  /// Chart options of this [ChartModel].
  ///
  /// Motivation: [ChartModel] needs this member as options
  /// affect data transforms and validations.
  final ChartOptions chartOptions;

  // todo-013-performance : cache valuesMax/Min ond also _flatten
  List<double> get _flatten => dataRows.expand((element) => element).toList();
  double get _valuesMin => _flatten.reduce(math.min);
  // double get _valuesMax => _flatten.reduce(math.max);

  double get _transformedValuesMin =>
      _flatten.map((value) => chartOptions.dataContainerOptions.yTransform(value).toDouble()).reduce(math.min);
  double get _transformedValuesMax =>
      _flatten.map((value) => chartOptions.dataContainerOptions.yTransform(value).toDouble()).reduce(math.max);

  void validate(List<String> legendNames, List<ui.Color> legendColors) {
    //                      But that would require ChartOptions available in ChartModel.
    if (!(dataRows.length == legendNames.length)) {
      throw StateError('The number of legend labels provided in parameter "legendNames", '
          'does not equal the number of data rows provided in parameter "dataRows":\n'
          'Detail reason: Row legend labels must be provided in parameter "legendNames", '
          'and their number must be the same as number of data rows. '
          'However, in your data definition, that is not the case:\n'
          '   [number of dataRows: ${dataRows.length}] != [number of legendNames: ${legendNames.length}].\n'
          'To fix this: provide ${dataRows.length} "legendNames".');
    }
    if (!(dataRows.length == legendColors.length)) {
      throw StateError('The number of legend colors provided in parameter "legendColors", '
          'does not equal the number of data rows provided in parameter "dataRows":\n'
          'Detail reason: If not provided in "legendColors", legend colors are generated. '
          'If the parameter "legendColors" is provided, '
          'the number of colors must be the same as number of data rows. '
          'However, in your data definition, that is not the case:\n'
          '   [number of dataRows: ${dataRows.length}] != [number of legendColors: ${legendColors.length}].\n'
          'To fix this: provide ${dataRows.length} "legendColors".');
    }
    // Check explicit log10 used in options. This test does not cover user's explicitly declared transforms.
    if (log10 == chartOptions.dataContainerOptions.yTransform) {
      if (!(_valuesMin > 0.0)) {
        throw StateError('Using logarithmic Y scale requires only positive Y data');
      }
    }
  }

  /// For positive [sign], returns max of all columns (more precisely, of all [DataColumnModel]s),
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
    return dataColumnModels
        .map((dataColumnModel) => dataColumnModel.extremeValueWithSign(sign, chartStacking))
        .extremeValueWithSign(sign);
  }

}

/// Data for one legend item, currently it's [name] and [color] used for data it represents.
///
/// Motivation: In this project model [ChartModel], we represent chart data as columns,
///             in [DataColumnModel]. This representation is motivated by a 'stacked column' view of data.
///             At the same time, list of data that represents one 'series' can be viewed as a row of data.
///             So
///               - In the 'row first view',    each row contains data in one series,     for ALL independent (input) labels.
///               - In the 'column first view', each column contains data 'across series' for ONE independent (input) label.
///             Each [LegendItem] describes one series of data (one row of data); it's [color] is used
///             to color data for the the same series.
///
class LegendItem {
  const LegendItem(this.name, this.color);
  final String   name;
  final ui.Color color;
}

/// Descriptors of legends; each descriptor
///
///
class _ByDataRowLegends {
  _ByDataRowLegends(List<String>nameColumn, List<ui.Color> legendColors) {
    if (nameColumn.length != legendColors.length) {
      throw StateError('There must be the same number of legend names and colors, but client provided '
          '${nameColumn.length} names and ${legendColors.length} colors.');
    }

    for (int row = 0; row < nameColumn.length; row++) {
      _legendItems.add(LegendItem(nameColumn[row], legendColors[row]));
    }
  }
  final List<LegendItem> _legendItems = [];
  void addItem(LegendItem item) => _legendItems.add(item);
  LegendItem getItemAt(int rowIndex) => _legendItems[rowIndex];
  List<LegendItem> get legendItems => _legendItems;
}

// =====================
/// Represents a list of cross-series data values in the [ChartModel], in another words, a column of data values.
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
/// Note: [DataColumnModel] replaces the [PointsColumn] in legacy layouter.
///
@immutable
class DataColumnModel {

  /// Constructs a model for one bar of points.
  ///
  /// The [valuesColumn] is a cross-series (column-wise) list of data values.
  /// The [outerChartModel] is the [ChartModel] underlying the [DataColumnModel] instance being created.
  /// The [columnIndex] is index of the [valuesColumn] in the [outerChartModel].
  /// The [numChartModelColumns] allows to later calculate this point's input value using [inputValueOnInputRange],
  ///   which assumes this point is on an axis with data range given by a [util_labels.DataRangeLabelInfosGenerator]
  ///   instance.
  DataColumnModel({
    required List<double> valuesColumn,
    required this.outerChartModel,
    required this.columnIndex,

  }) {
    // Construct data points from the passed [valuesRow] and add each point to member _points
    int rowIndex = 0;
    // Convert the positive/negative values of the passed [valuesColumn], into positive or negative [_dataColumnPoints]
    //   - positive and negative values of the [valuesColumn] are separated to their own [_dataColumnPoints].
    for (double outputValue in valuesColumn) {
      var point = PointModel(
        outputValue: outputValue,
        outerDataColumnModel: this,
        rowIndex: rowIndex,
      );
      pointModelList.add(point);
      rowIndex++;
    }
  }

  /// The full [ChartModel] from which data columns this [DataColumnModel] is created.
  final ChartModel outerChartModel;

  /// Index of this column (dataColumnPoints list) in the [ChartModel.dataColumnModels].
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
  /// instances of this [DataColumnModel] and it's [PointModel] elements.
  ///
  /// The value is in the middle of the column - there are [ChartModel.numColumns] [_numChartModelColumns] columns that
  /// divide the [dataRange].
  ///
  /// Note: So this is offset from start and end of the Interval.
  ///
  /// Late, once [util_labels.DataRangeLabelInfosGenerator] is established in view model,
  /// we can use the [_numChartModelColumns] and the [util_labels.DataRangeLabelInfosGenerator.dataRange]
  /// to calculate this value
  double inputValueOnInputRange({
    required util_labels.DataRangeLabelInfosGenerator dataRangeLabelInfosGenerator,
  }) {
    Interval dataRange = dataRangeLabelInfosGenerator.dataRange;
    double columnWidth = (dataRange.length / outerChartModel.numColumns);
    return (columnWidth * columnIndex) + (columnWidth / 2);
  }

  /// Points in this column are points in one cross-series column.
  /// // todo-00-next : should be private, just get by index. Same for ChartViewModel
  final List<PointModel> pointModelList = [];
  
  /// Returns the [DataColumnModel] for the next column from this [DataColumnModel] instance.
  /// 
  /// Should be surrounded with [hasNextColumnModel].
  ///
  /// Throws [StateError] if not such column exists. 
  ///
  /// 'Next column' refers to the column with [columnIndex] one more than this [DataColumnModel]s [columnIndex].
  DataColumnModel get nextColumnModel =>
      hasNextColumnModel
          ?
      outerChartModel.dataColumnModels[columnIndex + 1]
          :
      throw StateError('No next column for column $this. Use hasNextColumnModel');

  /// Returns true if there is a next column after this [DataColumnModel] instance.
  /// 
  /// Should be used before invoking [nextColumnModel].
  bool get hasNextColumnModel => columnIndex < outerChartModel.numColumns - 1 ? true : false;
  
  /// Returns minimum or maximum of [PointModel.outputValue]s in me.
  ///
  /// In more detail:
  ///   - For [chartStacking] == [ChartStacking.stacked],  returns added (accumulated) [PointModel.outputValue]s
  ///     for all [PointModel]s in this [DataColumnModel] instance, that have the passed [sign].
  ///   - For [chartStacking] == [ChartStacking.nonStacked]
  ///     - For [sign] positive, returns max of positive [PointModel.outputValue]s
  ///       for all positive [PointModel]s in this [DataColumnModel] instance.
  ///     - For [sign] negative, returns min of negative [PointModel.outputValue]s
  ///       for all negative [PointModel]s in this [DataColumnModel] instance.
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

/// Represents one data point in the chart data model [ChartModel] and related model classes.
///
/// Notes:
///   - [PointModel] replaces the [StackableValuePoint] in legacy layouter.
///   - Has private access to the outer [ChartModel] to which it belongs through it's member [outerDataColumnModel],
///     which in turn has access to [ChartModel] through it's private [DataColumnModel]
///     member `DataColumnModel._chartModel`.
///     This access is used for model colors and row and column indexes to [ChartModel.dataRows].
///
@immutable
class PointModel {

  // ===================== CONSTRUCTOR ============================================
  /// Constructs instance and from [DataColumnModel] instance [outerDataColumnModel],
  /// and [rowIndex], the index in where the point value [outputValue] is located.
  ///
  /// Important note: The [outerDataColumnModel] value on [rowIndex], IS NOT [outputValue],
  ///                 as the [outerDataColumnModel] is split from [ChartModel.dataColumns] so
  ///                 [rowIndex] can only be used to reach `outerDataColumnModel.chartModel.valuesRows`.
  PointModel({
    required double outputValue,
    required this.outerDataColumnModel,
    required this.rowIndex,
  })
    : outputValue = outerDataColumnModel.outerChartModel.chartOptions.dataContainerOptions.yTransform(outputValue).toDouble(),
    sign = outputValue >= 0.0 ? Sign.positiveOr0 : Sign.negative
  {
    assertDoubleResultsSame(
      outerDataColumnModel.outerChartModel.chartOptions.dataContainerOptions
          .yTransform(outerDataColumnModel.outerChartModel.dataRows[rowIndex][columnIndex])
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
  ///   - column at index [columnIndex], which is also the [outerDataColumnModel]'s
  ///     index [DataColumnModel.columnIndex].
  ///  Those indexes are also a way to access the original for comparisons and asserts in the algorithms.
  final double outputValue;


  /// [Sign] of the [outputValue].
  final Sign sign;

  /// References the data column (dataColumnPoints list) this point belongs to
  final DataColumnModel outerDataColumnModel;

  /// Refers to the row index in [ChartModel.valuesRows] from which this point was created.
  ///
  /// Also, this point object is kept in [DataColumnModel.pointModelList] at index [rowIndex].
  ///
  /// See [outputValue] for details of the column index from which this point was created.
  final int rowIndex;

  /// Getter of the column index in the [outerDataColumnModel].
  ///
  /// Delegated to [outerDataColumnModel] index [DataColumnModel.columnIndex].
  int get columnIndex => outerDataColumnModel.columnIndex;

  /// Returns the [PointModel] in the same row, next column from this [PointModel] instance.
  /// 
  /// Should be surrounded with [hasNextPointModel].
  ///
  /// Throws [StateError] if not such column exists. 
  ///
  /// 'Next column' refers to the column with [columnIndex] one more than this [PointModel]s [columnIndex].
  PointModel get nextPointModel =>
      hasNextPointModel
          ?
      outerDataColumnModel.nextColumnModel.pointModelList[rowIndex]
          :
      throw StateError('No next column for column $this. Use hasNextPointModel before invoking nextPointModel.');

  /// Returns true if there is a next column after this [PointModel] instance.
  /// 
  /// Should be used before invoking [nextPointModel].
  bool get hasNextPointModel => outerDataColumnModel.hasNextColumnModel;
  
  /// Gets or calculates the inputValue-position (x value) of this [PointModel] instance.
  ///
  /// Delegated to the same name method on [outerDataColumnModel] - the [DataColumnModel.inputValueOnInputRange] -
  /// given the passed [inputDataRangeLabelInfosGenerator].
  ///
  /// The delegated method divides the input data range into the number of columns,
  /// and places this instance input value in the middle of the column at which this [PointModel] lives.
  ///
  /// See documentation of the delegated  [DataColumnModel.inputValueOnInputRange].
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
  ///   Given the passed [inputDataRangeLabelInfosGenerator], using its data range
  ///   [util_labels.DataRangeLabelInfosGenerator.dataRange], we can assign an inputValue
  ///   to this [PointModel] by dividing the data range into equal portions,
  ///   and taking the center of the corresponding portion as the returned inputValue.
  ///
  double inputValueOnInputRange({
    required util_labels.DataRangeLabelInfosGenerator inputDataRangeLabelInfosGenerator,
  }) {
    return outerDataColumnModel.inputValueOnInputRange(
      dataRangeLabelInfosGenerator: inputDataRangeLabelInfosGenerator,
    );
  }

  /// Once the x labels are established, either as [inputUserLabels] or generated, clients can
  ///  ask for the label.
  Object get inputUserLabel => outerDataColumnModel.outerChartModel.inputUserLabels[columnIndex];

  ui.Color get color => outerDataColumnModel.outerChartModel.getLegendItemAt(rowIndex).color;

  /// Converts this [PointModel] to [PointOffset] with the same output value (the [PointModel.outputValue]
  /// is copied to [PointOffset.outputValue]), and the [PointOffset]'s [PointOffset.inputValue]
  /// created by evenly dividing the passed input range of the passed [inputDataRangeLabelInfosGenerator].
  PointOffset toPointOffsetOnInputRange({
    required util_labels.DataRangeLabelInfosGenerator inputDataRangeLabelInfosGenerator,
  }) =>
      PointOffset(
        inputValue: inputValueOnInputRange(
          inputDataRangeLabelInfosGenerator: inputDataRangeLabelInfosGenerator,
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
List<ui.Color> _byRowDefaultLegendColors(int dataRowsCount) {
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
