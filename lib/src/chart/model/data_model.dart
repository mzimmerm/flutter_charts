import 'dart:math' as math show Random, pow;
import 'dart:ui' as ui show Color;
import 'package:flutter/cupertino.dart' show immutable;

import 'package:logger/logger.dart' as logger;
import 'package:flutter/material.dart' as material show Colors;

// this level or equivalent
import '../options.dart';

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

    /* todo-00-last-done : moved fully to ChartViewModel
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
    */

  }

  // NEW CODE =============================================================

  /// The legends for each row of data.
  ///
  /// There is one Legend per data row. Alternative name would be "series names and colors".
  late final _ByDataRowLegends _byDataRowLegends;

  LegendItem getLegendItemAt(int index) => _byDataRowLegends.getItemAt(index);

  /* todo-00-last-done : moved fully to ChartViewModel
  /// List of dataColumnPoints in this [ChartModel].
  ///
  /// Indexed and can be iterated using
  ///   ```dart
  ///   for (int col=0; col < this.numColumns; col++)
  ///   ```
  final List<DataColumnModel> dataColumnModels = [];


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


   */
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

  /// For the benefit of [ChartViewModel] to construct [DataColumnModel]s. todo-0100: This is now too messy. What are responsibilities of ChartModel vs ChartViewModel???
  List<List<double>> get dataColumns => _dataColumns;

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

  /* todo-00-done : moved to ChartViewModel
  // todo-013-performance : cache valuesMax/Min ond also _flatten
  List<double> get _flatten => dataRows.expand((element) => element).toList();
  double get _valuesMin => _flatten.reduce(math.min);
  // double get _valuesMax => _flatten.reduce(math.max);

  double get _transformedValuesMin =>
      _flatten.map((value) => chartOptions.dataContainerOptions.yTransform(value).toDouble()).reduce(math.min);
  double get _transformedValuesMax =>
      _flatten.map((value) => chartOptions.dataContainerOptions.yTransform(value).toDouble()).reduce(math.max);
  */

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
      /* todo-00-next : put this back
      if (!(_valuesMin > 0.0)) {
        throw StateError('Using logarithmic Y scale requires only positive Y data');
      }
      */
    }
  }

  /* todo-00-last-done : Moved to ChartViewModel
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
  */

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
