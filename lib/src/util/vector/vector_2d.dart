
/// Vector. Equivalent to 1 Dimensional matrix.
class Vector<T extends num> {
  Vector(List<T> from)
    : _storage = from;

  final List<T> _storage;
  get length => _storage.length;

  /// Vector addition
  Vector operator +(Vector other) {
    _validate(other);
    return Vector(List.generate(length, (index) => _storage[index] + other._storage[index]));
  }

  /// Point-wise product
  Vector operator *(Vector other) {
    _validate(other);
    return Vector(List.generate(length, (index) => _storage[index] * other._storage[index]));
  }

  T operator [](int index) => _storage[index];

  /// Inner product
  num innerProduct(Vector other) {
    _validate(other);
    return List.generate(length, (index) => _storage[index] * other._storage[index]).fold(0, (a,b) => a + b);
  }

  Vector scaleBy(num scale) {
    return Vector(List.generate(length, (index) => scale * this[index])); // this[index] == _storage[index]
  }

  void _validate(Vector<num> other) {
    if (length != other.length) throw StateError('$runtimeType: Uneven length, this=$length, other=${other.length}');
  }

  @override
  bool operator ==(Object other) {
    if (other is! Vector) return false;
    if (_storage.length != other._storage.length) return false;

    for (int i = 0; i < _storage.length; i++) {
      if (_storage[i] != other._storage[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => _storage.hashCode;

}