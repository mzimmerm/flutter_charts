import 'package:test/test.dart';

import 'package:flutter_charts/flutter_charts.dart';

void main() {
  // todo 1 add tests for scaling . Add more tests in general

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

  test('Range.makeYScalerWithLabelInfosFromDataYsOnScale', () {
    ChartOptions options = const ChartOptions();
    double axisYMin = 100.0;
    double axisYMax = 500.0;

    // todo-00-last Range range;
    YScalerAndLabelFormatter yScaler;

    // todo-00-last range = Range(dataYs: [1.0, 22.0, 333.0];
    var dataYs = [1.0, 22.0, 333.0];
    yScaler = YScalerAndLabelFormatter(dataYs: dataYs, axisY: Interval(axisYMin, axisYMax), chartOptions: options);
    Interval dataYEnvelop = yScaler.dataYsEnvelop;
    List<num> labels = yScaler.dataYsOfLabels;
    expect(dataYEnvelop.min, 0.0);
    expect(dataYEnvelop.max, 333.0);
    expect(labels.length, 4);
    expect(labels[0], 0.0);
    expect(labels[1], 100.0);
    expect(labels[2], 200.0);
    expect(labels[3], 300.0);

    dataYs = [-1.0, -22.0, -333.0];
    yScaler = YScalerAndLabelFormatter(dataYs: dataYs, axisY: Interval(axisYMin, axisYMax), chartOptions: options);
    dataYEnvelop = yScaler.dataYsEnvelop;
    labels = yScaler.dataYsOfLabels;
    expect(dataYEnvelop.min, -333.0);
    expect(dataYEnvelop.max, 0.0);
    expect(labels.length, 4);
    expect(labels[0], -300.0);
    expect(labels[1], -200.0);
    expect(labels[2], -100.0);
    expect(labels[3], 0.0);

    dataYs = [22.0, 10.0, -333.0];
    yScaler = YScalerAndLabelFormatter(dataYs: dataYs, axisY: Interval(axisYMin, axisYMax), chartOptions: options);
    dataYEnvelop = yScaler.dataYsEnvelop;
    labels = yScaler.dataYsOfLabels;
    expect(dataYEnvelop.min, -333.0);
    expect(dataYEnvelop.max, 22.0);
    expect(labels.length, 5);
    expect(labels[0], -300.0);
    expect(labels[1], -200.0);
    expect(labels[2], -100.0);
    expect(labels[3], 0.0);
    expect(labels[4], 100.0);

    dataYs = [-22.0, -10.0, 333.0];
    yScaler = YScalerAndLabelFormatter(dataYs: dataYs, axisY: Interval(axisYMin, axisYMax), chartOptions: options);
    dataYEnvelop = yScaler.dataYsEnvelop;
    labels = yScaler.dataYsOfLabels;
    expect(dataYEnvelop.min, -22.0);
    expect(dataYEnvelop.max, 333.0);
    expect(labels.length, 5);
    expect(labels[0], -100.0);
    expect(labels[1], 0.0);
    expect(labels[2], 100.0);
    expect(labels[3], 200.0);
    expect(labels[4], 300.0);

    dataYs = [-1000.0, 0.0, 1000.0, 2000.0];
    yScaler = YScalerAndLabelFormatter(dataYs: dataYs, axisY: Interval(axisYMin, axisYMax), chartOptions: options);
    dataYEnvelop = yScaler.dataYsEnvelop;
    labels = yScaler.dataYsOfLabels;
    expect(dataYEnvelop.min, -1000.0);
    expect(dataYEnvelop.max, 2000.0);
    expect(labels.length, 4);
    expect(labels[0], -1000.0);
    expect(labels[1], 0.0);
    expect(labels[2], 1000.0);
    expect(labels[3], 2000.0);

    dataYs = [-1000.0, 0.0, 1000.0];
    yScaler = YScalerAndLabelFormatter(dataYs: dataYs, axisY: Interval(axisYMin, axisYMax), chartOptions: options);
    dataYEnvelop = yScaler.dataYsEnvelop;
    labels = yScaler.dataYsOfLabels;
    expect(dataYEnvelop.min, -1000.0);
    expect(dataYEnvelop.max, 1000.0);
    expect(labels.length, 3);
    expect(labels[0], -1000.0);
    expect(labels[1], 0.0);
    expect(labels[2], 1000.0);
  });

  test('Range.makeYScalerWithLabelInfosFromDataYsOnScale test - default ChartOptions forces labels start at 0', () {
    ChartOptions options = const ChartOptions();

    // The only independent things are: _dataYs, axisYMin, axisYMax. The rest (distributedLabelYs) are derived
    // [List _dataYs for Range constructor, axisYMin, axisYMax, distributedLabelYs, dataYEnvelop, yScaler] - yScaler is unused, will recreate
    var data = [
      [[1.0, 22.0, 333.0], 500.0, 100.0, [0.0, 100.0, 200.0, 300.0], 0.0, 333.0, 'ignore'],
      [[1.0, 22.0, 333.0], 500.0, 100.0, [0.0, 100.0, 200.0, 300.0], 0.0, 333.0, 'ignore'],
      
      // ex11 linear and bar
      /*
      [[-200.0, 600.0, 2000.0, 3600.0, -800.0, 200.0, 1200.0, 2800.0, -400.0, 600.0, 2000.0, 4000.0, -800.0, 600.0, 1600.0, 3600.0, -200.0, 400.0, 1400.0, 3400.0, -600.0, 600.0, 1600.0, 3600.0], 413.42857142857144, 8.0, [-1000.0, 0.0, 1000.0, 2000.0, 3000.0, 4000.0], -800.0, 4000.0, 'Instance of YScalerAndLabelFormatter'],
      [[-200.0, 600.0, 2000.0, 3600.0, -800.0, 200.0, 1200.0, 2800.0, -400.0, 600.0, 2000.0, 4000.0, -800.0, 600.0, 1600.0, 3600.0, -200.0, 400.0, 1400.0, 3400.0, -600.0, 600.0, 1600.0, 3600.0], 441.42857142857144, 0.0, [-1000.0, 0.0, 1000.0, 2000.0, 3000.0, 4000.0], -800.0, 4000.0, 'Instance of YScalerAndLabelFormatter'],
      [[-800.0, 0.0, 1000.0, 2200.0, -600.0, 400.0, 1400.0, 2200.0, -800.0, 200.0, 800.0, 1600.0, -200.0, 0.0, 1000.0, 1600.0, -400.0, 0.0, 800.0, 2000.0, -800.0, 200.0, 1400.0, 1800.0], 413.42857142857144, 8.0, [-1000.0, 0.0, 1000.0, 2000.0], -800.0, 2200.0, 'Instance of YScalerAndLabelFormatter'],
      [[-800.0, 0.0, 1000.0, 2200.0, -600.0, 400.0, 1400.0, 2200.0, -800.0, 200.0, 800.0, 1600.0, -200.0, 0.0, 1000.0, 1600.0, -400.0, 0.0, 800.0, 2000.0, -800.0, 200.0, 1400.0, 1800.0], 441.42857142857144, 0.0, [-1000.0, 0.0, 1000.0, 2000.0], -800.0, 2200.0, 'Instance of YScalerAndLabelFormatter'],
      */
      [[-200.0, 600.0, 2000.0, 3600.0, -800.0, 200.0, 1200.0, 2800.0, -400.0, 600.0, 2000.0, 4000.0, -800.0, 600.0, 1600.0, 3600.0, -200.0, 400.0, 1400.0, 3400.0, -600.0, 600.0, 1600.0, 3600.0], 413.42857142857144, 8.0, [-1000.0, 0.0, 1000.0, 2000.0, 3000.0, 4000.0], -800.0, 4000.0, 'Instance of YScalerAndLabelFormatter'],
      [[-200.0, 600.0, 2000.0, 3600.0, -800.0, 200.0, 1200.0, 2800.0, -400.0, 600.0, 2000.0, 4000.0, -800.0, 600.0, 1600.0, 3600.0, -200.0, 400.0, 1400.0, 3400.0, -600.0, 600.0, 1600.0, 3600.0], 441.42857142857144, 0.0, [-1000.0, 0.0, 1000.0, 2000.0, 3000.0, 4000.0], -800.0, 4000.0, 'Instance of YScalerAndLabelFormatter'],
      [[-800.0, 0.0, 1000.0, 2200.0, -600.0, 400.0, 1400.0, 2200.0, -800.0, 200.0, 800.0, 1600.0, -200.0, 0.0, 1000.0, 1600.0, -400.0, 0.0, 800.0, 2000.0, -800.0, 200.0, 1400.0, 1800.0], 413.42857142857144, 8.0, [-1000.0, 0.0, 1000.0, 2000.0], -800.0, 2200.0, 'Instance of YScalerAndLabelFormatter'],
      [[-800.0, 0.0, 1000.0, 2200.0, -600.0, 400.0, 1400.0, 2200.0, -800.0, 200.0, 800.0, 1600.0, -200.0, 0.0, 1000.0, 1600.0, -400.0, 0.0, 800.0, 2000.0, -800.0, 200.0, 1400.0, 1800.0], 441.42857142857144, 0.0, [-1000.0, 0.0, 1000.0, 2000.0], -800.0, 2200.0, 'Instance of YScalerAndLabelFormatter'],
    ];
    rangeTestCore(data, options);
  });

  test('Range.makeYScalerWithLabelInfosFromDataYsOnScale test - ChartOptions with startYAxisAtDataMinRequested: true forces axis labels to start above 0', () {
    // Here, options are non-default.
    ChartOptions options = const ChartOptions(
      dataContainerOptions: DataContainerOptions(startYAxisAtDataMinRequested: true),
    );

    // The only independent things are: _dataYs, axisYMin, axisYMax. The rest (distributedLabelYs) are derived
    // [List _dataYs for Range constructor, axisYMin, axisYMax, distributedLabelYs, dataYEnvelop, yScaler] - yScaler is unused, will recreate
    var data = [
      /*
      // ex32 linear
      [[20.0, 35.0, 25.0, 40.0, 30.0, 20.0, 35.0, 25.0, 40.0, 30.0, 20.0, 20.0], 413.42857142857144, 8.0, [20.0, 30.0, 40.0], 20.0, 40.0, 'Instance of YScalerAndLabelFormatter'],
      [[20.0, 35.0, 25.0, 40.0, 30.0, 20.0, 35.0, 25.0, 40.0, 30.0, 20.0, 20.0], 441.42857142857144, 0.0, [20.0, 30.0, 40.0], 20.0, 40.0, 'Instance of YScalerAndLabelFormatter'],
      // ex33 linear
      [[-20.0, -35.0, -25.0, -40.0, -30.0, -20.0, -35.0, -25.0, -40.0, -30.0, -20.0, -20.0], 413.42857142857144, 8.0, [-40.0, -30.0, -20.0], -40.0, -20.0, 'Instance of YScalerAndLabelFormatter'],
      [[-20.0, -35.0, -25.0, -40.0, -30.0, -20.0, -35.0, -25.0, -40.0, -30.0, -20.0, -20.0], 441.42857142857144, 0.0, [-40.0, -30.0, -20.0], -40.0, -20.0, 'Instance of YScalerAndLabelFormatter'],
      */
      // ex32 linear
      [[20.0, 35.0, 25.0, 40.0, 30.0, 20.0, 35.0, 25.0, 40.0, 30.0, 20.0, 20.0], 413.42857142857144, 8.0, [20.0, 30.0, 40.0], 20.0, 40.0, 'Instance of YScalerAndLabelFormatter'],
      [[20.0, 35.0, 25.0, 40.0, 30.0, 20.0, 35.0, 25.0, 40.0, 30.0, 20.0, 20.0], 441.42857142857144, 0.0, [20.0, 30.0, 40.0], 20.0, 40.0, 'Instance of YScalerAndLabelFormatter'],
      // ex33 linear
      [[-20.0, -35.0, -25.0, -40.0, -30.0, -20.0, -35.0, -25.0, -40.0, -30.0, -20.0, -20.0], 413.42857142857144, 8.0, [-40.0, -30.0, -20.0], -40.0, -20.0, 'Instance of YScalerAndLabelFormatter'],
      [[-20.0, -35.0, -25.0, -40.0, -30.0, -20.0, -35.0, -25.0, -40.0, -30.0, -20.0, -20.0], 441.42857142857144, 0.0, [-40.0, -30.0, -20.0], -40.0, -20.0, 'Instance of YScalerAndLabelFormatter'],
    ];
    rangeTestCore(data, options);
  });

}

void rangeTestCore(List<List<Object>> data, ChartOptions options) {
  for (var dataRow in data) {
    List<double> dataYsForRange = dataRow[0] as List<double>;
    double axisYMin = dataRow[1] as double;
    double axisYMax = dataRow[2] as double;
    List<double> expectedLabels = dataRow[3] as List<double>;
    double expectedDataEnvelopMin = dataRow[4] as double;
    double expectedDataEnvelopMax = dataRow[5] as double;

    // todo-00 Reversing min max in makeYScalerWithLabelInfosFromDataYsOnScale why is this needed?
    //         In data, min is > max, so this is the correct thing,
    //         but why does makeYScalerWithLabelInfosFromDataYsOnScale not adjust?
    YScalerAndLabelFormatter yScaler = YScalerAndLabelFormatter(dataYs: dataYsForRange, axisY: Interval(axisYMax, axisYMin), chartOptions: options);

    expect(yScaler.dataYsEnvelop.min, expectedDataEnvelopMin);
    expect(yScaler.dataYsEnvelop.max, expectedDataEnvelopMax);
    expect(yScaler.dataYsOfLabels.length, expectedLabels.length);
    for (int i = 0; i < yScaler.dataYsOfLabels.length; i++) {
      expect(
        yScaler.dataYsOfLabels[i],
        expectedLabels[i],
      );
    }
  }
}

