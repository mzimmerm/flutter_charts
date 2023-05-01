import 'dart:math' as math show Random;

import '../options.dart';
import 'data_model.dart';

// The single unnamed constructor (like primary factory in Newspeak). Must call super.
/// Generator of sample data for testing the charts.
///
class RandomChartModel extends ChartModel {
  RandomChartModel({
    required valuesRows,
    required inputUserLabels,
    required byRowLegends,
    required chartOptions,
    outputUserLabels,
    byRowColors,
  }) : super(
          valuesRows: valuesRows,
          inputUserLabels: inputUserLabels,
          byRowLegends: byRowLegends,
          chartOptions: chartOptions,
          outputUserLabels: outputUserLabels,
          byRowColors: byRowColors,
        );

  // Redirecting constructors just redirects to an 'unnamed' constructor on same class - the RandomChartModel(args) constructor.
  /// Generate random data for chart, with number of x labels given by
  /// [numXLabels] and number of data series given by [numDataRows].
  ///
  /// If [useMonthNames] is set to false, random
  ///
  RandomChartModel.generated({
    required ChartOptions chartOptions,
    bool useUserProvidedYLabels = false,
    int numXLabels = 6,
    int numDataRows = 4,
    bool useMonthNames = true,
    int maxLabelLength = 8,
    bool overlapDataYs = false,
    byRowColors,
  }) : this(
          valuesRows: randomDataYs(numXLabels, numDataRows, overlapDataYs),
          inputUserLabels: randomDataXLabels(numXLabels),
          byRowLegends: randomDataRowsLegends(numDataRows),
          chartOptions: chartOptions,
          outputUserLabels: randomDataYLabels(useUserProvidedYLabels),
          byRowColors: byRowColors,
        );
}

/// Sets up legends names, first several explicitly, rest randomly.
///
/// This is used if user does not set legends.
/// This should be kept in sync with colors below.
List<String> randomDataRowsLegends(int valuesRowsCount) {
  List<String> defaultLegends = List.empty(growable: true);

  if (valuesRowsCount >= 1) {
    defaultLegends.add('YELLOW' /*' with really long description'*/);
  }
  if (valuesRowsCount >= 2) {
    defaultLegends.add('GREEN');
  }
  if (valuesRowsCount >= 3) {
    defaultLegends.add('BLUE');
  }
  if (valuesRowsCount >= 4) {
    defaultLegends.add('BLACK');
  }
  if (valuesRowsCount >= 5) {
    defaultLegends.add('GREY');
  }
  if (valuesRowsCount >= 6) {
    defaultLegends.add('ORANGE');
  }
  if (valuesRowsCount > 6) {
    for (int i = 3; i < valuesRowsCount; i++) {
      // todo-1 when large value is generated, it paints outside canvas, fix.
      int number = math.Random().nextInt(10000);
      defaultLegends.add('OTHER  ${number.toString()}');
    }
  }
  return defaultLegends;
}

/// Generate list of "random" [inputUserLabels] as monthNames or weekday names.
///
///
List<String> randomDataXLabels(int numXLabels) {
  List<String> xLabelsDows = ['First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth', 'Seventh'];
  return xLabelsDows.getRange(0, numXLabels).toList();
}

List<String>? randomDataYLabels(bool useUserProvidedYLabels) {
  List<String>? outputUserLabels;
  if (useUserProvidedYLabels) {
    outputUserLabels = ['NONE', 'OK', 'GOOD', 'BETTER', '100%'];
  }
  return outputUserLabels;
}

List<List<double>> randomDataYs(int numXLabels, int numDataRows, bool overlapDataYs) {
  List<List<double>> valuesRows = List.empty(growable: true);

  double scale = 200.0;

  math.Random rgen = math.Random();

  int maxDataY = 4;
  double pushUpStep = overlapDataYs ? 0.0 : maxDataY.toDouble();

  for (int rowIndex = 0; rowIndex < numDataRows; rowIndex++) {
    valuesRows.add(_randomDataOneRow(
      rgen: rgen,
      max: maxDataY,
      pushUpBy: (rowIndex - 1) * pushUpStep,
      scale: scale,
      numXLabels: numXLabels,
    ));
  }
  return valuesRows;
}

List<double> _randomDataOneRow({
  required math.Random rgen,
  required int max,
  required double pushUpBy,
  required double scale,
  required int numXLabels,
}) {
  List<double> valuesRow = List.empty(growable: true);
  for (int i = 0; i < numXLabels; i++) {
    valuesRow.add((rgen.nextInt(max) + pushUpBy) * scale);
  }
  return valuesRow;
}
