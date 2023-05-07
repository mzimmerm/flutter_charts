import 'package:test/test.dart';

// import '../../../lib/src/util/util_dart.dart';

import '../../../lib/src/util/vector/vector_2d.dart';
import '../../../lib/src/util/vector/matrix_2d.dart';
import '../../../lib/src/util/vector/function_matrix_2d.dart';

void main() {
  group('double matrices and vectors', () {

    test('doubleMatrix.applyOnVector', () {
      var v = Vector([1.0, 2.0]);
      var m = DoubleMatrix2D<double>([
        [10.0, 20.0],
        [100.0, 200.0],
      ]);
      var result = Vector([50.0, 500.0]);

      expect(result == m.applyOnVector(v), true);
    });

    test('doubleMatrix * doubleMatrix', () {
      var m1 = DoubleMatrix2D<double>([
        [10.0, 20.0],
        [100.0, 200.0],
      ]);
      var m2 = DoubleMatrix2D<double>([
        [1.0, 2.0],
        [3.0, 4.0],
      ]);
      var result = DoubleMatrix2D<double>([
        [70.0, 100.0],
        [700.0, 1000.0],
      ]);
      var wrongResult = DoubleMatrix2D<double>([
        [70.0, 100.0],
        [700.0, 1111.0],
      ]);

      expect(result == (m1 * m2), true);

      expect(wrongResult == (m1 * m2), false);
    });

    test('doubleMatrix + doubleMatrix', () {
      var m1 = DoubleMatrix2D<double>([
        [10.0, 20.0],
        [100.0, 200.0],
      ]);
      var m2 = DoubleMatrix2D<double>([
        [1.0, 2.0],
        [3.0, 4.0],
      ]);
      var result = DoubleMatrix2D<double>([
        [11.0, 22.0],
        [103.0, 204.0],
      ]);
      var wrongResult = DoubleMatrix2D<double>([
        [11.0, 22.0],
        [103.0, 1111.0],
      ]);

      expect(result == (m1 + m2), true);

      expect(wrongResult == (m1 + m2), false);
    });
  });

  group('functional matrices and vectors', () {
    test('funcMatrix.applyOnVector', () {
      var v = Vector([1.0, 2.0]);
      var m = FunctionalMatrix2D<Functional>([
        [(x) => 10 * x, (x) => 20 * x],
        [(x) => 100 * x, (x) => 200 * x],
      ]);
      var result = Vector([50.0, 500.0]);

      expect(result == m.applyOnVector(v), true);
    });

    test('funcMatrix * funcMatrix', () {
      var m1 = FunctionalMatrix2D<Functional>([
        [(x) => 10 * x, (x) => 20 * x],
        [(x) => 100 * x, (x) => 200 * x],
      ]);
      var m2 = FunctionalMatrix2D<Functional>([
        [(x) => 1 * x, (x) => 2 * x],
        [(x) => 3 * x, (x) => 4 * x],
      ]);
      var result = FunctionalMatrix2D<Functional>([
        [(x) => 70 * x, (x) => 100 * x],
        [(x) => 700 * x, (x) => 1000 * x],
      ]);
      var wrongResult = FunctionalMatrix2D<Functional>([
        [(x) => 70 * x, (x) => 100 * x],
        [(x) => 700 * x, (x) => 1111 * x],
      ]);

      expect(result == (m1 * m2), true);

      expect(wrongResult == (m1 * m2), false);
    });

    test('funcMatrix + funcMatrix', () {
      var m1 = FunctionalMatrix2D<Functional>([
        [(x) => 10 * x, (x) => 20 * x],
        [(x) => 100 * x, (x) => 200 * x],
      ]);
      var m2 = FunctionalMatrix2D<Functional>([
        [(x) => 1 * x, (x) => 2 * x],
        [(x) => 3 * x, (x) => 4 * x],
      ]);
      var result = FunctionalMatrix2D<Functional>([
        [(x) => 11 * x, (x) => 22 * x],
        [(x) => 103 * x, (x) => 204 * x],
      ]);
      var wrongResult = FunctionalMatrix2D<Functional>([
        [(x) => 11 * x, (x) => 22 * x],
        [(x) => 103 * x, (x) => 1111 * x],
      ]);

      expect(result == (m1 + m2), true);

      expect(wrongResult == (m1 + m2), false);
    });

  });


  /* todo-010 : probably remove
    test('applyOnVector 2', () {
      var v = Vector([1.0, 2.0]);
      var m = FunctionalMatrix2D<Functional>([
        [Functional((x) => x), Functional((x) => 2 * x)],
        [Functional((x) => 3 * x), Functional((x) => 4 * x)],
      ]);
      var result = Vector([5.0, 11.0]);

      expect(result == m.applyOnVector(v), true);
    });

   */
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
        isCloserThanEpsilon( Během pře
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

