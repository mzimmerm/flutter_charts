import 'package:flutter_charts/src/chart/data.dart';
import '../util/util_data.dart' as util_data;
import 'dart:ui' as ui show Color;

/// Generator of sample data for testing the charts.
///
class RandomChartData implements ChartData {
  @override
  final List<List<double>> dataRows;
  @override
  final List<String> xLabels;
  @override
  final List<String> dataRowsLegends;
  @override
  List<String>? yLabels;
  @override
  List<ui.Color>? dataRowsColors;
  
  /// Generate random data for chart, with number of x labels given by
  /// [numXLabels] and number of data series given by [numDataRows].
  ///
  /// If [useMonthNames] is set to false, random
  ///
  RandomChartData({
    // todo-00-last-last required this.dataRows,
    // this.dataRowsLegends,
    bool useUserProvidedYLabels = false,
    int numXLabels = 6,
    int numDataRows = 4,
    bool useMonthNames = true,
    int maxLabelLength = 8,
    bool overlapYValues = false,
  })  : 
        xLabels = util_data.generateXLabels(numXLabels),
        dataRows = util_data.generateYValues(numXLabels, numDataRows, overlapYValues),
        // if 
        yLabels = util_data.generateYLabels(useUserProvidedYLabels),
        dataRowsLegends = util_data.dataRowsDefaultLegends(numDataRows),
        dataRowsColors = util_data.dataRowsDefaultColors(numDataRows) {
    // todo-00-last-last : deal with yLabels
    util_data.validate(dataRows, dataRowsLegends, xLabels);
  }
}
