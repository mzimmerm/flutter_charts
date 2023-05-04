import 'vector_2d.dart';

class Matrix2D<T extends num> {
  Matrix2D(List<List<T>> from)
      : _storage = List.from(from, growable: false) {
    if (numRows > 1) {
      for (int rowInd = 0; rowInd < _storage.length; rowInd++) {
        if (rowInd > 0 && _storage[rowInd].length != _storage[rowInd - 1].length) {
          throw StateError('Matrix constructed from uneven rows.');
        }
      }
    }
  }

  final List<List<T>> _storage;
  get numRows => _storage.length;
  get numCols => _storage.isNotEmpty ? _storage[0].length : 0;

  /// Matrix addition
  Matrix2D operator +(Matrix2D other) {
    if (numRows != other.numRows || numCols != other.numCols) {
      throw StateError('$runtimeType: Uneven length');
    }
    return Matrix2D(List.generate(
        numRows,
        (rowInd) => List.generate(numCols, (colInd) => _storage[rowInd][colInd] + other._storage[rowInd][colInd])
            .toList(growable: false)).toList(growable: false));
  }

  /// Multiply matrices
  Matrix2D operator *(Matrix2D other) {
    return _multiplyWith(other);
  }
  Matrix2D _multiplyWith(Matrix2D other) {
    throw UnimplementedError('todo-010 implement');
  }

  Vector operator [](int rowIndex) => Vector(_storage[rowIndex]);

  Vector applyOn(Vector vector) {
    if (numCols != vector.length || numRows == 0) throw StateError('Incompatible length or matrix size 0');

    return Vector(List.generate(numRows, (rowIndex) => this[rowIndex].innerProduct(vector)));
  }

  Matrix2D scaleBy(num scale) {
    return Matrix2D(List.generate(
        numRows,
            (rowInd) => List.generate(numCols, (colInd) => scale * _storage[rowInd][colInd])
            .toList(growable: false)).toList(growable: false));
  }
}