import 'dart:math' as math;

import 'package:flutter_charts/src/chart/data.dart';

/// Generator of sample data for testing the charts.
///
class RandomChartData extends ChartData {
  /// If true, Y labels are not numbers, but values
  /// hardwired in this class.
  final bool _useUserProvidedYLabels;
  final int _numXLabels;
  final int _numDataRows;

  //bool _useMonthNames;
  //int _maxLabelLength;
  final bool _overlapYValues;

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
  })  : _useUserProvidedYLabels = useUserProvidedYLabels,
        _numXLabels = numXLabels,
        _numDataRows = numDataRows,
        //_useMonthNames = useMonthNames,
        //_maxLabelLength = maxLabelLength,
        _overlapYValues = overlapYValues {
    _generateXLabels();

    _generateYValues();

    assignDataRowsDefaultLegends();

    _generateYLabels();

    assignDataRowsDefaultColors();

    validate();
  }

  /*
  /// Generate list of "random" [xLabels] as monthNames
  ///
  ///
  void _generateXLabelsMonths() {
    List<String> xLabelsMonths = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];

    // for (var xIndex in new Iterable.generate(_numXLabels, (i) => i)) {
    for (int xIndex = 0; xIndex < _numXLabels; xIndex++) {
      xLabels.add(xLabelsMonths[xIndex % 12]);
    }
  }
  */

  /*
  void _generateXLabelsDows() {
    List<String> xLabelsDows = [
      'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'
    ];

    for (int xIndex = 0; xIndex < _numXLabels; xIndex++) {
      xLabels.add(xLabelsDows[xIndex % 7]);
    }
  }
  */

  void _generateXLabelsCount() {
    List<String> xLabelsDows = ['First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth', 'Seventh'];

    for (int xIndex = 0; xIndex < _numXLabels; xIndex++) {
      xLabels.add(xLabelsDows[xIndex % 7]);
    }
  }

  /// Generate list of "random" [xLabels] as monthNames or weekday names.
  ///
  ///
  void _generateXLabels() {
    _generateXLabelsCount();
  }

  void _generateYLabels() {
    if (_useUserProvidedYLabels) {
      // yLabels = [ "0%", "25%", "50%", "75%", "100%"];
      yLabels = ['NONE', 'OK', 'GOOD', 'BETTER', '100%'];
    }
  }

  void _generateYValues() {
    dataRows = List.empty(growable: true);

    double scale = 200.0;

    math.Random rgen = math.Random();

    int maxYValue = 4;
    double pushUpStep = _overlapYValues ? 0.0 : maxYValue.toDouble();

    for (int rowIndex = 0; rowIndex < _numDataRows; rowIndex++) {
      dataRows.add(_oneDataRow(rgen: rgen, max: maxYValue, pushUpBy: (rowIndex - 1) * pushUpStep, scale: scale));
    }
    // print("Random generator data: ${_flattenData()}.");
  }

  List<double> _oneDataRow({
    required math.Random rgen,
    required int max,
    required double pushUpBy,
    required double scale,
  }) {
    List<double> dataRow = List.empty(growable: true);
    for (int i = 0; i < _numXLabels; i++) {
      dataRow.add((rgen.nextInt(max) + pushUpBy) * scale);
    }
    return dataRow;
  }
}
