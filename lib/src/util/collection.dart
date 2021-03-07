import 'dart:collection' as collection show ListBase;

class CustomList<E> extends collection.ListBase<E> {
  final List<E> delegate = List.empty(growable: true);

  CustomList();

  // ListBase implements all read operations using only the
  // - `length` and
  // - `operator[]` and members.
  // It implements write operations using those and
  // - `add`,
  // - `length=` and
  // - `operator[]=`
  // Classes using this base classs  should implement those five operations.

  set length(int newLength) {
    delegate.length = newLength;
  }

  int get length => delegate.length;

  E operator [](int index) => delegate[index];

  void operator []=(int index, E value) {
    delegate[index] = value;
  }

  /// The [add] method must be overridden for lists that do NOT
  /// allow `null` as element.
  void add(E element) {
    delegate.add(element);
  }
}
