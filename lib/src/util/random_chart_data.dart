import 'dart:math' as math;

import 'package:flutter_charts/src/chart/data.dart';

/// Generator of sample data for testing the charts.
///
class RandomChartData extends ChartData {

  bool _useUserProvidedYLabels;
  int _numXLabels;
  int _numDataRows;
  //bool _useMonthNames;
  //int _maxLabelLength;
  bool _overlapYValues;

  /// Generate random data for chart, with number of x labels given by
  /// [numXLabels] and number of data series given by [numDataRows].
  ///
  /// If [useMonthNames] is set to false, random
  ///
  RandomChartData({
    bool useUserProvidedYLabels,
    int numXLabels = 6,
    int numDataRows = 4,
    bool useMonthNames = true,
    int maxLabelLength = 8,
    bool overlapYValues = false,
  }) {
    _useUserProvidedYLabels = useUserProvidedYLabels;
    _numXLabels = numXLabels;
    _numDataRows = numDataRows;
    //_useMonthNames = useMonthNames;
    //_maxLabelLength = maxLabelLength;
    _overlapYValues = overlapYValues;

    _generateXLabels();

    _generateYValues();

    _generateDataRowsLegends();

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
    for (var xIndex = 0; xIndex < _numXLabels; xIndex++) {
      xLabels.add(xLabelsMonths[xIndex % 12]);
    }
  }
  */

  /*
  void _generateXLabelsDows() {
    List<String> xLabelsDows = [
      'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'
    ];

    for (var xIndex = 0; xIndex < _numXLabels; xIndex++) {
      xLabels.add(xLabelsDows[xIndex % 7]);
    }
  }
  */

  void _generateXLabelsCount() {
    List<String> xLabelsDows = [
      'First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth', 'Seventh'
    ];

    for (var xIndex = 0; xIndex < _numXLabels; xIndex++) {
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
      yLabels = [ "NONE", "OK", "GOOD", "BETTER", "100%"];
    }
  }

  void _generateDataRowsLegends() {
    int dataRowsCount = dataRows.length;

    if (dataRowsCount >= 1) {
      dataRowsLegends.add("YELLOW");
    }
    if (dataRowsCount >= 2) {
      dataRowsLegends.add("GREEN");
    }
    if (dataRowsCount >= 3) {
      dataRowsLegends.add("BLUE");
    }
    if (dataRowsCount > 3) {
      for (int i = 3; i < dataRowsCount; i++) {
        // todo-1 when large value is generated, it paints outside canvas, fix.
        int number = new math.Random().nextInt(10000);
        dataRowsLegends.add("OTHER " + number.toString());
      }
    }
  }

  void _generateYValues() {
    dataRows = new List<List<double>>();

    double scale = 200.0;

    math.Random rgen = new math.Random();

    int maxYValue = 4;
    double pushUpStep = _overlapYValues ? 0.0 : maxYValue.toDouble();

    for (var rowIndex = 0; rowIndex < _numDataRows; rowIndex++) {
      dataRows.add(
          _oneDataRow(
              rgen: rgen,
              max: maxYValue,
              pushUpBy: (rowIndex - 1) * pushUpStep,
              scale: scale));
    }
    // print("Random generator data: ${_flattenData()}.");
  }

  List<double> _oneDataRow(
      {math.Random rgen, int max, double pushUpBy, double scale}) {
    List<double> dataRow = new List<double>();
    for (int i = 0; i < _numXLabels; i++) {
      dataRow.add((rgen.nextInt(max) + pushUpBy) * scale);
    }
    return dataRow;
  }

}