import 'dart:collection' as collection show ListBase;

class CustomList<E> extends collection.ListBase<E> {
  final List<E> delegate = [];
  CustomList();

  set length(int newLength) {
    delegate.length = newLength;
  }

  int get length => delegate.length;
  E operator [](int index) => delegate[index];
  void operator []=(int index, E value) {
    delegate[index] = value;
  }
}
