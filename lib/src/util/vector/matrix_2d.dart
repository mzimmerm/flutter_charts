import 'vector_2d.dart';
import '../util_dart.dart' show transposeRowsToColumns;

class Matrix2D<T, N extends double> {
  Matrix2D(List<List<T>> fromRows)
      : _storage = List.generate(
          fromRows.length,
          (rowIndex) => List<T>.from(fromRows[rowIndex]).toList(growable: false),
        ) {
    _validate();
    _storageByColumn = transposeRowsToColumns(_storage);
  }

  final List<List<T>> _storage;
  late final List<List<T>> _storageByColumn;

  int get numRows => _storage.length;
  int get numCols => _storage.isNotEmpty ? _storage[0].length : 0;

  // ********** Support for Function space ********
  //
  /// T should be either number or functional,
  get zeroOfT => throw UnimplementedError('implement in extensions'); // 0 as T;
  double get zeroOfN => 0.0;
  /// Addition:   number to number it T is number, functional to functional if T is functional. Result N or T
  addTT(t1, t2) => throw UnimplementedError('implement in extensions');
  /// Addition of numbers: number + number always. Result N.
  addNN(double number1, double number2) => number1 + number2;
  /// Multiplication: number by number it T is number, number by functional if T is functional. Result N or T.
  multiplyNT(double number, t) => throw UnimplementedError('implement in extensions');
  /// Multiplication if T is number, composition if T is functional. Result N or T.
  multiplyOrComposeTT(t1, t2) => throw UnimplementedError('implement in extensions');
  /// Multiplication if T, N both numbers, call T(n) if T is a functional. Result always N.
  double multiplyOrApplyTN(t, double n) => throw UnimplementedError('implement in extensions');

  bool equalsTT(T first, T second) => throw UnimplementedError('implement in extensions');

      /// Matrix addition
  Matrix2D operator +(covariant Matrix2D other) {
    if (numRows != other.numRows || numCols != other.numCols) {
      throw StateError('$runtimeType: Uneven length');
    }
    return Matrix2D(List.generate(
        numRows,
        (rowInd) => List.generate(numCols, (colInd) => addTT(_storage[rowInd][colInd], other._storage[rowInd][colInd]))
            .toList(growable: false)).toList(growable: false));
  }

  /// Multiply matrices - assumes num rows == num cols
  Matrix2D operator *(covariant Matrix2D other) {
    return _multiplyWith(other);
  }

  Matrix2D _multiplyWith(covariant Matrix2D other) {
    return Matrix2D(List.generate(
        numRows,
        (rowInd) => List.generate(numCols, (colInd) {
              T dotProductInRowColCurr = zeroOfT;
              for (int freeInd = 0; freeInd < numCols; freeInd++) {
                  dotProductInRowColCurr = addTT(
                    dotProductInRowColCurr,
                    multiplyOrComposeTT(
                      _storage[rowInd][freeInd],
                      other._storageByColumn[colInd][freeInd],
                    ),
                  );
              }
              return dotProductInRowColCurr;
            }).toList(growable: false)));
  } //  _storage[rowInd][colInd] * other._storage[rowInd][colInd]

  Vector applyOnVector(Vector vector) {
    return Vector(_multiplyOrApplyAsList(vector));
  }

  /// Returns a list of doubles, which result from point-wise Function applications on numbers
  /// or point-wise number multiplications.
  ///
  /// A Matrix applied on vector.
  List<double> _multiplyOrApplyAsList(Vector vector) {
    if (numCols != vector.length || numRows == 0) throw StateError('Incompatible length or matrix size 0');

    return List.generate(
        vector.length,
            (rowInd) {
          double dotProductInRowCol0Curr = zeroOfN;
          for (int thisColInd = 0; thisColInd < numCols; thisColInd++) {
            // for (int otherRowInd = 0; otherRowInd < vector._storage[otherRowInd].length; otherRowInd++) {
              dotProductInRowCol0Curr = addNN(
                dotProductInRowCol0Curr,
                multiplyOrApplyTN( // result is number
                  _storage[rowInd][thisColInd],
                  vector[thisColInd] as N, // as N required here
                ),
              );
            // }
          }
          return dotProductInRowCol0Curr;
        }).toList(growable: false);
  }

  /// Multiplies each element of the matrix by a scalar (scales by a scalar).
  Matrix2D scaleBy(double number) {
    return Matrix2D(List.generate(
        numRows,
            (rowInd) => List.generate(numCols, (colInd) => multiplyNT(number, _storage[rowInd][colInd]))
            .toList(growable: false)).toList(growable: false));
  }

  List<T> listAtRow(int rowIndex) => _storage[rowIndex];

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

  @override
  bool operator ==(Object other) {
    if (other is! Matrix2D) return false;
    if (numRows != other.numRows || numCols != other.numCols) return false;

    for (int rowIndex = 0; rowIndex < _storage.length; rowIndex++) {
      for (int colIndex = 0; colIndex < _storage[rowIndex].length; colIndex++) {
        if (!equalsTT(_storage[rowIndex][colIndex], other._storage[rowIndex][colIndex])) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  int get hashCode => _storage.hashCode;
  
}

class DoubleMatrix2D<T extends double> extends Matrix2D {
  DoubleMatrix2D(List<List<T>> from) : super(from);

  /// T should be either number or functional,
  @override
  get zeroOfT => 0.0;
  /// Addition:   number to number it T is number, functional to functional if T is functional
  @override
  addTT(t1, t2) => t1 + t2;
  /// Multiplication: number by number it T is number, number by functional if T is functional
  @override
  multiplyNT(double number, t) => number * t;
  /// Multiplication if T is number, composition if T is functional
  @override
  multiplyOrComposeTT(t1, t2) => t1 * t2;
  /// Multiplication if T, N both numbers, call T(n) if T is a functional
  @override
  multiplyOrApplyTN(t, double n) => t * n;

  @override
  bool equalsTT(first, second) => first == second;

}
