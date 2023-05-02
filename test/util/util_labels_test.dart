import 'package:test/test.dart'; // test package
import 'dart:ui' as ui show Color;

// Tested package
import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';
import 'package:flutter_charts/src/morphic/container/morphic_dart_enums.dart';
// import '../../lib/src/morphic/container/morphic_dart_enums.dart';

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
    ChartOrientation chartOrientation = ChartOrientation.column;
    ChartStacking chartStacking = ChartStacking.stacked;

    DataRangeLabelInfosGenerator labelsGenerator;
    
    var extendAxisToOrigin = true;
    var inputUserLabels = ['1', '2', '3'];
    var legendNames = ['Legend of row 1'];

    var valuesRows = [[1.0, 22.0, 333.0]];
    labelsGenerator = dataRangeLabelsGenerator(chartOrientation, chartStacking, extendAxisToOrigin, options, valuesRows, inputUserLabels, legendNames);
    List<AxisLabelInfo> labelInfoList = labelsGenerator.labelInfoList;
    expect(labelInfoList.length, 4);
    expect(labelInfoList[0].outputValue, 0.0);
    expect(labelInfoList[1].outputValue, 100.0);
    expect(labelInfoList[2].outputValue, 200.0);
    expect(labelInfoList[3].outputValue, 300.0);


    valuesRows = [[-1.0, -22.0, -333.0]];
    labelsGenerator = dataRangeLabelsGenerator(chartOrientation, chartStacking, extendAxisToOrigin, options, valuesRows, inputUserLabels, legendNames);
    labelInfoList = labelsGenerator.labelInfoList;
    expect(labelInfoList.length, 4);
    expect(labelInfoList[0].outputValue, -300.0);
    expect(labelInfoList[1].outputValue, -200.0);
    expect(labelInfoList[2].outputValue, -100.0);
    expect(labelInfoList[3].outputValue, 0.0);

    valuesRows = [[22.0, 10.0, -333.0]];
    labelsGenerator = dataRangeLabelsGenerator(chartOrientation, chartStacking, extendAxisToOrigin, options, valuesRows, inputUserLabels, legendNames);
    labelInfoList = labelsGenerator.labelInfoList;
    expect(labelInfoList.length, 5);
    expect(labelInfoList[0].outputValue, -300.0);
    expect(labelInfoList[1].outputValue, -200.0);
    expect(labelInfoList[2].outputValue, -100.0);
    expect(labelInfoList[3].outputValue, 0.0);
    expect(labelInfoList[4].outputValue, 100.0);

    valuesRows = [[-22.0, -10.0, 333.0]];
    labelsGenerator = dataRangeLabelsGenerator(chartOrientation, chartStacking, extendAxisToOrigin, options, valuesRows, inputUserLabels, legendNames);
    labelInfoList = labelsGenerator.labelInfoList;
    expect(labelInfoList.length, 5);
    expect(labelInfoList[0].outputValue, -100.0);
    expect(labelInfoList[1].outputValue, 0.0);
    expect(labelInfoList[2].outputValue, 100.0);
    expect(labelInfoList[3].outputValue, 200.0);
    expect(labelInfoList[4].outputValue, 300.0);

    valuesRows = [[-1000.0, 0.0, 1000.0, 2000.0]];
    labelsGenerator = dataRangeLabelsGenerator(chartOrientation, chartStacking, extendAxisToOrigin, options, valuesRows, ['1', '2', '3', '4'], legendNames);
    labelInfoList = labelsGenerator.labelInfoList;
    expect(labelInfoList.length, 4);
    expect(labelInfoList[0].outputValue, -1000.0);
    expect(labelInfoList[1].outputValue, 0.0);
    expect(labelInfoList[2].outputValue, 1000.0);
    expect(labelInfoList[3].outputValue, 2000.0);

    valuesRows = [[-1000.0, 0.0, 1000.0]];
    labelsGenerator = dataRangeLabelsGenerator(chartOrientation, chartStacking, extendAxisToOrigin, options, valuesRows, inputUserLabels, legendNames);
    labelInfoList = labelsGenerator.labelInfoList;
    expect(labelInfoList.length, 3);
    expect(labelInfoList[0].outputValue, -1000.0);
    expect(labelInfoList[1].outputValue, 0.0);
    expect(labelInfoList[2].outputValue, 1000.0);

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
  //     [[-200.0, 600.0, 2000.0, 3600.0, -800.0, 200.0, 1200.0, 2800.0, -400.0, 600.0, 2000.0, 4000.0, -800.0, 600.0, 1600.0, 3600.0, -200.0, 400.0, 1400.0, 3400.0, -600.0, 600.0, 1600.0, 3600.0], 413.42857142857144, 8.0, [-1000.0, 0.0, 1000.0, 2000.0, 3000.0, 4000.0], -800.0, 4000.0, 'Instance of DataRangeLabelInfosGenerator'],
  //     [[-200.0, 600.0, 2000.0, 3600.0, -800.0, 200.0, 1200.0, 2800.0, -400.0, 600.0, 2000.0, 4000.0, -800.0, 600.0, 1600.0, 3600.0, -200.0, 400.0, 1400.0, 3400.0, -600.0, 600.0, 1600.0, 3600.0], 441.42857142857144, 0.0, [-1000.0, 0.0, 1000.0, 2000.0, 3000.0, 4000.0], -800.0, 4000.0, 'Instance of DataRangeLabelInfosGenerator'],
  //     [[-800.0, 0.0, 1000.0, 2200.0, -600.0, 400.0, 1400.0, 2200.0, -800.0, 200.0, 800.0, 1600.0, -200.0, 0.0, 1000.0, 1600.0, -400.0, 0.0, 800.0, 2000.0, -800.0, 200.0, 1400.0, 1800.0], 413.42857142857144, 8.0, [-1000.0, 0.0, 1000.0, 2000.0], -800.0, 2200.0, 'Instance of DataRangeLabelInfosGenerator'],
  //     [[-800.0, 0.0, 1000.0, 2200.0, -600.0, 400.0, 1400.0, 2200.0, -800.0, 200.0, 800.0, 1600.0, -200.0, 0.0, 1000.0, 1600.0, -400.0, 0.0, 800.0, 2000.0, -800.0, 200.0, 1400.0, 1800.0], 441.42857142857144, 0.0, [-1000.0, 0.0, 1000.0, 2000.0], -800.0, 2200.0, 'Instance of DataRangeLabelInfosGenerator'],
  //   ];
  //   rangeTestCore(data, options, extendAxisToOrigin, byRowLegends, inputUserLabels);
  // });
  //
  // test('Range.makeLabelsGeneratorWithLabelInfosFromDataYsOnScale test - ChartOptions with startYAxisAtDataMinRequested: true forces axis labels to start above 0', () {
  //   // Here, options are not-default.
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
  //     [[20.0, 35.0, 25.0, 40.0, 30.0, 20.0, 35.0, 25.0, 40.0, 30.0, 20.0, 20.0], 413.42857142857144, 8.0, [20.0, 30.0, 40.0], 20.0, 40.0, 'Instance of DataRangeLabelInfosGenerator'],
  //     [[20.0, 35.0, 25.0, 40.0, 30.0, 20.0, 35.0, 25.0, 40.0, 30.0, 20.0, 20.0], 441.42857142857144, 0.0, [20.0, 30.0, 40.0], 20.0, 40.0, 'Instance of DataRangeLabelInfosGenerator'],
  //     // ex33 linear
  //     [[-20.0, -35.0, -25.0, -40.0, -30.0, -20.0, -35.0, -25.0, -40.0, -30.0, -20.0, -20.0], 413.42857142857144, 8.0, [-40.0, -30.0, -20.0], -40.0, -20.0, 'Instance of DataRangeLabelInfosGenerator'],
  //     [[-20.0, -35.0, -25.0, -40.0, -30.0, -20.0, -35.0, -25.0, -40.0, -30.0, -20.0, -20.0], 441.42857142857144, 0.0, [-40.0, -30.0, -20.0], -40.0, -20.0, 'Instance of DataRangeLabelInfosGenerator'],
  //   ];
  //   rangeTestCore(data, options, extendAxisToOrigin, byRowLegends, inputUserLabels);
  // });


}

DataRangeLabelInfosGenerator dataRangeLabelsGenerator(ChartOrientation chartOrientation, ChartStacking chartStacking, bool extendAxisToOrigin, ChartOptions options, List<List<double>> valuesRows, List<String> inputUserLabels, List<String> legendNames) {
  var mockChartModel = _constructMockChartModel(options, valuesRows, inputUserLabels, extendAxisToOrigin, legendNames);
  return DataRangeLabelInfosGenerator(
    /*chartViewMaker: MockChartViewMaker(
      chartModel: mockChartModel,
      chartOrientation: chartOrientation,
      isStacked: true,
    ),*/
    chartOrientation: chartOrientation,
    chartStacking: chartStacking,
    chartModel: mockChartModel,
    dataDependency: DataDependency.outputData,
    extendAxisToOrigin: extendAxisToOrigin, // start Y axis at 0
    valueToLabel: outputValueToLabel,
    inverseTransform: options.dataContainerOptions.yInverseTransform,
  );
}

class MockChartViewMaker extends ChartViewMaker {
  MockChartViewMaker({
    required ChartModel chartModel,
    required ChartOrientation chartOrientation,
    required ChartStacking chartStacking,
}): super(
    chartModel: chartModel,
    chartOrientation: chartOrientation,
    chartStacking: ChartStacking.stacked,
);

  @override
  bool get extendAxisToOrigin => false;

  @override
  ChartRootContainerCL makeChartRootContainer({required ChartViewMaker chartViewMaker}) => throw UnimplementedError();
}


MockChartModel _constructMockChartModel(
  ChartOptions options,
  List<List<double>> valuesRows,
  List<String> inputUserLabels,
  bool extendAxisToOrigin,
  List<String> legendNames,
) {
  return MockChartModel(
      chartOptions: options,
      legendNames: legendNames,
      valuesRows: valuesRows,
      inputUserLabels: inputUserLabels,
      legendColors: const [ui.Color.fromARGB(0, 0, 0, 0)],
    );
}

void rangeTestCore(
  ChartModel chartModel,
  List<List<Object>> data,
  ChartOptions options,
  bool extendAxisToOrigin,
  List<String> legendNames,
  List<String> inputUserLabels,
) {
  for (var valuesRow in data) {
    // List<double> dataYsForRange = valuesRow[0] as List<double>;
    // double axisYMin = valuesRow[1] as double;
    // double axisYMax = valuesRow[2] as double;
    List<double> expectedLabels = valuesRow[3] as List<double>;
    // double expectedDataEnvelopMin = valuesRow[4] as double;
    // double expectedDataEnvelopMax = valuesRow[5] as double;

    // Reversing min max in makeLabelsGeneratorWithLabelInfosFromDataYsOnScale why is this needed?
    //         In data, min is > max, so this is the correct thing,
    //         but why does makeLabelsGeneratorWithLabelInfosFromDataYsOnScale not adjust?
    DataRangeLabelInfosGenerator labelsGenerator = DataRangeLabelInfosGenerator(
      /*chartViewMaker: MockChartViewMaker(
        chartModel: chartModel,
        chartOrientation: ChartOrientation.column,
        isStacked: true,
      ),*/
      chartOrientation: ChartOrientation.column,
      chartStacking: ChartStacking.nonStacked,
      chartModel: chartModel,
      dataDependency: DataDependency.outputData,
      extendAxisToOrigin: extendAxisToOrigin, // start Y axis at 0
      valueToLabel: outputValueToLabel,
      inverseTransform: options.dataContainerOptions.yInverseTransform,
    );


    expect(labelsGenerator.labelInfoList.length, expectedLabels.length);
    for (int i = 0; i < labelsGenerator.labelInfoList.length; i++) {
      expect(
        labelsGenerator.labelInfoList[i].outputValue,
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

class MockChartModel extends ChartModel {
  MockChartModel({
    required valuesRows,
    required inputUserLabels,
    required legendNames,
    required chartOptions,
    List<String>? outputUserLabels,
    List<ui.Color>? legendColors,
  }) : super(
    valuesRows: valuesRows,
    inputUserLabels: inputUserLabels,
    legendNames: legendNames,
    chartOptions: chartOptions,
    outputUserLabels: outputUserLabels,
    legendColors: legendColors,
  );

}
