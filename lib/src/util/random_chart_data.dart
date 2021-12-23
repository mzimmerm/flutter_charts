import 'package:flutter_charts/src/chart/data.dart';
import '../util/util_data.dart' as util_data;
import 'dart:ui' as ui show Color;

/// Generator of sample data for testing the charts.
///
class RandomChartData implements ChartData {
  @override
  final List<List<double>> dataRows;
  @override
  final List<String> xUserLabels;
  @override
  final List<String> dataRowsLegends;
  @override
  final List<String>? yUserLabels;
  @override
  List<ui.Color>? dataRowsColors;
  
  /// Generate random data for chart, with number of x labels given by
  /// [numXLabels] and number of data series given by [numDataRows].
  ///
  /// If [useMonthNames] is set to false, random
  ///
  RandomChartData({
    bool useUserProvidedYLabels = false,
    int numXLabels = 6,
    int numDataRows = 4,
    bool useMonthNames = true,
    int maxLabelLength = 8,
    bool overlapYValues = false,
  })  : 
        xUserLabels = util_data.randomDataXLabels(numXLabels),
        dataRows = util_data.randomDataYValues(numXLabels, numDataRows, overlapYValues),
        yUserLabels = util_data.randomDataYLabels(useUserProvidedYLabels),
        dataRowsLegends = util_data.randomDataRowsLegends(numDataRows),
        dataRowsColors = util_data.dataRowsDefaultColors(numDataRows) {
    util_data.validate(this);
  }
  @override
  bool get isUsingUserLabels => yUserLabels != null;
}
