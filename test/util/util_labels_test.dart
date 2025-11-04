import 'package:test/test.dart'; // test package
import 'dart:ui' as ui show Color;

// Tested package
import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';
import 'package:flutter_charts/src/morphic/container/morphic_dart_enums.dart';
import 'package:flutter_charts/src/chart/cartesian/view_model/view_model.dart' show ChartViewModel;
import 'package:flutter_charts/src/coded_layout/chart/container.dart';

void main() {
  // todo 1 add tests for extrapolating . Add more tests in general

  test('Range.makeRangeDescriptorWithLabelInfosFromDataYsOnScale', () {
    // Should this be options from test?
    ChartOptions options = const ChartOptions();
    ChartOrientation chartOrientation = ChartOrientation.column;
    ChartStacking chartStacking = ChartStacking.stacked;

    AxisIntervalTicksAndLabelsDescriptor axisIntervalDescriptor;
    
    var extendAxisToOrigin = true;
    var inputUserLabels = ['1', '2', '3'];
    var legendNames = ['Legend of row 1'];

    var dataRows = [[1.0, 22.0, 333.0]];
    axisIntervalDescriptor = makeAxisIntervalDescriptor(chartOrientation, chartStacking, extendAxisToOrigin, options, dataRows, inputUserLabels, legendNames);
    List<AxisLabelInfo> labelInfoList = axisIntervalDescriptor.labelInfoList;
    expect(labelInfoList.length, 4);
    expect(labelInfoList[0].centerTickValue, 0.0);
    expect(labelInfoList[1].centerTickValue, 100.0);
    expect(labelInfoList[2].centerTickValue, 200.0);
    expect(labelInfoList[3].centerTickValue, 300.0);


    dataRows = [[-1.0, -22.0, -333.0]];
    axisIntervalDescriptor = makeAxisIntervalDescriptor(chartOrientation, chartStacking, extendAxisToOrigin, options, dataRows, inputUserLabels, legendNames);
    labelInfoList = axisIntervalDescriptor.labelInfoList;
    expect(labelInfoList.length, 4);
    expect(labelInfoList[0].centerTickValue, -300.0);
    expect(labelInfoList[1].centerTickValue, -200.0);
    expect(labelInfoList[2].centerTickValue, -100.0);
    expect(labelInfoList[3].centerTickValue, 0.0);

    dataRows = [[22.0, 10.0, -333.0]];
    axisIntervalDescriptor = makeAxisIntervalDescriptor(chartOrientation, chartStacking, extendAxisToOrigin, options, dataRows, inputUserLabels, legendNames);
    labelInfoList = axisIntervalDescriptor.labelInfoList;
    expect(labelInfoList.length, 5);
    expect(labelInfoList[0].centerTickValue, -300.0);
    expect(labelInfoList[1].centerTickValue, -200.0);
    expect(labelInfoList[2].centerTickValue, -100.0);
    expect(labelInfoList[3].centerTickValue, 0.0);
    expect(labelInfoList[4].centerTickValue, 100.0);

    dataRows = [[-22.0, -10.0, 333.0]];
    axisIntervalDescriptor = makeAxisIntervalDescriptor(chartOrientation, chartStacking, extendAxisToOrigin, options, dataRows, inputUserLabels, legendNames);
    labelInfoList = axisIntervalDescriptor.labelInfoList;
    expect(labelInfoList.length, 5);
    expect(labelInfoList[0].centerTickValue, -100.0);
    expect(labelInfoList[1].centerTickValue, 0.0);
    expect(labelInfoList[2].centerTickValue, 100.0);
    expect(labelInfoList[3].centerTickValue, 200.0);
    expect(labelInfoList[4].centerTickValue, 300.0);

    dataRows = [[-1000.0, 0.0, 1000.0, 2000.0]];
    axisIntervalDescriptor = makeAxisIntervalDescriptor(chartOrientation, chartStacking, extendAxisToOrigin, options, dataRows, ['1', '2', '3', '4'], legendNames);
    labelInfoList = axisIntervalDescriptor.labelInfoList;
    expect(labelInfoList.length, 4);
    expect(labelInfoList[0].centerTickValue, -1000.0);
    expect(labelInfoList[1].centerTickValue, 0.0);
    expect(labelInfoList[2].centerTickValue, 1000.0);
    expect(labelInfoList[3].centerTickValue, 2000.0);

    dataRows = [[-1000.0, 0.0, 1000.0]];
    axisIntervalDescriptor = makeAxisIntervalDescriptor(chartOrientation, chartStacking, extendAxisToOrigin, options, dataRows, inputUserLabels, legendNames);
    labelInfoList = axisIntervalDescriptor.labelInfoList;
    expect(labelInfoList.length, 3);
    expect(labelInfoList[0].centerTickValue, -1000.0);
    expect(labelInfoList[1].centerTickValue, 0.0);
    expect(labelInfoList[2].centerTickValue, 1000.0);

  });

}

AxisIntervalTicksAndLabelsDescriptor makeAxisIntervalDescriptor(ChartOrientation chartOrientation, ChartStacking chartStacking, bool extendAxisToOrigin, ChartOptions options, List<List<double>> dataRows, List<String> inputUserLabels, List<String> legendNames) {
  var mockChartModel = _constructMockChartModel(options, dataRows, inputUserLabels, extendAxisToOrigin, legendNames);
  return AxisIntervalTicksAndLabelsDescriptor(
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
    AxisIntervalTicksAndLabelsDescriptor axisIntervalDescriptor = AxisIntervalTicksAndLabelsDescriptor(
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


    expect(axisIntervalDescriptor.labelInfoList.length, expectedLabels.length);
    for (int i = 0; i < axisIntervalDescriptor.labelInfoList.length; i++) {
      expect(
        axisIntervalDescriptor.labelInfoList[i].centerTickValue,
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
