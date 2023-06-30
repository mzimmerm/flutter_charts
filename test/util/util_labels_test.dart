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

  test('Range.makeRangeDescriptorWithLabelInfosFromDataYsOnScale', () {
    ChartOptions options = const ChartOptions();
    ChartOrientation chartOrientation = ChartOrientation.column;
    ChartStacking chartStacking = ChartStacking.stacked;

    DataRangeTicksAndLabelsDescriptor rangeDescriptor;
    
    var extendAxisToOrigin = true;
    var inputUserLabels = ['1', '2', '3'];
    var legendNames = ['Legend of row 1'];

    var dataRows = [[1.0, 22.0, 333.0]];
    rangeDescriptor = dataRangeRangeDescriptor(chartOrientation, chartStacking, extendAxisToOrigin, options, dataRows, inputUserLabels, legendNames);
    List<AxisLabelInfo> labelInfoList = rangeDescriptor.labelInfoList;
    expect(labelInfoList.length, 4);
    expect(labelInfoList[0].centerTickValue, 0.0);
    expect(labelInfoList[1].centerTickValue, 100.0);
    expect(labelInfoList[2].centerTickValue, 200.0);
    expect(labelInfoList[3].centerTickValue, 300.0);


    dataRows = [[-1.0, -22.0, -333.0]];
    rangeDescriptor = dataRangeRangeDescriptor(chartOrientation, chartStacking, extendAxisToOrigin, options, dataRows, inputUserLabels, legendNames);
    labelInfoList = rangeDescriptor.labelInfoList;
    expect(labelInfoList.length, 4);
    expect(labelInfoList[0].centerTickValue, -300.0);
    expect(labelInfoList[1].centerTickValue, -200.0);
    expect(labelInfoList[2].centerTickValue, -100.0);
    expect(labelInfoList[3].centerTickValue, 0.0);

    dataRows = [[22.0, 10.0, -333.0]];
    rangeDescriptor = dataRangeRangeDescriptor(chartOrientation, chartStacking, extendAxisToOrigin, options, dataRows, inputUserLabels, legendNames);
    labelInfoList = rangeDescriptor.labelInfoList;
    expect(labelInfoList.length, 5);
    expect(labelInfoList[0].centerTickValue, -300.0);
    expect(labelInfoList[1].centerTickValue, -200.0);
    expect(labelInfoList[2].centerTickValue, -100.0);
    expect(labelInfoList[3].centerTickValue, 0.0);
    expect(labelInfoList[4].centerTickValue, 100.0);

    dataRows = [[-22.0, -10.0, 333.0]];
    rangeDescriptor = dataRangeRangeDescriptor(chartOrientation, chartStacking, extendAxisToOrigin, options, dataRows, inputUserLabels, legendNames);
    labelInfoList = rangeDescriptor.labelInfoList;
    expect(labelInfoList.length, 5);
    expect(labelInfoList[0].centerTickValue, -100.0);
    expect(labelInfoList[1].centerTickValue, 0.0);
    expect(labelInfoList[2].centerTickValue, 100.0);
    expect(labelInfoList[3].centerTickValue, 200.0);
    expect(labelInfoList[4].centerTickValue, 300.0);

    dataRows = [[-1000.0, 0.0, 1000.0, 2000.0]];
    rangeDescriptor = dataRangeRangeDescriptor(chartOrientation, chartStacking, extendAxisToOrigin, options, dataRows, ['1', '2', '3', '4'], legendNames);
    labelInfoList = rangeDescriptor.labelInfoList;
    expect(labelInfoList.length, 4);
    expect(labelInfoList[0].centerTickValue, -1000.0);
    expect(labelInfoList[1].centerTickValue, 0.0);
    expect(labelInfoList[2].centerTickValue, 1000.0);
    expect(labelInfoList[3].centerTickValue, 2000.0);

    dataRows = [[-1000.0, 0.0, 1000.0]];
    rangeDescriptor = dataRangeRangeDescriptor(chartOrientation, chartStacking, extendAxisToOrigin, options, dataRows, inputUserLabels, legendNames);
    labelInfoList = rangeDescriptor.labelInfoList;
    expect(labelInfoList.length, 3);
    expect(labelInfoList[0].centerTickValue, -1000.0);
    expect(labelInfoList[1].centerTickValue, 0.0);
    expect(labelInfoList[2].centerTickValue, 1000.0);

  });

}

DataRangeTicksAndLabelsDescriptor dataRangeRangeDescriptor(ChartOrientation chartOrientation, ChartStacking chartStacking, bool extendAxisToOrigin, ChartOptions options, List<List<double>> dataRows, List<String> inputUserLabels, List<String> legendNames) {
  var mockChartModel = _constructMockChartModel(options, dataRows, inputUserLabels, extendAxisToOrigin, legendNames);
  return DataRangeTicksAndLabelsDescriptor(
    chartOrientation: chartOrientation,
    chartStacking: chartStacking,
    chartViewModel: MockChartViewModel(
      chartModel: mockChartModel,
      chartType: ChartType.lineChart,
      chartOrientation: chartOrientation,
      chartStacking: ChartStacking.stacked,
    ),
    dataDependency: DataDependency.outputData,
    extendAxisToOrigin: extendAxisToOrigin, // start Y axis at 0
    valueToLabel: outputValueToLabel,
    inverseTransform: options.dataContainerOptions.yInverseTransform,
  );
}

class MockChartViewModel extends ChartViewModel {
  MockChartViewModel({
    required ChartModel chartModel,
    required ChartType chartType,
    required ChartOrientation chartOrientation,
    required ChartStacking chartStacking,
}): super(
    chartModel: chartModel,
    chartType: chartType,
    chartOrientation: chartOrientation,
    chartStacking: ChartStacking.stacked,
);

  @override
  bool get extendAxisToOrigin => false;

  @override
  ChartRootContainerCL makeChartRootContainer({required ChartViewModel chartViewModel}) => throw UnimplementedError();
}


MockChartModel _constructMockChartModel(
  ChartOptions options,
  List<List<double>> dataRows,
  List<String> inputUserLabels,
  bool extendAxisToOrigin,
  List<String> legendNames,
) {
  return MockChartModel(
      chartOptions: options,
      legendNames: legendNames,
      dataRows: dataRows,
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

    // Reversing min max in makeRangeDescriptorWithLabelInfosFromDataYsOnScale why is this needed?
    //         In data, min is > max, so this is the correct thing,
    //         but why does makeRangeDescriptorWithLabelInfosFromDataYsOnScale not adjust?
    DataRangeTicksAndLabelsDescriptor rangeDescriptor = DataRangeTicksAndLabelsDescriptor(
      chartOrientation: ChartOrientation.column,
      chartStacking: ChartStacking.nonStacked,
      chartViewModel: MockChartViewModel(
        chartModel: chartModel,
        chartType: ChartType.lineChart,
        chartOrientation: ChartOrientation.column,
        chartStacking: ChartStacking.stacked,
      ),
      dataDependency: DataDependency.outputData,
      extendAxisToOrigin: extendAxisToOrigin, // start Y axis at 0
      valueToLabel: outputValueToLabel,
      inverseTransform: options.dataContainerOptions.yInverseTransform,
    );


    expect(rangeDescriptor.labelInfoList.length, expectedLabels.length);
    for (int i = 0; i < rangeDescriptor.labelInfoList.length; i++) {
      expect(
        rangeDescriptor.labelInfoList[i].centerTickValue,
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
    required dataRows,
    required inputUserLabels,
    required legendNames,
    required chartOptions,
    List<String>? outputUserLabels,
    List<ui.Color>? legendColors,
  }) : super(
    dataRows: dataRows,
    inputUserLabels: inputUserLabels,
    legendNames: legendNames,
    chartOptions: chartOptions,
    outputUserLabels: outputUserLabels,
    legendColors: legendColors,
  );

}
