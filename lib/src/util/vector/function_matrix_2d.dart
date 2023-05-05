import 'matrix_2d.dart';

typedef DoubleToDoubleFunction = double Function(double);

extension DoubleToDoubleFunctional on DoubleToDoubleFunction {
/*
  DoubleToDoubleFunction operator +(DoubleToDoubleFunction other) => (double arg) => this(arg) + other(arg);
  DoubleToDoubleFunction multiplyN(double number) => (double arg) => number * this(arg);
  DoubleToDoubleFunction operator *(DoubleToDoubleFunction other) => (double arg) => this(other(arg)); // * is compose
*/
  DoubleToDoubleFunction addT(DoubleToDoubleFunction other) => (double arg) => this(arg) + other(arg);
  DoubleToDoubleFunction multiplyN(double number) => (double arg) => number * this(arg);
  DoubleToDoubleFunction multiplyT(DoubleToDoubleFunction other) => (double arg) => this(other(arg)); // * is compose
  DoubleToDoubleFunction applyOnN(double number) => (double arg) => this(arg); // function(number)
}

DoubleToDoubleFunction toZero = (double x) => 0.0;
DoubleToDoubleFunction identityDD = (double x) => x;

class FunctionMatrix2D<T extends DoubleToDoubleFunction> extends Matrix2D {
  FunctionMatrix2D(List<List<T>> from) : super(from);

  /// T should be either number or functional,
  @override
  get zeroOfT => toZero;
  /// Addition:   number to number it T is number, functional to functional if T is functional
  @override
  addTT(t1, t2) => t1.addT(t2);
  /// Multiplication: number by number it T is number, number by functional if T is functional
  @override
  multiplyNT(double number, t) => t.multiplyNT(number);
  /// Multiplication if T is number, composition if T is functional
  @override
  multiplyOrComposeTT(t1, t2) => t1.multiplyT(t2);
  /// Multiplication if T, N both numbers, call T(n) if T is a functional
  @override
  multiplyOrApplyTN(t, n) => t.applyOnN(n);

}


/* ORIGINAL KEEP :  without extension
class FunctionMatrix2D<T extends DoubleToDoubleFunction> extends Matrix2D {
  FunctionMatrix2D(List<List<T>> from)
      : _storage = List.from(from, growable: false) {
    _validate();
  }

  final List<List<T>> _storage;
  get numRows => _storage.length;
  get numCols => _storage.isNotEmpty ? _storage[0].length : 0;

  /// FunctionMatrix addition
  FunctionMatrix2D operator +(FunctionMatrix2D other) {
    if (numRows != other.numRows || numCols != other.numCols) {
      throw StateError('$runtimeType: Uneven length');
    }
    return FunctionMatrix2D(List.generate(
        numRows,
        (rowInd) => List.generate(numCols, (colInd) => _storage[rowInd][colInd] + other._storage[rowInd][colInd])
            .toList(growable: false)).toList(growable: false));
  }

  /// Multiply matrices
  FunctionMatrix2D operator *(FunctionMatrix2D other) {
    return _multiplyWith(other);
  }
  FunctionMatrix2D _multiplyWith(FunctionMatrix2D other) {
    throw UnimplementedError('todo-010 implement');
  }

  /// Multiplies each element of the matrix by a scalar (scales by a scalar).
  FunctionMatrix2D scaleBy(num scalar) {
    return FunctionMatrix2D(List.generate(
        numRows,
            (rowInd) => List.generate(numCols, (colInd) => scalar * _storage[rowInd][colInd])
            .toList(growable: false)).toList(growable: false));
  }

  Vector operator [](int rowIndex) => Vector(_storage[rowIndex]);

  Vector applyOn(Vector vector) {
    if (numCols != vector.length || numRows == 0) throw StateError('Incompatible length or matrix size 0');

    return Vector(List.generate(numRows, (rowIndex) => this[rowIndex].innerProduct(vector)));
  }

  /// Validate whether the [_storage] created in constructor
  /// has all rows the same length, a precondition for a valid matrix.
  ///
  /// Throws [StateError] if invalid.
  void _validate() {
    if (numRows > 1) {
      for (int rowInd = 0; rowInd < _storage.length; rowInd++) {
        if (rowInd > 0 && _storage[rowInd].length != _storage[rowInd - 1].length) {
          throw StateError('Matrix constructed from uneven rows.');
        }
      }
    }
    if (numRows != numCols) {
      throw StateError('Only square matrices supported ATM.');
    }
  }

}

 */
/*
// Not working illustration of a functional vector space.
// A functional vector space is defined as:
//   - F, a field
//   - V, a vector space over field F
//   - X, any set, a domain of functions from set FSet
//   - FSet, a set of vector-valued functions from X -> V, with the following operations:
//     - + : (FSet, FSet) -> FSet, in other words, (f, g) -> f + g
//       - for any f, g in FSet, any x in X
//           (f + g)(x) = f(x) + g(x) // operation + in V is valid
//     - * (or dot) : (F, FSet) -> FSet, in other words, (c, f) -> c * g
//       - for any f in FSet, any x in X, any c in F
//           (c * f)(x) = c * f(x) // operation * in V is valid
//
extension RealVectorSpace1D on double {}
extension RealField on double {}
extension RealFunctionDomain on double {}

class FunctionalVectorSpace {
  RealVectorSpace1D vectorSpace;
  RealField field;
  RealFunctionDomain functionDomain;
}
*/

