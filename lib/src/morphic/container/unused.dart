/*
/// Mixin allows to create a double-linked list on a set of objects.
///
/// The set of object which became double-linked are defined by
/// member [doubleLinkedOwner] and calling [DoubleLinkedOwner.allElements].
///
/// It should be used on [E] which is also mixed in with [DoubleLinked<E>],
/// because then [E] is both [DoubleLinked] and [E], and can be mutually cast.
///
/// See [DoubleLinkedOwner] for a typical use.
@Deprecated('DoubleLinked is removed')
mixin DoubleLinked<E> {
  
  late final DoubleLinkedOwner<E> doubleLinkedOwner;

  /// Maintains linked list from previous child to next child.
  E? _next;

  /// Public getter reaches the [next] sibling child.
  E? get next => _next;
  
  bool _hasNext = false;

  bool get hasNext => _hasNext;

  /// Maintains linked list from previous child to next child.
  E? _previous;

  /// Public getter reaches the [next] sibling child.
  E? get previous => _previous;
  
  bool _hasPrevious = false;
  
  bool get hasPrevious => _hasPrevious;

  /// Set `previous.next = current`, and return [current] as the new previous
  E createLink(E? previous, E current) {
    if (previous != null) {
      (previous as DoubleLinked)._next = current;
      previous._hasNext = true;
      (current as DoubleLinked)._previous = previous;
      current._hasPrevious = true;
    }
    return current;
  }

  /// Establishes previous/next relationship between all elements defined by [allElements].
  ///
  /// Calling this method on any [DoubleLinked] element causes the whole set of  [DoubleLinked] elements to be linked
  /// for previous/next operation.
  void linkAll() {
    E? previous;
    for (E element in doubleLinkedOwner.allElements()) {
      previous = createLink(previous, element);
    }
  }

  /// Assuming previous/next relationship is already done between [allElements],
  /// links the first [addedToLinked] to the end of [allElements] and establishes link
  /// between all [addedToLinked]. The end effect is that all [allElements] and [addedToLinked]
  /// are linked together.
  void linkAllWith(Iterable<E> addedToLinked) {
    E? previous;
    if (doubleLinkedOwner.allElements().isNotEmpty) {
      previous = doubleLinkedOwner.allElements().last;
    }
    for (var child in addedToLinked) {
      previous = createLink(previous, child);
    }
  }

  /// From this [DoubleLinked], iterates all owned [DoubleLinked] elements starting with the first,
  /// and applies the passed function on the passed object.
  ///
  /// Delegated to the implementation of this  [DoubleLinked] object's [doubleLinkedOwner],
  /// see [DoubleLinkedOwner.applyOnAllElements].
  void applyOnAllElements(Function(E, dynamic passedObject) useElementWith, dynamic object) {
    doubleLinkedOwner.applyOnAllElements(useElementWith, object);
  }

  /// From this [DoubleLinked], iterates all owned [DoubleLinked] elements starting with the last,
  /// and applies the passed function on the passed object.
  ///
  /// Delegated to the implementation of this  [DoubleLinked] object's [doubleLinkedOwner],
  /// see [DoubleLinkedOwner.applyOnAllElementsReversed].
  void applyOnAllElementsReversed(Function(E, dynamic passedObject) useElementWith, dynamic object) {
    doubleLinkedOwner.applyOnAllElements(useElementWith, object);
  }
}

/// Owner of [DoubleLinked] elements.
///
/// Its existence is necessary for any [DoubleLinked] set of objects to define the set to be linked [allElements]
/// as well as to be moved along later by finding one of the [DoubleLinked] objects, for example
/// by invoking [allElements.first].
///
/// Client using a set of [DoubleLinked] objects need to hold on to [DoubleLinkedOwner] instance to
/// be able to make use of the set of  [DoubleLinked] objects by two lifecycle actions:
///   1. First client needs to define the set of [DoubleLinked] that should be linked using [DoubleLinked.linkAll].
///      This set is defined by [DoubleLinkedOwner.allElements].
///   2. Next, to apply some function on the [DoubleLinked] objects,
///      start walking through the set of [DoubleLinked] objects, client needs to
///      access one object from the set of [DoubleLinked] objects.
///      This access can be done by invoking [DoubleLinkedOwner.firstLinked].
///   2b)  Alternatively, and better,  to apply some function on the [DoubleLinked] objects,
///        client would invoke
///        ```dart
///          doubleLinkedOwner.applyOnAllElements(useElementWith, object);
///        ```
///
/// It's [hasLinkedElements] method must be called before the [firstLinked].
///
/// Assuming [DoubleLinked.linkAll] has been called on the first  nce [hasLinkedElements] returns true,
///
/// A typical manual use:
/// ```dart
///   if (doubleLinkedOwner.hasLinkedElements) {
///     E element = doubleLinkedOwner.firstLinked();
///     while (true) {
///        use(element);
///        if (!element.hasNext) {
///          break;
///        }
///        element = element.next;
///   }
/// ```
/// OR
/// ```dart
///   if (doubleLinkedOwner.hasLinkedElements) {
///     for (E element = doubleLinkedOwner.firstLinked(); ; element = element.next) {
///        use(element);
///        if (!element.hasNext()) {
///          break;
///        }
///     }
/// ```
///
/// Prefer to use the 'all in one' form [applyOnAllElements] or [applyOnAllElementsReversed]
/// which iterates and applies:
/// ```dart
///     doubleLinkedOwner.applyOnAllElements(useElementWith, object);
/// ```
@Deprecated('DoubleLinkedOwner is removed')
mixin DoubleLinkedOwner<E> {

  /// Abstract method defines the elements accessed (and owned) by this [DoubleLinkedOwner].
  ///
  /// This method must return iterable of all [DoubleLinked] instances that should be linked
  /// to enable moving back and forth.
  Iterable<E> allElements();

  bool get hasLinkedElements => allElements().isNotEmpty;

  bool get hasNoLinkedElements => allElements().isEmpty;

  E firstLinked() {
    if (hasNoLinkedElements) {
      throw StateError('$runtimeType instance $this has no points. Cannot ask for firstLinked().');
    }
    return allElements().first;
  }

  E lastLinked() {
    if (hasNoLinkedElements) {
      throw StateError('$runtimeType instance $this has no points. Cannot ask for lastLinked().');
    }
    return allElements().last;
  }
  /// Iterates all owned [DoubleLinked] elements starting with the first,
  /// and invokes the passed function [useElementWith] with the current element as first parameter,
  /// and the passed [object] as second parameter.
  ///
  /// Motivation: This method forces the function [useElementWith] to 'visit'
  ///             each element of [DoubleLinked] with an additional [object]
  ///             which can serve as a collector of results of each 'visit'.
  ///
  void applyOnAllElements(Function(E, dynamic passedObject) useElementWith, dynamic object) {

    if (hasLinkedElements) {
      for (E element = firstLinked(); ; element = element.next) {
        // e.g. object is pointContainerList,
        //      useElementWith is Function with body: {pointContainerList.add(element.generateViewChildrenEtc())};
        useElementWith(element, object);
        if (!(element as DoubleLinked).hasNext) {
          break;
        }
      }
    }
  }

  /// Behaves as [applyOnAllElements], except it starts on the last element of the owned [DoubleLinked].
  void applyOnAllElementsReversed(Function(E, dynamic passedObject) useElementWith, dynamic object) {

    if (hasLinkedElements) {
      for (E element = lastLinked(); ; element = element.previous) {
        useElementWith(element, object);
        if (!(element as DoubleLinked).hasPrevious) {
          break;
        }
      }
    }
  }
}
*/
