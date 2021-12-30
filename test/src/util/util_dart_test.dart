import 'package:test/test.dart'; // Dart test package
import 'package:flutter_charts/flutter_charts.dart';

void main() {
  test('linear scaling test', () {
    expect(scaleValue(
      value: 1.0,
      fromDomainMin: 1.0,
      fromDomainMax: 2.0,
      toDomainMin: 10.0,
      toDomainMax: 20.0,
    ),
    10.0);
  });

  var data = [
    [1.0, 1.0, 2.0, 10.0, 20.0, 10.0],
    [2.0, 1.0, 2.0, 10.0, 20.0, 20.0],
    [0.0, -1000.0, 2200.0, 413.42857142857144, 8.0, 286.7321428571429],
    [2000.0, -1000.0, 2200.0, 413.42857142857144, 8.0, 33.33928571428572],
    [-600.0, -1000.0, 2200.0, 413.42857142857144, 8.0, 362.75],
    [0.0, -1000.0, 2200.0, 413.42857142857144, 8.0, 286.7321428571429],
    [-600.0, -1000.0, 2200.0, 413.42857142857144, 8.0, 362.75],
    [600.0, -1000.0, 2200.0, 413.42857142857144, 8.0, 210.71428571428572],
    [0.0, -1000.0, 2200.0, 413.42857142857144, 8.0, 286.7321428571429],
    [600.0, -1000.0, 2200.0, 413.42857142857144, 8.0, 210.71428571428572],
    [1400.0, -1000.0, 2200.0, 413.42857142857144, 8.0, 109.35714285714289],
    [600.0, -1000.0, 2200.0, 413.42857142857144, 8.0, 210.71428571428572],
    
  ];

  for (var oneData in data) {
    test('linear scaling test with array input', () {
      expect(
          scaleValue(
            value:         oneData[0],
            fromDomainMin: oneData[1],
            fromDomainMax: oneData[2],
            toDomainMin:   oneData[3],
            toDomainMax:   oneData[4],
          ),
          oneData[5]);
    });
  }
}
