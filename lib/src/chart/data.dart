import 'dart:math' as math;
import 'dart:ui' as ui show Color;
import 'package:flutter/material.dart' as material show Colors;
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
  final List<List<double>> dataRows; //  = List.empty(growable: true);

  /// Labels on independent (X) axis.
  ///
  /// It is assumed labels are defined, by the client
  /// and their number is the same as number of points
  /// in each row in [dataRows].
  final List<String> xLabels; // = List.empty(growable: true);

  /// Provides legends for [dataRows] (data series).
  ///
  /// One Legend String per row.
  /// Alternative name would be "series names".
  final List<String> dataRowsLegends; // = List.empty(growable: true);

  /// Labels on dependent (Y) axis.
  ///
  /// - If you need Data-Generated Y label numbers with units (e.g. %),
  ///   - Do not set [yLabels]
  ///   - Set [YContainerOptions.useUserProvidedYLabels] to false
  ///   - define [YContainerOptions.yLabelUnits] in options
  /// - If you need User-Defined "Ordinal" (Strings with order) Y labels,
  ///   - Set [yLabels] to ordinal values
  ///   - Set [YContainerOptions.useUserProvidedYLabels] to true.
  ///   - [YContainerOptions.yLabelUnits] are ignored
  ///
  /// This [yLabels] member is used only if
  /// [YContainerOptions.useUserProvidedYLabels] is true.
  ///
  final List<String>? yLabels; // = List.empty(growable: true); // todo-00-last-last can be made non nullable?

  /// Colors corresponding to each data row (series) in [ChartData].
  List<ui.Color>? dataRowsColors;  // todo-00-last-last can be made non nullable?
  
  /// Default constructor only assumes [dataRows] are set,
  /// and assigns default values of [dataRowsLegends], [dataRowsColors], [xLabels], [yLabels].
  ///
  // todo-00-last-last : make final and always define with DataRows.
  ChartData({
    required this.dataRows,
    required this.xLabels,
    required this.dataRowsLegends,
    this.yLabels,
    this.dataRowsColors,
  }) {
    dataRowsColors ??= util_data.dataRowsDefaultColors(dataRows.length);

    // todo-00-last-last : deal with yLabels
    util_data.validate(dataRows, dataRowsLegends, xLabels);
  }

/*
  List<double> _flattenData() {
    return dataRows.expand((i) => i).toList();
  }

  double maxData() {
    return _flattenData().reduce(math.max);
  }

  double minData() {
    return _flattenData().reduce(math.min);
  }
*/

}
