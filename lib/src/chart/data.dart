import 'dart:math' as math show Random, pow, min, max;
import 'dart:ui' as ui show Color;
import 'package:flutter/material.dart' as material show Colors;
import 'package:flutter_charts/flutter_charts.dart';

/// Manages Chart Data.
@Deprecated('Use NewDataModel instead.')
class ChartData {
  /// Data in rows.
  ///
  /// Each row of data represents one data series.
  /// Legends per row are managed by [dataRowsLegends].
  ///
  /// Each element of the outer list represents one row.
  /// Alternative name would be "data series".
  final List<List<double>> dataRows;

  /// Labels on independent (X) axis.
  ///
  /// It is assumed labels are defined, by the client
  /// and their number is the same as number of points
  /// in each row in [dataRows].
  final List<String> xUserLabels;

  /// The legends for the [dataRows] (data series).
  ///
  /// One Legend String per row.
  /// Alternative name would be "series names".
  final List<String> dataRowsLegends;

  /// User defined labels to be used by the chart, instead of labels auto-generated from data.
  ///
  /// Can be Strings or numbers.
  /// If not null, a "manual" layout is used in the [YContainer].
  /// If null, a "auto" layout is used in the [YContainer].
  ///
  final List<String>? yUserLabels;

  /// Colors corresponding to each data row (series) in [ChartData].
  final List<ui.Color> dataRowsColors;

  /// Chart options which may affect data validation.
  final ChartOptions chartOptions;

  /// Default constructor only assumes [dataRows] are set,
  /// and assigns default values of [dataRowsLegends], [dataRowsColors], [xUserLabels], [yUserLabels].
  ///
  ChartData({
    required this.dataRows,
    required this.xUserLabels,
    required this.dataRowsLegends,
    required this.chartOptions,
    this.yUserLabels,
    dataRowsColors,
  }) :
        // Initializing of non-nullable dataRowsColors which is a non-required argument
        // must be in the initializer list by a non-member function (member methods only in constructor)
        dataRowsColors = dataRowsColors ?? dataRowsDefaultColors(dataRows.length) {
    validate();
  }

  bool get isUsingUserLabels => yUserLabels != null;

  List<double> get flatten => dataRows.expand((element) => element).toList();
  double get dataYMax => flatten.reduce(math.max);
  double get dataYMin => flatten.reduce(math.min);

  void validate() {
    //                      But that would require ChartOptions available in ChartData.
    if (!(dataRows.length == dataRowsLegends.length && dataRows.length == dataRowsColors.length)) {
      throw StateError('If row legends are defined, their '
          'number must be the same as number of data rows. '
          ' [dataRows length: ${dataRows.length}] '
          '!= [dataRowsLegends length: ${dataRowsLegends.length}]. ');
    }
    for (List<double> dataRow in dataRows) {
      if (!(dataRow.length == xUserLabels.length)) {
        throw StateError('If xUserLabels are defined, their '
            'length must be the same as length of each dataRow'
            ' [dataRow length: ${dataRow.length}] '
            '!= [xUserLabels length: ${xUserLabels.length}]. ');
      }
    }
    // Check explicit log10 used in options. This test does not cover user's explicitly declared transforms.
    if (log10 == chartOptions.dataContainerOptions.yTransform) {
      if (!(dataYMin > 0.0)) {
        throw StateError('Using logarithmic Y scale requires only positive Y data');
      }
    }
  }
}

// To initialize default colors with dynamic list that allows the colors NOT null, initialization must be done in
//  initializer list (it is too late in constructor, by then, the colors list would have to be NULLABLE).
/// Sets up colors for legends, first several explicitly, rest randomly.
///
/// This is used if user does not set colors.
List<ui.Color> dataRowsDefaultColors(int dataRowsCount) {
  List<ui.Color> _rowsColors = List.empty(growable: true);

  if (dataRowsCount >= 1) {
    _rowsColors.add(material.Colors.yellow);
  }
  if (dataRowsCount >= 2) {
    _rowsColors.add(material.Colors.green);
  }
  if (dataRowsCount >= 3) {
    _rowsColors.add(material.Colors.blue);
  }
  if (dataRowsCount >= 4) {
    _rowsColors.add(material.Colors.black);
  }
  if (dataRowsCount >= 5) {
    _rowsColors.add(material.Colors.grey);
  }
  if (dataRowsCount >= 6) {
    _rowsColors.add(material.Colors.orange);
  }
  if (dataRowsCount > 6) {
    for (int i = 3; i < dataRowsCount; i++) {
      int colorHex = math.Random().nextInt(0xFFFFFF);
      int opacityHex = 0xFF;
      _rowsColors.add(ui.Color(colorHex + (opacityHex * math.pow(16, 6)).toInt()));
    }
  }
  return _rowsColors;
}
