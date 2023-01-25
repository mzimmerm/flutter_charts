import 'dart:collection' as collection show ListBase;

class CustomList<E> extends collection.ListBase<E> {

  /// Makes this custom list growable on/off on construction.
  final bool _growable;

  /// Delegate to which we pass all concrete methods of the [CustomList] class.
  late final List<E> delegate;

  /// The single UNNAMED, and one of GENERATIVE constructors. 1 unnamed which is also generative always works.
  CustomList({required bool growable})
      : _growable = growable,
        super() {
    delegate = List.empty(growable: _growable);
  }

  // ListBase implements all read operations using only the
  // - `length` and
  // - `operator[]` and members.
  // It implements write operations using those and
  // - `add`,
  // - `length=` and
  // - `operator[]=`
  // Classes using this base classs  should implement those five operations.

  @override
  set length(int newLength) {
    delegate.length = newLength;
  }

  @override
  int get length => delegate.length;

  @override
  E operator [](int index) => delegate[index];

  @override
  void operator []=(int index, E value) {
    delegate[index] = value;
  }

  /// The [add] method must be overridden for lists that do NOT
  /// allow `null` as element.
  @override
  void add(E element) {
    delegate.add(element);
  }
}
