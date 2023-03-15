import 'dart:math' as math show Random;

import '../options.dart';
import 'data_model_new.dart';

// The single unnamed constructor (like primary factory in Newspeak). Must call super.
/// Generator of sample data for testing the charts.
///
class RandomChartData extends ChartModel {
  RandomChartData({
    required dataRows,
    required xUserLabels,
    required dataRowsLegends,
    required chartOptions,
    yUserLabels,
    dataRowsColors,
  }) : super(
          dataRows: dataRows,
          xUserLabels: xUserLabels,
          dataRowsLegends: dataRowsLegends,
          chartOptions: chartOptions,
          yUserLabels: yUserLabels,
          dataRowsColors: dataRowsColors,
        );

  // Redirecting constructors just redirects to an 'unnamed' constructor on same class - the RandomChartData(args) constructor.
  /// Generate random data for chart, with number of x labels given by
  /// [numXLabels] and number of data series given by [numDataRows].
  ///
  /// If [useMonthNames] is set to false, random
  ///
  RandomChartData.generated({
    required ChartOptions chartOptions,
    bool useUserProvidedYLabels = false,
    int numXLabels = 6,
    int numDataRows = 4,
    bool useMonthNames = true,
    int maxLabelLength = 8,
    bool overlapDataYs = false,
    dataRowsColors,
  }) : this(
          dataRows: randomDataYs(numXLabels, numDataRows, overlapDataYs),
          xUserLabels: randomDataXLabels(numXLabels),
          dataRowsLegends: randomDataRowsLegends(numDataRows),
          chartOptions: chartOptions,
          yUserLabels: randomDataYLabels(useUserProvidedYLabels),
          dataRowsColors: dataRowsColors,
        );
}

/// Sets up legends names, first several explicitly, rest randomly.
///
/// This is used if user does not set legends.
/// This should be kept in sync with colors below.
List<String> randomDataRowsLegends(int dataRowsCount) {
  List<String> defaultLegends = List.empty(growable: true);

  if (dataRowsCount >= 1) {
    defaultLegends.add('YELLOW' /*' with really long description'*/);
  }
  if (dataRowsCount >= 2) {
    defaultLegends.add('GREEN');
  }
  if (dataRowsCount >= 3) {
    defaultLegends.add('BLUE');
  }
  if (dataRowsCount >= 4) {
    defaultLegends.add('BLACK');
  }
  if (dataRowsCount >= 5) {
    defaultLegends.add('GREY');
  }
  if (dataRowsCount >= 6) {
    defaultLegends.add('ORANGE');
  }
  if (dataRowsCount > 6) {
    for (int i = 3; i < dataRowsCount; i++) {
      // todo-1 when large value is generated, it paints outside canvas, fix.
      int number = math.Random().nextInt(10000);
      defaultLegends.add('OTHER  ${number.toString()}');
    }
  }
  return defaultLegends;
}

/// Generate list of "random" [xUserLabels] as monthNames or weekday names.
///
///
List<String> randomDataXLabels(int numXLabels) {
  List<String> xLabelsDows = ['First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth', 'Seventh'];
  return xLabelsDows.getRange(0, numXLabels).toList();
}

List<String>? randomDataYLabels(bool useUserProvidedYLabels) {
  List<String>? yUserLabels;
  if (useUserProvidedYLabels) {
    yUserLabels = ['NONE', 'OK', 'GOOD', 'BETTER', '100%'];
  }
  return yUserLabels;
}

List<List<double>> randomDataYs(int numXLabels, int numDataRows, bool overlapDataYs) {
  List<List<double>> dataRows = List.empty(growable: true);

  double scale = 200.0;

  math.Random rgen = math.Random();

  int maxDataY = 4;
  double pushUpStep = overlapDataYs ? 0.0 : maxDataY.toDouble();

  for (int rowIndex = 0; rowIndex < numDataRows; rowIndex++) {
    dataRows.add(_randomDataOneRow(
      rgen: rgen,
      max: maxDataY,
      pushUpBy: (rowIndex - 1) * pushUpStep,
      scale: scale,
      numXLabels: numXLabels,
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
