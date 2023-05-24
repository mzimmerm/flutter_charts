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

}

