import 'dart:collection' as collection show ListBase;

class CustomList<E> extends collection.ListBase<E> {
  final _growable = false; // todo-00-last-added

  final List<E> delegate = List.empty(growable: true);

  /// todo-00-last : Ensure a single public unnamed constructor exists (would be generated anyway)
  /// todo-00-last : added the whole growable argument.
  CustomList({required bool growable});

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
