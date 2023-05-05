import 'package:test/test.dart';

// import '../../../lib/src/util/util_dart.dart';

import '../../../lib/src/util/vector/vector_2d.dart';
import '../../../lib/src/util/vector/matrix_2d.dart';
import '../../../lib/src/util/vector/function_matrix_2d.dart';

void main() {
  group('double matrices and vectors', () {

    test('matrix.applyOnVector', () {
      var v = Vector([1.0, 2.0]);
      var m = MatrixDouble2D<double>([
        [10.0, 20.0],
        [100.0, 200.0],
      ]);
      var result = Vector([50.0, 500.0]);

      expect(result == m.applyOnVector(v), true);
    });

/*
    test('matrix * matrix', () {
      var m1 = MatrixDouble2D<double>([
        [10.0, 20.0],
        [100.0, 200.0],
      ]);
      var m2 = MatrixDouble2D<double>([
        [10.0, 20.0],
        [100.0, 200.0],
      ]);
      var m1v1Result = Vector([50.0, 500.0]);

      expect(m1v1Result == m1.applyOnVector(v1), true);
    });
*/

  });

  group('functional matrices and vectors', () {
    test('applyOnVector 1', () {
      var v = Vector([1.0, 2.0]);
      var m = FunctionalMatrix2D<Functional>([
        [Functional((x) => 10 * x), Functional((x) => 20 * x)],
        [Functional((x) => 100 * x), Functional((x) => 200 * x)],
      ]);
      var result = Vector([50.0, 500.0]);

      expect(result == m.applyOnVector(v), true);
    });

    test('applyOnVector 2', () {
      var v = Vector([1.0, 2.0]);
      var m = FunctionalMatrix2D<Functional>([
        [Functional((x) => x), Functional((x) => 2 * x)],
        [Functional((x) => 3 * x), Functional((x) => 4 * x)],
      ]);
      var result = Vector([5.0, 11.0]);

      expect(result == m.applyOnVector(v), true);
    });
  });

  // todo-010 : move to function_test.dart
  group('Functions', () {
    group('Functions == : Same result producing functions are not ==', () {
      double f(double arg) => arg * arg;
      double g(double arg) => arg * arg;
      test('f == g', () {
        assert(f == f, true);
        assert(g == g, true);
        // Always throws, whether true or false. Use expect instead of assert: assert(f == g, true);
        expect((f == f), true);
        expect((g == g), true);
        expect((f == g), false);
        });
      });
    });

  /* todo-010 remove
  test('vectors2', () {
    var data = [
      [-65.0, -40.0, -20.0,      8.0, 413.42857142857144,  920.2142857142858],
      [-70.0, -40.0, -20.0,      8.0, 413.42857142857144,  1021.5714285714286],
      [0.0, -40.0, -20.0,        8.0, 413.42857142857144,  -397.428571428571434],
    ];

    expect(ToPixelsLTransform1D(
      fromValues: const Interval(1.0, 2.0),
      toPixels: const Interval(10.0, 20.0),
    ).apply(1.0),
      10.0,);

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

