import 'dart:ui' as ui show Color;
import 'dart:math' as math show Random, pow;
import 'package:flutter/material.dart' as material show Colors;

// todo-00-last-last move this somewhere else - close to data or random data
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
      // todo-11-last : cast toInt added - does this change results?
      _rowsColors.add(ui.Color(colorHex + (opacityHex * math.pow(16, 6)).toInt()));
    }
  }
  return _rowsColors;
}

/// Sets up legends names, first several explicitly, rest randomly.
///
/// This is used if user does not set legends.
/// This should be kept in sync with colors below.
List<String> dataRowsDefaultLegends(int dataRowsCount) {

  List<String> _defaultLegends = List.empty(growable: true);

  if (dataRowsCount >= 1) {
    _defaultLegends.add('YELLOW');
  }
  if (dataRowsCount >= 2) {
    _defaultLegends.add('GREEN');
  }
  if (dataRowsCount >= 3) {
    _defaultLegends.add('BLUE');
  }
  if (dataRowsCount >= 4) {
    _defaultLegends.add('BLACK');
  }
  if (dataRowsCount >= 5) {
    _defaultLegends.add('GREY');
  }
  if (dataRowsCount >= 6) {
    _defaultLegends.add('ORANGE');
  }
  if (dataRowsCount > 6) {
    for (int i = 3; i < dataRowsCount; i++) {
      // todo-1 when large value is generated, it paints outside canvas, fix.
      int number = math.Random().nextInt(10000);
      _defaultLegends.add('OTHER ' + number.toString());
    }
  }
  return _defaultLegends;
}


/// Generate list of "random" [xLabels] as monthNames or weekday names.
///
///
List<String> generateXLabels(int numXLabels) {
  List<String> xLabelsDows = ['First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth', 'Seventh'];

/* todo-00-last-last
  for (int xIndex = 0; xIndex < _numXLabels; xIndex++) {
    xLabels.add(xLabelsDows[xIndex % 7]);
  }
*/
  return xLabelsDows.getRange(0, numXLabels).toList();
}

List<String> generateYLabels(bool useUserProvidedYLabels) {
  List<String> yLabels = List.empty(growable: true);
  if (useUserProvidedYLabels) {
    // yLabels = [ "0%", "25%", "50%", "75%", "100%"];
    yLabels = ['NONE', 'OK', 'GOOD', 'BETTER', '100%'];
  }
  return yLabels;
}

List<List<double>> generateYValues(int numXLabels, int _numDataRows, bool _overlapYValues) {
  List<List<double>> dataRows = List.empty(growable: true);

  double scale = 200.0;

  math.Random rgen = math.Random();

  int maxYValue = 4;
  double pushUpStep = _overlapYValues ? 0.0 : maxYValue.toDouble();

  for (int rowIndex = 0; rowIndex < _numDataRows; rowIndex++) {
    dataRows.add(_oneDataRow(
      rgen: rgen,
      max: maxYValue,
      pushUpBy: (rowIndex - 1) * pushUpStep,
      scale: scale,
      numXLabels: numXLabels
    ));
  }
  return dataRows;
}


List<double> _oneDataRow({
  required math.Random rgen,
  required int max,
  required double pushUpBy,
  required double scale,
  required int numXLabels,
}) {
  List<double> dataRow = List.empty(growable: true);
  for (int i = 0; i < numXLabels; i++) {
    dataRow.add((rgen.nextInt(max) + pushUpBy) * scale);
  }
  return dataRow;
}

void validate(List<List<double>> dataRows, List<String> dataRowsLegends, List<String> xLabels) {
  if (dataRowsLegends.isNotEmpty && dataRows.length != dataRowsLegends.length) {
    throw StateError(' If row legends are defined, their '
        'number must be the same as number of data rows. '
        ' [dataRows length: ${dataRows.length}] '
        '!= [dataRowsLegends length: ${dataRowsLegends.length}]. ');
  }
  for (List<double> dataRow in dataRows) {
    if (xLabels.isNotEmpty && dataRow.length != xLabels.length) {
      throw StateError(' If xLabels are defined, their '
          'length must be the same as length of each dataRow'
          ' [dataRow length: ${dataRow.length}] '
          '!= [xLabels length: ${xLabels.length}]. ');
    }
  }
}

