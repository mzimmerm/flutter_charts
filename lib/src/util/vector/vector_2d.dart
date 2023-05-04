
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

  /// Inner product
  num innerProduct(Vector other) {
    _validate(other);
    return List.generate(length, (index) => _storage[index] * other._storage[index]).fold(0, (a,b) => a + b);
  }

  Vector scaleBy(num scale) {
    return Vector(List.generate(length, (index) => scale * _storage[index]));
  }

  void _validate(Vector<num> other) {
    if (length != other.length) throw StateError('$runtimeType: Uneven length, this=$length, other=${other.length}');
  }
}