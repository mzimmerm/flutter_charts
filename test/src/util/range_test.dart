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

  test('Range makeLabelsFromDataOnScale', () {
    ChartOptions options = const ChartOptions();
    double min = 100.0;
    double max = 500.0;

    Range r;
    YScalerAndLabelFormatter lsf;

    r = Range(values: [1.0, 22.0, 333.0], chartOptions: options);
    lsf = r.makeLabelsFromDataOnScale(axisYMin: min, axisYMax: max);
    Interval c = lsf.dataYsEnvelop;
    List<num> labels = lsf.dataYLabelValues;
    expect(c.min, 0.0);
    expect(c.max, 333.0);
    expect(labels.length, 4);
    expect(labels[0], 0.0);
    expect(labels[1], 100.0);
    expect(labels[2], 200.0);
    expect(labels[3], 300.0);

    r = Range(values: [-1.0, -22.0, -333.0], chartOptions: options);
    lsf = r.makeLabelsFromDataOnScale(axisYMin: min, axisYMax: max);
    c = lsf.dataYsEnvelop;
    labels = lsf.dataYLabelValues;
    expect(c.min, -333.0);
    expect(c.max, 0.0);
    expect(labels.length, 4);
    expect(labels[0], -300.0);
    expect(labels[1], -200.0);
    expect(labels[2], -100.0);
    expect(labels[3], 0.0);

    r = Range(values: [22.0, 10.0, -333.0], chartOptions: options);
    lsf = r.makeLabelsFromDataOnScale(axisYMin: min, axisYMax: max);
    c = lsf.dataYsEnvelop;
    labels = lsf.dataYLabelValues;
    expect(c.min, -333.0);
    expect(c.max, 22.0);
    expect(labels.length, 5);
    expect(labels[0], -300.0);
    expect(labels[1], -200.0);
    expect(labels[2], -100.0);
    expect(labels[3], 0.0);
    expect(labels[4], 100.0);

    r = Range(values: [-22.0, -10.0, 333.0], chartOptions: options);
    lsf = r.makeLabelsFromDataOnScale(axisYMin: min, axisYMax: max);
    c = lsf.dataYsEnvelop;
    labels = lsf.dataYLabelValues;
    expect(c.min, -22.0);
    expect(c.max, 333.0);
    expect(labels.length, 5);
    expect(labels[0], -100.0);
    expect(labels[1], 0.0);
    expect(labels[2], 100.0);
    expect(labels[3], 200.0);
    expect(labels[4], 300.0);

    r = Range(values: [-1000.0, 0.0, 1000.0, 2000.0], chartOptions: options);
    lsf = r.makeLabelsFromDataOnScale(axisYMin: min, axisYMax: max);
    c = lsf.dataYsEnvelop;
    labels = lsf.dataYLabelValues;
    expect(c.min, -1000.0);
    expect(c.max, 2000.0);
    expect(labels.length, 4);
    expect(labels[0], -1000.0);
    expect(labels[1], 0.0);
    expect(labels[2], 1000.0);
    expect(labels[3], 2000.0);

    r = Range(values: [-1000.0, 0.0, 1000.0], chartOptions: options);
    lsf = r.makeLabelsFromDataOnScale(axisYMin: min, axisYMax: max);
    c = lsf.dataYsEnvelop;
    labels = lsf.dataYLabelValues;
    expect(c.min, -1000.0);
    expect(c.max, 1000.0);
    expect(labels.length, 3);
    expect(labels[0], -1000.0);
    expect(labels[1], 0.0);
    expect(labels[2], 1000.0);

    // todo 1 test pure fractions, and combination of pure fractions and mixed (whole.fraction)
  });
}
