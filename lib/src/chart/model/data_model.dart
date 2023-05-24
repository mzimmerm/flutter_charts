import 'dart:math' as math show Random, pow, min;
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
///     such as [ChartRootContainerCL.rangeDescriptor].
///
/// Legacy Note: Replacement for legacy [ChartData], [PointsColumns],
///              and various holders of dependent data values, including parts of [DataRangeTicksAndLabelsDescriptor]
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

  }

  // NEW CODE =============================================================

  /// The legends for each row of data.
  ///
  /// There is one Legend per data row. Alternative name would be "series names and colors".
  late final _ByDataRowLegends _byDataRowLegends;

  LegendItem getLegendItemAt(int index) => _byDataRowLegends.getItemAt(index);

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

  /// For the benefit of [ChartViewModel] to construct [PointsBarModel]s.
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

  // todo-013-performance : cache flattenRows, also _valuesMin, also look at its usages
  List<double> get flattenRows => dataRows.expand((element) => element).toList();
  double get _valuesMin => flattenRows.reduce(math.min);

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
}

/// Data for one legend item, currently it's [name] and [color] used for data it represents.
///
/// Motivation: In this project model [ChartModel], we represent chart data as columns,
///             in [PointsBarModel]. This representation is motivated by a 'stacked column' view of data.
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
