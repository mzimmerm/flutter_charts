import 'dart:ui' as ui show Color;
import 'dart:math' as math show Random, pow;
import 'package:flutter/material.dart' as material show Colors;
import '../../src/chart/data.dart' as data show ChartData;

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
List<String> randomDataRowsLegends(int dataRowsCount) {

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


/// Generate list of "random" [xUserLabels] as monthNames or weekday names.
///
///
List<String> randomDataXLabels(int numXLabels) {
  List<String> xLabelsDows = ['First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth', 'Seventh'];

/* todo-00-last-last
  for (int xIndex = 0; xIndex < _numXLabels; xIndex++) {
    xUserLabels.add(xLabelsDows[xIndex % 7]);
  }
*/
  return xLabelsDows.getRange(0, numXLabels).toList();
}

List<String>? randomDataYLabels(bool useUserProvidedYLabels) {
  List<String>? yUserLabels;
  if (useUserProvidedYLabels) {
    yUserLabels = ['NONE', 'OK', 'GOOD', 'BETTER', '100%'];
  }
  return yUserLabels;
}

List<List<double>> randomDataYValues(int numXLabels, int _numDataRows, bool _overlapYValues) {
  List<List<double>> dataRows = List.empty(growable: true);

  double scale = 200.0;

  math.Random rgen = math.Random();

  int maxYValue = 4;
  double pushUpStep = _overlapYValues ? 0.0 : maxYValue.toDouble();

  for (int rowIndex = 0; rowIndex < _numDataRows; rowIndex++) {
    dataRows.add(_randomDataOneRow(
      rgen: rgen,
      max: maxYValue,
      pushUpBy: (rowIndex - 1) * pushUpStep,
      scale: scale,
      numXLabels: numXLabels
    ));
  }
  return dataRows;
}

List<double> _randomDataOneRow({
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

void validate(data.ChartData chartData) {
  //                      But that would require ChartOptions available in ChartData. 
  if (chartData.dataRowsLegends.isNotEmpty && chartData.dataRows.length != chartData.dataRowsLegends.length) {
    throw StateError(' If row legends are defined, their '
        'number must be the same as number of data rows. '
        ' [dataRows length: ${chartData.dataRows.length}] '
        '!= [dataRowsLegends length: ${chartData.dataRowsLegends.length}]. ');
  }
  for (List<double> dataRow in chartData.dataRows) {
    if (chartData.xUserLabels.isNotEmpty && dataRow.length != chartData.xUserLabels.length) {
      throw StateError(' If xUserLabels are defined, their '
          'length must be the same as length of each dataRow'
          ' [dataRow length: ${dataRow.length}] '
          '!= [xUserLabels length: ${chartData.xUserLabels.length}]. ');
    }
  }
}

