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
