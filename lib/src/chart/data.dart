import 'dart:ui' as ui show Color;
import 'package:flutter_charts/flutter_charts.dart';
import '../util/util_data.dart' as util_data;

// todo-00-last-last : Make final and immutable and rethink completely.
//                     Should be able to set defaults for everything, unless set on construction time.

class ChartData {
  
  /// Data in rows. Each row of data represents one data series.
  ///
  /// Legends per row are managed by [dataRowsLegends].
  ///
  /// Each element of outer list represents one row.
  /// Alternative name would be "data series".
  final List<List<double>> dataRows;

  /// Labels on independent (X) axis.
  ///
  /// It is assumed labels are defined, by the client
  /// and their number is the same as number of points
  /// in each row in [dataRows].
  final List<String> xUserLabels;

  /// Provides legends for [dataRows] (data series).
  ///
  /// One Legend String per row.
  /// Alternative name would be "series names".
  final List<String> dataRowsLegends;

  /// User defined labels to be used by the chart, instead of labels auto-generated from data.
  /// 
  /// Can be Strings or numbers. 
  /// If not null, a "manual" layout is used, specifically the [YContainer.layoutManually()].
  /// If null, a "auto" layout of Y axis is used.
  /// 
  final List<String>? yUserLabels;

  /// Colors corresponding to each data row (series) in [ChartData].
  List<ui.Color>? dataRowsColors;
  
  /// Default constructor only assumes [dataRows] are set,
  /// and assigns default values of [dataRowsLegends], [dataRowsColors], [xUserLabels], [yUserLabels].
  ///
  ChartData({
    required this.dataRows,
    required this.xUserLabels,
    required this.dataRowsLegends,
    this.yUserLabels,
    this.dataRowsColors,
  }) {
    dataRowsColors ??= util_data.dataRowsDefaultColors(dataRows.length);

    // todo-00-last-last : deal with yUserLabels and xUserLabels
    util_data.validate(this);
  }
  
  bool get isUsingUserLabels => yUserLabels != null;
}
