import 'package:test/test.dart'; // test package
import 'dart:ui' as ui show Color;

// Tested package
import 'package:flutter_charts/flutter_charts.dart';

void main() {
  // todo 1 add tests for extrapolating . Add more tests in general

  test('Poly power and coeff', () {
    Poly p = Poly(from: 123.04);
    expect(p.signum, 1);
    expect(p.maxPower, 2);
    expect(p.coefficientAtMaxPower, 1);

    p = Poly(from: 78);
    expect(p.signum, 1);
    expect(p.maxPower, 1);
    expect(p.coefficientAtMaxPower, 7);

    p = Poly(from: 0);
    expect(p.signum, 0);
    expect(p.maxPower, 0);
    expect(p.coefficientAtMaxPower, 0);

    p = Poly(from: 0.0);
    expect(p.signum, 0);
    expect(p.maxPower, 0);
    expect(p.coefficientAtMaxPower, 0);

    p = Poly(from: 0.1);
    expect(p.signum, 1);
    expect(p.maxPower, -1);
    expect(p.coefficientAtMaxPower, 1);

    p = Poly(from: 0.01);
    expect(p.signum, 1);
    expect(p.maxPower, -2);
    expect(p.coefficientAtMaxPower, 1);

    p = Poly(from: -0.01);
    expect(p.signum, -1);
    expect(p.maxPower, -2);
    expect(p.coefficientAtMaxPower, 1);
  });

  test('Poly floor and ceil', () {
    Poly p = Poly(from: 123.04);
    expect(p.floorAtMaxPower, 100);
    expect(p.ceilAtMaxPower, 200);

    // todo 1 test pure fractions and negatives
  });

  test('Range.makeLabelsGeneratorWithLabelInfosFromDataYsOnScale', () {
    ChartOptions options = const ChartOptions();

    DataRangeLabelsGenerator labelsGenerator;
    
    var extendAxisToOrigin = true;
    var xUserLabels = ['1', '2', '3'];
    var dataRowsLegends = ['Legend of row 1'];

    var dataRows = [[1.0, 22.0, 333.0]];
    labelsGenerator = dataRangeLabelsGenerator(extendAxisToOrigin, options, dataRows, xUserLabels, dataRowsLegends);
    List<num> labels = labelsGenerator.labelPositions;
    expect(labels.length, 4);
    expect(labels[0], 0.0);
    expect(labels[1], 100.0);
    expect(labels[2], 200.0);
    expect(labels[3], 300.0);


    dataRows = [[-1.0, -22.0, -333.0]];
    labelsGenerator = dataRangeLabelsGenerator(extendAxisToOrigin, options, dataRows, xUserLabels, dataRowsLegends);
    labels = labelsGenerator.labelPositions;
    expect(labels.length, 4);
    expect(labels[0], -300.0);
    expect(labels[1], -200.0);
    expect(labels[2], -100.0);
    expect(labels[3], 0.0);

    dataRows = [[22.0, 10.0, -333.0]];
    labelsGenerator = dataRangeLabelsGenerator(extendAxisToOrigin, options, dataRows, xUserLabels, dataRowsLegends);
    labels = labelsGenerator.labelPositions;
    expect(labels.length, 5);
    expect(labels[0], -300.0);
    expect(labels[1], -200.0);
    expect(labels[2], -100.0);
    expect(labels[3], 0.0);
    expect(labels[4], 100.0);

    dataRows = [[-22.0, -10.0, 333.0]];
    labelsGenerator = dataRangeLabelsGenerator(extendAxisToOrigin, options, dataRows, xUserLabels, dataRowsLegends);
    labels = labelsGenerator.labelPositions;
    expect(labels.length, 5);
    expect(labels[0], -100.0);
    expect(labels[1], 0.0);
    expect(labels[2], 100.0);
    expect(labels[3], 200.0);
    expect(labels[4], 300.0);

    dataRows = [[-1000.0, 0.0, 1000.0, 2000.0]];
    labelsGenerator = dataRangeLabelsGenerator(extendAxisToOrigin, options, dataRows, ['1', '2', '3', '4'], dataRowsLegends);
    labels = labelsGenerator.labelPositions;
    expect(labels.length, 4);
    expect(labels[0], -1000.0);
    expect(labels[1], 0.0);
    expect(labels[2], 1000.0);
    expect(labels[3], 2000.0);

    dataRows = [[-1000.0, 0.0, 1000.0]];
    labelsGenerator = dataRangeLabelsGenerator(extendAxisToOrigin, options, dataRows, xUserLabels, dataRowsLegends);
    labels = labelsGenerator. labelPositions;
    expect(labels.length, 3);
    expect(labels[0], -1000.0);
    expect(labels[1], 0.0);
    expect(labels[2], 1000.0);

  });


  // test('Range.makeLabelsGeneratorWithLabelInfosFromDataYsOnScale test - default ChartOptions forces labels start at 0', () {
  //   ChartOptions options = const ChartOptions();
  //   // The requested option (default) must be confirmed with behavior (this mimicks asking for 0 start on any TopChartContainer)
  //   bool extendAxisToOrigin = false;
  //
  //   // The only independent things are: _dataYs, axisYMin, axisYMax. The rest (distributedLabelYs) are derived
  //   // [List _dataYs for Range constructor, axisYMin, axisYMax, distributedLabelYs, dataYEnvelop, labelsGenerator] - labelsGenerator is unused, will recreate
  //   var data = [
  //     [[1.0, 22.0, 333.0], 500.0, 100.0, [0.0, 100.0, 200.0, 300.0], 0.0, 333.0, 'ignore'],
  //     [[1.0, 22.0, 333.0], 500.0, 100.0, [0.0, 100.0, 200.0, 300.0], 0.0, 333.0, 'ignore'],
  //
  //     // ex10 linear and bar
  //     [[-200.0, 600.0, 2000.0, 3600.0, -800.0, 200.0, 1200.0, 2800.0, -400.0, 600.0, 2000.0, 4000.0, -800.0, 600.0, 1600.0, 3600.0, -200.0, 400.0, 1400.0, 3400.0, -600.0, 600.0, 1600.0, 3600.0], 413.42857142857144, 8.0, [-1000.0, 0.0, 1000.0, 2000.0, 3000.0, 4000.0], -800.0, 4000.0, 'Instance of DataRangeLabelsGenerator'],
  //     [[-200.0, 600.0, 2000.0, 3600.0, -800.0, 200.0, 1200.0, 2800.0, -400.0, 600.0, 2000.0, 4000.0, -800.0, 600.0, 1600.0, 3600.0, -200.0, 400.0, 1400.0, 3400.0, -600.0, 600.0, 1600.0, 3600.0], 441.42857142857144, 0.0, [-1000.0, 0.0, 1000.0, 2000.0, 3000.0, 4000.0], -800.0, 4000.0, 'Instance of DataRangeLabelsGenerator'],
  //     [[-800.0, 0.0, 1000.0, 2200.0, -600.0, 400.0, 1400.0, 2200.0, -800.0, 200.0, 800.0, 1600.0, -200.0, 0.0, 1000.0, 1600.0, -400.0, 0.0, 800.0, 2000.0, -800.0, 200.0, 1400.0, 1800.0], 413.42857142857144, 8.0, [-1000.0, 0.0, 1000.0, 2000.0], -800.0, 2200.0, 'Instance of DataRangeLabelsGenerator'],
  //     [[-800.0, 0.0, 1000.0, 2200.0, -600.0, 400.0, 1400.0, 2200.0, -800.0, 200.0, 800.0, 1600.0, -200.0, 0.0, 1000.0, 1600.0, -400.0, 0.0, 800.0, 2000.0, -800.0, 200.0, 1400.0, 1800.0], 441.42857142857144, 0.0, [-1000.0, 0.0, 1000.0, 2000.0], -800.0, 2200.0, 'Instance of DataRangeLabelsGenerator'],
  //   ];
  //   rangeTestCore(data, options, extendAxisToOrigin, dataRowsLegends, xUserLabels);
  // });
  //
  // test('Range.makeLabelsGeneratorWithLabelInfosFromDataYsOnScale test - ChartOptions with startYAxisAtDataMinRequested: true forces axis labels to start above 0', () {
  //   // Here, options are non-default.
  //   ChartOptions options = const ChartOptions(
  //     dataContainerOptions: DataContainerOptions(startYAxisAtDataMinRequested: true),
  //   );
  //   // The requested option must be confirmed with behavior (this mimicks asking for above 0 start on LineChartContainer)
  //   bool extendAxisToOrigin = true;
  //
  //   // The only independent things are: _dataYs, axisYMin, axisYMax. The rest (distributedLabelYs) are derived
  //   // [List _dataYs for Range constructor, axisYMin, axisYMax, distributedLabelYs, dataYEnvelop, labelsGenerator] - labelsGenerator is unused, will recreate
  //   var data = [
  //     // ex32 linear
  //     [[20.0, 35.0, 25.0, 40.0, 30.0, 20.0, 35.0, 25.0, 40.0, 30.0, 20.0, 20.0], 413.42857142857144, 8.0, [20.0, 30.0, 40.0], 20.0, 40.0, 'Instance of DataRangeLabelsGenerator'],
  //     [[20.0, 35.0, 25.0, 40.0, 30.0, 20.0, 35.0, 25.0, 40.0, 30.0, 20.0, 20.0], 441.42857142857144, 0.0, [20.0, 30.0, 40.0], 20.0, 40.0, 'Instance of DataRangeLabelsGenerator'],
  //     // ex33 linear
  //     [[-20.0, -35.0, -25.0, -40.0, -30.0, -20.0, -35.0, -25.0, -40.0, -30.0, -20.0, -20.0], 413.42857142857144, 8.0, [-40.0, -30.0, -20.0], -40.0, -20.0, 'Instance of DataRangeLabelsGenerator'],
  //     [[-20.0, -35.0, -25.0, -40.0, -30.0, -20.0, -35.0, -25.0, -40.0, -30.0, -20.0, -20.0], 441.42857142857144, 0.0, [-40.0, -30.0, -20.0], -40.0, -20.0, 'Instance of DataRangeLabelsGenerator'],
  //   ];
  //   rangeTestCore(data, options, extendAxisToOrigin, dataRowsLegends, xUserLabels);
  // });


}

DataRangeLabelsGenerator dataRangeLabelsGenerator(bool extendAxisToOrigin, ChartOptions options, List<List<double>> dataRows, List<String> xUserLabels, List<String> dataRowsLegends) {
  return DataRangeLabelsGenerator(
    extendAxisToOrigin: extendAxisToOrigin, // start Y axis at 0
    valueToLabel: options.yContainerOptions.valueToLabel,
    inverseTransform: options.dataContainerOptions.yInverseTransform,
    dataModel: _constructMockNewModel(options, dataRows, xUserLabels, extendAxisToOrigin, dataRowsLegends),
    isStacked: false,
  );
}

MockNewModel _constructMockNewModel(
  ChartOptions options,
  List<List<double>> dataRows,
  List<String> xUserLabels,
  bool extendAxisToOrigin,
  List<String> dataRowsLegends,
) {
  return MockNewModel(
      chartOptions: options,
      dataRowsLegends: dataRowsLegends,
      dataRows: dataRows,
      xUserLabels: xUserLabels,
      dataRowsColors: [const ui.Color.fromARGB(0, 0, 0, 0)],
    );
}

void rangeTestCore(
  NewModel dataModel,
  List<List<Object>> data,
  ChartOptions options,
  bool extendAxisToOrigin,
  List<String> dataRowsLegends,
  List<String> xUserLabels,
) {
  for (var dataRow in data) {
    // List<double> dataYsForRange = dataRow[0] as List<double>;
    // double axisYMin = dataRow[1] as double;
    // double axisYMax = dataRow[2] as double;
    List<double> expectedLabels = dataRow[3] as List<double>;
    // double expectedDataEnvelopMin = dataRow[4] as double;
    // double expectedDataEnvelopMax = dataRow[5] as double;

    // Reversing min max in makeLabelsGeneratorWithLabelInfosFromDataYsOnScale why is this needed?
    //         In data, min is > max, so this is the correct thing,
    //         but why does makeLabelsGeneratorWithLabelInfosFromDataYsOnScale not adjust?
    DataRangeLabelsGenerator labelsGenerator = DataRangeLabelsGenerator(
      dataModel: dataModel,
      extendAxisToOrigin: extendAxisToOrigin, // start Y axis at 0
      valueToLabel: options.yContainerOptions.valueToLabel,
      inverseTransform: options.dataContainerOptions.yInverseTransform,
      isStacked: false,
    );


    // expect(labelsGenerator.dataYsEnvelope.min, expectedDataEnvelopMin);
    // expect(labelsGenerator.dataYsEnvelope.max, expectedDataEnvelopMax);
    expect(labelsGenerator.labelPositions.length, expectedLabels.length);
    for (int i = 0; i < labelsGenerator.labelPositions.length; i++) {
      expect(
        labelsGenerator.labelPositions[i],
        expectedLabels[i],
      );
    }
  }
}

class StartYAxisAtDataMinAllowedChartBehavior extends Object with ChartBehavior {
  @override
  bool get extendAxisToOrigin => true;
}

class StartYAxisAtDataMinProhibitedChartBehavior extends Object with ChartBehavior {
  @override
  bool get extendAxisToOrigin => false;
}

class MockNewModel extends NewModel {
  MockNewModel({
    required dataRows,
    required xUserLabels,
    required dataRowsLegends,
    required chartOptions,
    List<String>? yUserLabels,
    List<ui.Color>? dataRowsColors,
  }) : super(
    dataRows: dataRows,
    xUserLabels: xUserLabels,
    dataRowsLegends: dataRowsLegends,
    chartOptions: chartOptions,
    yUserLabels: yUserLabels,
    dataRowsColors: dataRowsColors,
  );

}
