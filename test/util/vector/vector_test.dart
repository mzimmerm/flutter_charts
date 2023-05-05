import 'package:test/test.dart';

import '../../../lib/src/util/util_dart.dart';

import '../../../lib/src/util/vector/vector_2d.dart';
import '../../../lib/src/util/vector/matrix_2d.dart';
import '../../../lib/src/util/vector/function_matrix_2d.dart';

void main() {
  test('vectors 1', () {
    var v1 = Vector([1.0, 2.0]);
    var m1 = MatrixDouble2D<double>([
      [10.0, 20.0],
      [100.0, 200.0],
    ]);
    var m1v1Result = Vector([50.0, 500.0]);

    /* expect(ToPixelsLTransform1D(
      fromValues: const Interval(1.0, 2.0),
      toPixels: const Interval(10.0, 20.0),
    ).apply(1.0),
      10.0,);*/
    expect (m1v1Result == m1.applyOnVector(v1), true);
  });

  /*
  test('vecrors2', () {
    var data = [
      [-65.0, -40.0, -20.0,      8.0, 413.42857142857144,  920.2142857142858],
      [-70.0, -40.0, -20.0,      8.0, 413.42857142857144,  1021.5714285714286],
      [0.0, -40.0, -20.0,        8.0, 413.42857142857144,  -397.428571428571434],
    ];
    for (var valuesRow in data) {
      expect(
        isCloserThanEpsilon(
            DomainLTransform1D(
              fromDomainStart: valuesRow[1],
              fromDomainEnd: valuesRow[2],
              toDomainStart: valuesRow[4],
              toDomainEnd: valuesRow[3],
            ).apply(valuesRow[0]),
            valuesRow[5]
        ),
        true,
      );
    }
  });
*/
}

