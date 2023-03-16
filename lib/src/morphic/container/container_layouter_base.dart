import 'dart:ui' as ui show Size, Offset, Rect, Canvas, Paint;
import 'dart:math' as math show Random, min, max;
import 'package:flutter/material.dart' as material show Colors;
import 'package:flutter/services.dart';

// this level or equivalent
import 'container_edge_padding.dart' show EdgePadding;
import 'layouter_one_dimensional.dart'
    show Align, Packing, LengthsPositionerProperties,
    LayedoutLengthsPositioner, PositionedLineSegments, ConstraintsDistribution;
import 'container_alignment.dart' show Alignment, AlignmentTransform;
import 'constraints.dart' show BoundingBoxesBase, BoxContainerConstraints;
import '../../util/extensions_flutter.dart' show SizeExtension, RectExtension;
import '../../util/util_dart.dart' as util_dart
    show LineSegment, Interval, ToPixelsExtrapolation1D,
    transposeRowsToColumns, assertDoubleResultsSame;
import '../../util/util_flutter.dart' as util_flutter
    show boundingRectOfRects, assertSizeResultsSame;
import '../../util/collection.dart' as custom_collection
    show CustomList;
import '../../util/extensions_dart.dart';
import 'container_key.dart'
    show ContainerKey, Keyed, UniqueKeyedObjectsManager;

abstract class BoxContainerHierarchy extends Object with UniqueKeyedObjectsManager, DoubleLinked<BoxContainer>, DoubleLinkedOwner<BoxContainer> {

  /// Children that should define a key, for the purpose of checking uniqueness of key between them.
  ///
  /// In this default implementation, all children must define a key. Unlikely to be changed by derived classes.
  ///
  /// Implements the sole abstract method of [UniqueKeyedObjectsManager].
  @override
  List<Keyed> get keyedMembers => _children;

  /* KEEP
  /// Remove ability to create instance on extensions, encouraging use of [BoxContainerHierarchy]
  /// as mixin only. BUT IT IS NOT CLEAR HOW TO DO THIS AS  BoxContainer extends BoxContainerHierarchy,
  /// to change BoxContainerHierarchy to mixin, more work.
  BoxContainerHierarchy._internal();
  */

  /// The parent of this [BoxContainer], initialized to null here, set to in one of 2 places:
  ///   1. In the [BoxContainer] constructor, if [__children] are non-null,
  ///      parent is set on all children as `child.parent = this`.
  ///   2. In [BoxContainer.addChildren], [_parent] is set on all passed children.
  BoxContainer? _parent; // null. will be set to non-null when addChild(this) is called on this' parent
  BoxContainer? get parent => _parent; // todo-01 - only one use. See if needed long term.

  /// Manages children of this [BoxContainer].
  ///
  /// All children are a siblings linked list.
  /// The next sibling can be accessed by invoking [next].
  final List<BoxContainer> __children = [];

  /// Get children list and protect with copy
  List<BoxContainer> get _children => List.from(__children);

  void _ensureKeySet(BoxContainer thisContainer, ContainerKey? key) {
    if (key != null) {
      thisContainer.key = key;
    }  else {
      // A hacky thing may fail uniqueness among siblings on rare occasions.
      // This is temporary until we require key non-nullable.
      thisContainer.key = ContainerKey(math.Random().nextInt(10000000).toString());
    }
  }

  void _makeSelfParentOf(BoxContainerHierarchy thisContainer, List<BoxContainer> parentedChildren) {
    for (var child in parentedChildren) {
      child._parent = thisContainer as BoxContainer;
    }
  }

  /// Appends all children passed in [addedChildren] to existing [_children],
  /// changes all [addedChildren] member [_parent] to self, and ensures unique
  /// keys among all [_children].
  /// todo-03 : can/should we move this method and all children manipulation to [BoxContainerHierarchy]?
  void addChildren(List<BoxContainer> addedChildren) {
    // Establish a 'nextSibling' linked list from __children to addedChildren, before [addedChildren]
    // are added to [__children];
    linkAllWith(addedChildren);
    __children.addAll(addedChildren);
    _makeSelfParentOf(this, addedChildren);
    ensureKeyedMembersHaveUniqueKeys();
  }


  void replaceChildrenWith(List<BoxContainer> newChildren) {
    // Establish a 'nextSibling' linked list from __children to addedChildren, before [addedChildren]
    // are added to [__children];
    __children.clear();
    addChildren(newChildren);
  }

  /// Allows [BoxContainer]'s [_children] to be created and set (or replaced) late (after parent creation)
  /// while the parent [layout] is descended into it's children [layout]s.
  ///
  /// Note: "Normally", the [_children] should created *early* in the [BoxContainer] constructor.
  ///
  /// Important note on motivation for this method's existence:
  ///   - When constructing most UIs, when creating a parent [BoxContainer], the UI creator
  ///     knows there is a fixed list of children; such fixed list can be created in the parent constructor,
  ///     by adding children constructors inside the list in the `children: [..]` section. It is a judgment
  ///     of the creator which layouter (if any!) the children will be wrapped in. It could be:
  ///     - Using a rolling layouter such as Row, if the children fit on one line.
  ///     - Using a wrapping layouter, such as WrapOnEnd if the children may not fit on one line
  ///     - Using a horizontal scrollbar
  ///     - or another approach.
  ///   - Another situation is that, the UI creator knows there will be a list of children, but does not know how many,
  ///     until runtime.
  ///     - In this situation, it the UI creator intents for all children to be shown, they solution is, one of the above.
  ///     - However, in charting:
  ///       - Using a rolling layouter may cause labels to overlap or not fit
  ///       - Using a wrapping layouter to continue chart on another line is not reasonably possible,
  ///       - Using a horizontal scrollbar for the chart is often not desired,
  ///     - In charting, a reasonable approach is to skip some labels. However, it is not known
  ///       util runtime, how much space will be given to the chart, or how many labels would fit the width.
  ///     - *The intended role, and reason of existence, of this method, is to build, or rebuild, the children
  ///        at runtime during the [layout] process, when both the constraints left for the chart, as well
  ///        as the number of children (labels) is known*
  ///
  /// Implementations should use this method as follows:
  ///   - Implementations can assume that [BoxLayouter.constraints] are set,
  ///     likely by a hierarchy-parent during layout.
  ///   - Implementations can assume this method is called in parent's [layout].
  ///   - Implementations should add code that creates children and adds them to self.
  ///     The number of children or some of their properties are assumed to depend
  ///     on results of previously layed out siblings in parent's [layout] - otherwise,
  ///     this [BoxContainer] would not need to mixin this [BuilderOfChildrenDuringParentLayout],
  ///     and build it's children in it's [BoxContainer] constructor.
  ///
  /// Important note - lifecycle:
  ///   For instances of [BoxContainer] mixed in with this [BuilderOfChildrenDuringParentLayout], \
  ///   the sequence of method invocations of such object should be as follows
  ///   ``` dart
  ///     1.  instance.applyParentConstraints(this, instanceParentConstraints);
  ///     2.  instance.buildAndReplaceChildren(); // or a concrete LayoutContext todo-00-doc documentation is not right
  ///     3.  instance.layout();
  ///     4.  instance.applyParentOffset(this, instanceParentOffset);
  ///   ```
  ///   This was chosen because there are legitimate reasons for the [buildAndReplaceChildren]
  ///   to need the instance's [constraints].
  ///
  /// An example: As an example, we have a chart with 'root container' which contains two hierarchy-sibling areas:
  ///   - the 'x axis container', which shows data labels that must not wrap, but
  ///     there may be too many labels to fit the width.
  ///   - The 'data container' which shows, among others, a dotted vertical line
  ///     in the center of each label.
  ///
  ///   - An acceptable solution to the problem where 'x axis container' labels that must not wrap, but
  ///     there may be too many labels to fit the width, is for the chart to skip every N-th label.
  ///     The N only becomes known during the 'x axis container' [layout],
  ///     called from the 'root container' [layout].  But this situation creates a
  ///     dependency for drawing dotted lines above the labels. As the dotted lines are part
  ///     of 'data container', a sibling container to the 'x axis container',
  ///     we can mix this [BuilderOfChildrenDuringParentLayout] to the 'data container',
  ///     and call it's [buildAndReplaceChildren] during the 'root container' [layout].
  ///
  ///   - This approach requires for the 'source' sibling 'x axis container' to *know* which sibling(s) 'sinks'
  ///     depend on the 'source' [layout], and the other way around.  Also, the 'source' and the 'sink' must
  ///     agree on the object to exchange the 'sink' create information - this is the object
  ///     returned from [findSourceContainersReturnLayoutResultsToBuildSelf]
  ///
  ///   - In such situation, a hierarchy-parent during the [layout] would first call
  ///     this mixin's siblings' [layout], establishing the remaining space
  ///     ([constraints]) left over for this [BuilderOfChildrenDuringParentLayout] container, then
  ///     create an 'appropriate', 'non-overlapping' children of itself.

  void buildAndReplaceChildren();

  /// Default implementation of [buildAndReplaceChildren] is a no-op,
  /// does not modify this node's children, does not modify container's internal state
  ///
  /// Default should be called from [buildAndReplaceChildren] by any container
  /// that creates it's whole child hierarchy in its constructor.
  ///
  /// Containers that wish to only set *immediate children* in their constructor
  /// (while intending that the hierarchy will be built deeper down),
  /// should not call this default method in [buildAndReplaceChildren], but use
  /// [buildAndReplaceChildren] to do the intended deeper hierarchy building.
  ///
  void buildAndReplaceChildrenDefault() {
    // As a test, replace children with self. Remove later when this proves to work
    // replaceChildrenWith(_children);
  }

  bool get isRoot => _parent == null;

  bool get isLeaf => __children.isEmpty;

  BoxContainer? _root;

  /// Obtain hierarchy-root of this [BoxContainerHierarchy] node, and cache the hierarchy-root
  /// as [_root] along the path.
  BoxContainer get root {
    if (_parent == null) {
      return this as BoxContainer;
    }
    if (_root != null) {
      // root was cached in _root
      return _root!;
    }

    if (_parent == null) {
      // This hierarchy-node is root
      // We cannot set `_root = this` as 'this' is ContainerHierarchy, so find this reference
      //   among children's parent, there must be at least one child of this node;
      _root = _children[0]._parent;
      return _root!;
    }

    // My _parent, set as rootCandidate
    BoxContainer rootCandidate = _parent!;

    while (rootCandidate._parent != null) {
      // My _parent == rootCandidate.
      // Optimization: If previously cached as _root on my _parent, use _root as my root as well.
      if (rootCandidate._root != null) {
        _root = rootCandidate._root;
        return _root!;
      }
      rootCandidate = rootCandidate._parent!;
    }
    // We iterated all the way to root, and no node had a cached _root.
    // Cache rootCandidate as _root, and return the cached _root.
    // But before, propagate the cached _root to all parents for next time use.
    print(' ### get root: No cached _root found all the way to actual hierarchy-root.');
    __propagateRootCacheUp(rootCandidate);
    _root = rootCandidate;
    return _root!;
  }

  /// Assumed to be called on this node when looking for a hierarchy-root,
  /// no cached root [_root] was found all the way to the top.
  ///
  /// In this situation, to speed up future calls to [root], we cache the
  /// root as [_root] on all nodes from this node all the way to actual hierarchy-root.
  __propagateRootCacheUp(BoxContainer cachedRoot) {
    // Walk back up from this node, using _parent to indicate hierarchy-root
    BoxContainer rootCandidate = _parent!;
    while (rootCandidate._parent != null) {
      if (rootCandidate._root != null) {
        throw StateError('__propagateRootCacheUp: Unexpected already cached root ${rootCandidate._root} '
            'during caching on rootCandidate=$rootCandidate ');
      }
      rootCandidate._root = cachedRoot;
      rootCandidate = rootCandidate._parent!;
    }
  }

  /// Implementation of [DoubleLinkedOwner.allElements]
  @override
  Iterable<BoxContainer> allElements() => __children;
}

/// Mixin allows to create a double-linked list on a set of objects.
///
/// The set of object which became double-linked are defined by
/// member [doubleLinkedOwner] and calling [DoubleLinkedOwner.allElements].
///
/// It should be used on [E] which is also mixed in with [DoubleLinked<E>],
/// because then [E] is both [DoubleLinked] and [E], and can be mutually cast.
///
/// See [DoubleLinkedOwner] for a typical use.
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

/// If set on a [BoxLayouter] instance, when looking at the instance as one of siblings (of a parent),
/// defines how constraints should be distributed among it's siblings.
///
/// The parent of such instance gathers all the children's [ConstraintsWeight]s, and distribute constraints
/// among it's children (including the said instance) proportionally to their [ConstraintsWeight]s
/// 
/// Definition: Weights with value of 0 [defaultWeight] or negative values are all classified as *undefined weight*
///             [BoxLayouter] with [BoxLayouter.constraintsWeight] set to [defaultWeight] or negative value
///             is also classified as *undefined weight* layouter.
///
/// Important notes regarding constraints distribution:
///   - On [BoxLayouter] parent on which, among it's children at least one child has *UNDEFINED weight*,
///     parent's layout algorithm should pass to all children it's full constraint.
///   - On [BoxLayouter] parent on which, all children have  *DEFINED weights*,
///     parent's layout algorithm should distribute constraints among it's children
///     proportionally to their [ConstraintsWeight]s.
///
class ConstraintsWeight {

  const ConstraintsWeight({
    this.weight = 0,
  });

  final int weight;

  static const ConstraintsWeight defaultWeight = ConstraintsWeight(weight: 0);

  @override
  bool operator ==(Object other) {
    return other is ConstraintsWeight && weight == other.weight;
  }

  @override
  int get hashCode => Object.hash(this, weight);


  @override
  String toString() {
    return 'weight = weight.toString()';
  }
}

class ConstraintsWeights {

  final List<ConstraintsWeight> constraintsWeightList;

  ConstraintsWeights.from({
     required List<ConstraintsWeight> constraintsWeightList,
  }) : constraintsWeightList = List.from(constraintsWeightList, growable: false);

  bool get allDefined => constraintsWeightList.where((element) => element.weight <= 0).isEmpty;

  List<int> get intWeightList {
    if (!allDefined) {
      throw StateError('Some weights are not defined positive, constraintsWeights=$constraintsWeightList');
    }
    return constraintsWeightList.map((element) => element.weight).toList();
  }

  /// Sum of weights in [constraintsWeightList].
  ///
  /// Before invoking, should invoke [allDefined] to check if all siblings have a defined
  /// (non 0, non negative, non-default) weight.
  int get sum {
    if (!allDefined) {
      throw StateError('Some weights are not defined positive, constraintsWeights=$constraintsWeightList');
    }
    return constraintsWeightList.fold(0, (previousValue, element) => previousValue + element.weight);
  }
}

/// [LayoutableBox] is an abstraction of behavior of a box which was sized and positioned
/// on a 2D plane.
///
/// It is an interface-only common to [BoxLayouter] and [BoxContainer].
///
/// Sizing is obtained by the getter [layoutSize].
/// Positioning is obtained by the getter [offset].
///
/// Implementations will likely add setters to the above described getters.
///
/// Used in methods that operate on [BoxLayouter] or [BoxContainer], but only require
/// a narrower interface which exposes query for [layoutSize] and [offset],
/// and applying several properties by parent. The apply methods in their names
/// describe those properties should only be invoked
/// in context of [BoxLayouter] or [BoxContainer] hierarchy by a parent invoker.
///
/// Such use hides the extended role of [BoxLayouter] or [BoxContainer]
/// hierarchy, (getting children, parents, etc),
/// and points out only what is needed to position a list of [LayoutableBox]s
/// by another [LayoutableBox].
abstract class LayoutableBox {
  /// Size after the box has been layed out.
  ///
  /// Each [BoxContainer] node method [layout] must be able to set this [layoutSize]
  ///    on itself after all children were layed out.
  ///
  /// Important note: [layoutSize] is not set by parent, but it is accessed (get) by parent.
  ///                So maybe setter could be here, getter also here
  ui.Size get layoutSize;

  // todo-013 : should this be private as changes are performed by the 'apply' method?
  ui.Offset get offset;

  /// Moves this [LayoutableBox] by [offset], ensuring the invocation is by [_parent] in the [BoxContainerHierarchy].
  ///
  /// Lifecycle: Should be invoked by [_parent] during [layout] after
  ///            sizes and positions of all this [LayoutableBox]'s siblings are calculated.
  ///
  /// Override if this [LayoutableBox]'s [_parent] offset needs to be applied also to [_children] of
  /// this [LayoutableBox].
  ///
  /// Important override notes and rules for [applyParentOffset] on extensions:
  ///  1) Generally, IF OVERRIDDEN, `super.applyParentOffset` SHOULD BE CALLED FIRST.
  ///  2) Generally,
  ///    - Non-leafs do NOT need to override [applyParentOffset], as calling this method
  ///      (which delegates offset to children) is an integral part of the layout process (implemented in [layout]).
  ///    - Leafs WHICH carry additional non-child members to paint (e.g. rectangle), LIKELY NEED TO OVERRIDE as follows:
  ///      - call `super.applyParentOffset` first, to set overall offset in parent.
  ///      - apply offset on the non-child members that will be painted on the offset.
  ///      The override is also needed to ensure the layed out rectangles outer rectangle assert to
  ///      envelope to children, will succeed.
  ///      Example [AxisCornerContainer]
  ///      ```dart
  ///          @override
  ///          void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
  ///            // This was a core issue of layout rectangles and child rectangles not matching.
  ///            super.applyParentOffset(caller, offset);
  ///            _rect = _rect.shift(offset);
  ///          }
  ///      ```
  ///  3) Generally, [BoxContainer]s using manual layout, SHOULD override.
  ///     Those would generally (always?) be leafs, and they would do the following:
  ///       - Override [layout] (no super call), do manual layout calculations,
  ///         likely store the result as member (see [LabelContainer._tiltedLabelEnvelope],
  ///         and set [layoutSize] at the end, so parent can pick it up
  ///       - Override [applyParentOffset] as follows:
  ///          - likely call super [applyParentOffset] first, to set overall offset in parent.
  ///          - offset the additionally maintained children by the same offset as the [BoxContainerHierarchy._children].
  ///          - potentially re-offset the position as a result of the manual layout
  ///            (see [LabelContainer.offsetOfPotentiallyRotatedLabel]) and store result as member
  ///        - Override [paint] by painting on the calculated (parent also applied) offset,
  ///           (see [LabelContainer.paint].

  ///
  void applyParentOffset(LayoutableBox caller, ui.Offset offset);

  /// todo-doc-01 fully, also write : Important override notes and rules for [applyParentOrderedSkip] on extensions:
  /// Expresses that parent ordered this [BoxLayouter] instance to be skipped during
  /// the [layout] and [paint] processing.
  ///
  void applyParentOrderedSkip(LayoutableBox caller, bool orderedSkip);

  /// Set constraints from parent of this [LayoutableBox].
  // todo-00-doc : document fully, including rules for overriding
  void applyParentConstraints(LayoutableBox caller, BoxContainerConstraints constraints);

  ///
  /// Assumptions:
  ///   1. Before calling this method, [constraints] must be set at least on the root of the [BoxContainerHierarchy].
  ///
  /// Important override notes and rules for [layout] on extensions:
  ///   1: Everywhere in docs, by 'layouter specific processing', we mean there is code
  ///      which auto-layouts all known layouters [Row], [Column] etc, using their set values of [Packing] and [Align].
  ///
  ///   2: General rules for [layout] on extensions
  ///
  ///      1) Generally, leafs do not need to override [layout],
  ///         as their only role in the layout process is to set their [layoutSize], which parents can later get.
  ///         The standard place for leafs to set their [layoutSize] is [layout_Post_Leaf_SetSize_FromInternals]
  ///         which MUST be overridden on classes which do NOT override [layout].
  ///         Alternatively, it is sufficient for leafs to override [layout] and only set [layoutSize] there.
  ///      2) Non-leafs do often need to override some methods invoked from [layout],
  ///         or the whole [layout]. Some details on Non-Leafs
  ///         - Non-positioning Non-leafs: Generally only need to override [layout_Post_NotLeaf_PositionChildren] to return .
  ///           If mostly do not need to override [layout] at all,
  ///           unless they wish to distribute constraints to children differently from the default,
  ///           passing the full constraint to all children.
  ///           The empty
  ///         as this method is integral part of autolayout (as is [applyParentOffset]).
  ///      2) Exception would be [BoxLayouter]s that want to use manual or semi-manual
  ///         layout process.
  ///           - On Leaf: override [layout] (no super call), do manual layout calculations,
  ///             likely store the result as member (see [LabelContainer._tiltedLabelEnvelope],
  ///             and set [layoutSize] at the end. This is already described in [BoxLayouter.applyParentOffset]
  ///           - Potentially - this would be a hack PARENT of the leaf also may need to override[layout], where it :
  ///             - Perform layout logic to set some size-related value on it's child. We do not have example,
  ///               as we moved this stuff from [LabelContainer] parent [LegendItemContainer] to [LabelContainer] .
  ///               See around [_layoutLogicToSetMemberMaxSizeForTextLayout]
  ///
  /// Misc less important notes:
  ///   1. Can we make layoutSize result of layout (INSTEAD OF VOID)  and not store on layout?
  ///     - NO, because ??? todo-013 : layoutSize member: Make still available as late final on BoxLayouter,
  ///           set it after return in case it is needed later. Always set just after return from layout.
  void layout();
}


// ---------- Width and Height sizers and layouters vvvvvv -------------------------------------------------------------

/// Holds on to width and height sizers used somewhere in the container-hierarchy.
///
/// Intended to be placed on root [BoxContainer.sandbox] using key [keyInSandbox].
class RootSandboxSizers {
  // Map with keys to objects which implement [FromConstraintsWidthSizer].
  // Intent: only have one key 'width' and one key 'height', The idea is that any chart areas should only have
  // one width and one size - as if there was a table with many columns, but there is one column which cells must have the same width.
  //                      and many rows, but there is exactly one row where height matters. They intersect on the DataContainer.
  WidthSizerLayouter? __widthSizer;
  HeightSizerLayouter? __heightSizer;

  /// Key of this object when used in [BoxContainer.sandbox].
  static const String keyInSandbox = 'sizers';

  /// If width sizer exists on this object, check if the passed has same width, if not exception
  ///    else add the passed sizer
  checkOrSetSizer(FromConstraintsSizerMixin firstOrLaterSizer) {

    FromConstraintsSizerMixin? currentSizer;
    
    if (firstOrLaterSizer is WidthSizerLayouter) {
      currentSizer = __widthSizer;
    } else if (firstOrLaterSizer is HeightSizerLayouter) {
      currentSizer = __heightSizer;
    } else {
      throw StateError('Unexpected type passed, ${firstOrLaterSizer.runtimeType}');
    }

    if (currentSizer != null) {
      util_dart.assertDoubleResultsSame(
        currentSizer.length,
        firstOrLaterSizer.length,
        'Passed width sizer $firstOrLaterSizer differs from width sizer on root sandbox. '
        'Likely reason: Multiple [WidthSizerLayouter]s were placed in the container hierarchy, '
        'but the position is in places where the widths of the constraints passed to them is not the same.'
        'It may equivalently apply to multiple [HeightSizerLayouter]s.',
      );
      return;
    }
    if (firstOrLaterSizer is WidthSizerLayouter) {
      __widthSizer = firstOrLaterSizer;
    } else if (firstOrLaterSizer is HeightSizerLayouter) {
      __heightSizer = firstOrLaterSizer;
    } else {
      throw StateError('Unexpected type passed, ${firstOrLaterSizer.runtimeType}');
    }
  }

  /// Returns width sizer if exists, otherwise exception.
  WidthSizerLayouter get widthSizerEnsured {
    if (__widthSizer == null) {
      throw StateError('No width sizer was placed on the sandbox');
    }
    return __widthSizer!;
  }

  /// Returns height sizer if exists, otherwise exception.
  HeightSizerLayouter get heightSizerEnsured {
    if (__heightSizer == null) {
      throw StateError('No height sizer was placed on the sandbox');
    }
    return __heightSizer!;
  }
}

/// On behalf of far-away children than implement [FromConstraintsWidthSizerChild]
///   provides ability to set [lenght] which represents width on [FromConstraintsWidthSizer]
///   or height on [FromConstraintsHeightSizer].
///
/// The [length] is assumed to be in units pixel -
/// this is the width or height in pixels, to which the far-away children
/// will linearly extrapolate (lextr) their width or height.
mixin FromConstraintsSizerMixin on BoxContainer {

  late final double length;

  /// Finds hierarchy-root of this [BoxContainer], ensures both [sandbox] 
  /// and object [RootSandboxSizers] on key [sandboxSizersKey] exist, then check or set the passed
  /// [FromConstraintsSizerMixin] onto the [RootSandboxSizers] object.
  ///
  /// Should be called in applyParentConstraints.
  void findOrSetRootSandboxSizersThenCheckOrSetThisSizer() {

    root.sandbox ??= {};

    RootSandboxSizers sizersInSandbox = RootSandboxSizers();
    if (root.sandbox!.containsKey(RootSandboxSizers.keyInSandbox)) {
      sizersInSandbox = root.sandbox![RootSandboxSizers.keyInSandbox];
    } else {
      root.sandbox![RootSandboxSizers.keyInSandbox] = sizersInSandbox;
    }
    sizersInSandbox.checkOrSetSizer(this);
  }

}

/// Marker class, marking ability to [findOrSetRootSandboxSizersThenCheckOrSetThisSizer].
///
/// Consider removing from class hierarchy, OR moving portion of methods from [WidthSizerLayouter]
/// and [HeightSizerLayouter] to it.
abstract class FromConstraintsSizerLayouter extends NonPositioningBoxLayouter with FromConstraintsSizerMixin {

  /// The required generative constructor
  FromConstraintsSizerLayouter({
    List<BoxContainer>? children,
  }) : super(
    children: children,
  );

  /// Helper for [layoutSize], calculates and returns [layoutSize] which is
  /// increased, in the Sizer direction, to the full available [constraints],
  /// and keeps the super layoutSize in the cross direction
  ui.Size layoutSizeIncreasedToLength({required bool isWidthMain}) {
    // In the main direction (e.g. width), must increase layoutSize calculated by super
    // to the constraints size from this Sizer's [length].
    // If the [super.layoutSize] does not fit into this Sizer's [length], display a warning,
    // AND use the bigger non-fitting [super.layoutSize].
    // AFTER, IN [__layout_Post_AssertSizeInsideConstraints] the caller should warn or throw exception.
    ui.Size superLayoutSize = super.layoutSize;
    if (isWidthMain) {
      if (super.layoutSize.width <= length) {
        return ui.Size(length, superLayoutSize.height);
      }
    } else {
      // Height is the direction
      if (super.layoutSize.height <= length) {
        return ui.Size(superLayoutSize.width, length);
      }
    }
    print('$runtimeType: layoutSize calculated is $superLayoutSize exceeds, in width, the constraint width=$length');
    return super.layoutSize;
  }

  /// Ensures the sizer logic around width and height constraints is applied, then invokes super
  /// which stores the passed constraints.
  /// The sizer logic is applied by invoking [findOrSetRootSandboxSizersThenCheckOrSetThisSizer].
  @override
  void applyParentConstraints(LayoutableBox caller, BoxContainerConstraints constraints) {
    // length = constraints.width or height called in extension
    findOrSetRootSandboxSizersThenCheckOrSetThisSizer();
    super.applyParentConstraints(caller, constraints);
  }

}

class WidthSizerLayouter extends FromConstraintsSizerLayouter {

  /// The required generative constructor
  WidthSizerLayouter({
    List<BoxContainer>? children,
  }) : super(
    children: children,
  );

  /// Sets [length] from the passed [BoxContainerConstraints.width], then calls super
  /// which ensures the sizer logic is applied.
  @override
  void applyParentConstraints(LayoutableBox caller, BoxContainerConstraints constraints) {
    length = constraints.width;
    super.applyParentConstraints(caller, constraints); // on FromConstraintsSizerLayouter
  }

  @override
  Size get layoutSize {
    return layoutSizeIncreasedToLength(isWidthMain: true);
  }
}

class HeightSizerLayouter extends FromConstraintsSizerLayouter {

  /// The required generative constructor
  HeightSizerLayouter({
    List<BoxContainer>? children,
  }) : super(
    children: children,
  );

  /// Ensures the sizer logic around width and height constraints is applied, then invokes super
  /// which stores the passed constraints.
  @override
  void applyParentConstraints(LayoutableBox caller, BoxContainerConstraints constraints) {
    length = constraints.height;
    super.applyParentConstraints(caller, constraints);
  }

  @override
  Size get layoutSize {
    return layoutSizeIncreasedToLength(isWidthMain: false);
  }

}

/// Should be applied on children of [WidthSizerLayouter].
/// The mixin method [widthToLextr] provides the width (set by some far-away parent) to which this instance should lextr.
mixin WidthSizerLayouterChild on BoxContainer {

  /// Width in pixels of a far-away parent, to which this child's width will linearly extrapolate (lextr).
  ///
  /// All nullable fields must be set by now, otherwise error. We do the non-null cast without
  /// checking. Should be improved to provide good hints to users.
  double get widthToLextr =>
      (root.sandbox![RootSandboxSizers.keyInSandbox] as RootSandboxSizers).widthSizerEnsured.length;
}

/// Should be applied on children of [HeightSizerLayouter].
/// Mixin method [heightToLextr] provides the height (set by some far-away parent) to which this instance should lextr.
mixin HeightSizerLayouterChild on BoxContainer {

  /// Height in pixels of a far-away parent, to which this child's height will linearly extrapolate (lextr).
  ///
  /// See [WidthSizerLayouterChild] for details.
  double get heightToLextr =>
      (root.sandbox![RootSandboxSizers.keyInSandbox] as RootSandboxSizers).heightSizerEnsured.length;
}

// ---------- Width and Height sizers and layouters ^^^^^^ -------------------------------------------------------------

// ---------- Non-positioning BoxLayouter and BoxContainer -------------------------------------------------------------

/// Mixin provides role of a generic layouter for a one [LayoutableBox] or a list of [LayoutableBox]es.
///
/// The core functions of this class is to position their children
/// using [layout_Post_NotLeaf_PositionChildren] in self,
/// then apply the positions as offsets onto children in [_layout_Post_NotLeaf_OffsetChildren].
///
/// Layouter classes with this mixin can be divided into two categories,
/// if they use the default [layout] :
///
///   - *positioning* layouters position their children in self (potentially and likely to non-zero position).
///     This also implies that during layout, the position is converted into offsets , applied to it's children.
///     As a result, we consider extensions being *positioning* is equivalent to being *offsetting*.
///     Implementation-wise, *positioning* (and so *offsetting*)
///     extensions must implement both [layout_Post_NotLeaf_PositionChildren] and [_layout_Post_NotLeaf_OffsetChildren].
///     Often, the offset method can use the default, but the positioning method should be overriden.
///
///   - *non-positioning* (equivalent to *non-offsetting*) should implement both positioning
///     and offsetting methods as non-op.
///     If the positioning method is implemented does not hurt (but it's useless)
///     as long as the offsetting method is no-op.
///
/// Important Note: Mixin fields can still be final, but then they must be late, as they are
///   always initialized in concrete implementations constructors or their initializer list.

mixin BoxLayouter on BoxContainerHierarchy implements LayoutableBox, Keyed {

  // BoxLayouter section 1: Implements [Keyed] ----------------------------------------------------------------------------

  /// Unique [ContainerKey] [key] implements [Keyed].
  @override
  late final ContainerKey key;

  /// Defines the relative size of constraints when considered as one child among siblings.
  ///
  /// The 'relative size' is referred to as 'weight' of this child constraint among all children constraints.
  ///
  /// The 'weight' is given to each child, and the 'relative size' is calculated as this child weight,
  /// divided by sum of all siblings weight.
  ///
  /// [BoxContainer] derived classes should require this weight to be set
  /// by parent [BoxLayouter] (during construction), ONLY if parents want to proportionally layout
  /// instances of it's children. This is the situation for multi-children layouters, such as [Column] and [Row].
  ///
  late final ConstraintsWeight constraintsWeight;

  ConstraintsWeights get childrenWeights =>
      ConstraintsWeights.from(constraintsWeightList: __children.map((child) => child.constraintsWeight).toList());

  // BoxLayouter section 2: Implements [LayoutableBox] -------------------------------------------------

  /// Manages the layout size, the result of [layout].
  ///
  /// - On leaf layouters, it should generally be set as a tight rectangular envelope of pixels
  ///   that will be painted. For example, if a leaf paints a rectangle, it would be size of the rectangle.
  /// - On non-leaf , it should generally be set as a tight rectangular envelope of layed out and
  ///   positioned children.
  ///
  /// Set late in [layout], once the layout size is known after all children were layed out.
  /// Extensions of [BoxLayouter] should not generally override, even with their own layout.
  ///
  /// todo-03 : should layoutSize, and perhaps offset, be moved as separate getter/setter onto LayoutableBox? Certainly layoutSize should be!
  @override
  late final ui.Size layoutSize;

  // offset ------

  ui.Offset _offset = ui.Offset.zero;

  /// Current absolute offset, set by parent (and it's parent etc, to root).
  ///
  /// That means, it is the offset from (0,0) of the canvas. There is only one
  /// canvas, managed by the top BoxContainer, passed to all children in the
  /// [paint] (canvas).
  ///
  /// It is a sum of all offsets passed in subsequent calls
  /// to [applyParentOffset] during object lifetime.
  @override
  ui.Offset get offset => _offset;

  /// Implementation of abstract super [LayoutableBox.applyParentOffset].
  @override
  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    assertCallerIsParent(caller);

    if (orderedSkip) return;

    _offset += offset;

    for (var child in _children) {
      child.applyParentOffset(this, offset);
    }
  }

  // BoxLayouter section 3: Methods of [BoxLayouter] -------------------------------------------------------------------

  // orderedSkip ------
  bool _orderedSkip = false; // want to be late final but would have to always init.

  /// [orderedSkip] is set by parent; instructs this container that it should not be
  /// painted or layed out - as if it collapsed to zero size.
  ///
  /// When set to true, implementations must add appropriate support for collapse.
  bool get orderedSkip => _orderedSkip;

  /// Override of method on [LayoutableBox], uses the private member [_orderedSkip]
  /// with assert that caller is parent.
  ///
  /// todo-doc-01   /// Important override notes and rules for [applyParentOrderedSkip] on extensions:
  @override
  void applyParentOrderedSkip(LayoutableBox caller, bool orderedSkip) {
    assertCallerIsParent(caller);
    _orderedSkip = orderedSkip;
  }

  // constraints ------

  /// Constraints set by parent.
  late final BoxContainerConstraints _constraints;

  BoxContainerConstraints get constraints => _constraints;

  /// Set private member [_constraints] with assert that the caller is parent
  @override
  void applyParentConstraints(LayoutableBox caller, BoxContainerConstraints constraints) {
    assertCallerIsParent(caller);
    _constraints = constraints;
  }

  /// If size constraints imposed by parent are too tight,
  /// some internal calculations of sizes may lead to negative values,
  /// making painting of this [BoxLayouter] not possible.
  ///
  /// Setting the [allowParentToSkipOnDistressedSize] `true` helps to solve such situation.
  /// It causes the [BoxLayouter] not be painted
  /// (skipped during layout) when space is constrained too much
  /// (not enough space to reasonably paint the [BoxLayouter] contents).
  /// Note that setting this to `true` may result
  /// in surprising behavior, instead of exceptions.
  ///
  /// Note that concrete implementations must add
  /// appropriate support for collapse to work.
  ///
  /// Unlike [orderedSkip], which directs the parent to ignore this [BoxLayouter],
  /// [allowParentToSkipOnDistressedSize] is intended to be checked in code
  /// for some invalid conditions, and if they are reached, bypass painting
  /// the [BoxLayouter].
  bool allowParentToSkipOnDistressedSize = true; // always true atm

  /// Return true if container would like to expand as much as possible, within it's constraints.
  ///
  /// Greedy would take layoutSize infinity, but do not check that here, as layoutSize is late and not yet set
  ///   when this is called in [layout].
  bool get isGreedy => false;

  bool get hasGreedyChild => _children.where((child) => child.isGreedy).isNotEmpty;

  BoxLayouter get firstGreedyChild => _children.firstWhere((child) => child.isGreedy);

  /// Assert if caller is identical to container-hierarchy-parent in the [BoxContainerHierarchy].
  ///
  /// Works on behalf of 'apply' methods.
  /// On the root in [BoxContainerHierarchy], 'apply' can be invoked with any 'caller' instance.
  /// On any other [BoxContainer], 'apply' much be called from the  container-hierarchy-parent.
  void assertCallerIsParent(LayoutableBox caller) {
    if (!isRoot) {
      if (!identical(caller, _parent)) {
        throw StateError('On this $this, parent is $_parent, BUT it should be == to caller $caller');
      }
    }
  }

  /// Implementation of abstract [LayoutableBox.layout].
  ///
  /// Terminology:
  ///   - A leaf in documentation and method names of this algorithm is a [BoxContainer] with empty [__children].
  ///     Note: we may consider explicitly set another property such as [alwaysLeaf]. Reason: in dynamic layouts,
  ///               we may get a node that is normally not a leaf become a leaf using this definition,
  ///               causing that the default implementation of [layout_Post_Leaf_SetSize_FromInternals]
  ///               (which throws if called on no-children) stops the layout.
  ///               So in principle current approach forces us to always override [layout_Post_Leaf_SetSize_FromInternals].
  ///
  /// Implementation:
  ///   - The layouter order of processing of [_children] always starts with the first child
  ///     in the [_children] list, proceeds in it's [Iterator.moveNext] sequence.
  ///     This is also true for [_layout_Pre_DistributeConstraintsToImmediateChildren],
  ///     which, if overridden without overriding [layout], must distribute constraints in the same order.
  ///   - For a leaf, the only method called is [layout_Post_Leaf_SetSize_FromInternals]!
  ///     As a consequence, for a leaf, overriding [layout] and overriding [layout_Post_Leaf_SetSize_FromInternals]
  ///     achieves the same result, as long as either override has the same code.
  ///
  /// Important notes about this default implementation, overrides, terms, and conditions:
  ///   - For an extension overriding [layout] to function in a [BoxContainerHierarchy] the requirements
  ///     for the [layout] method are:
  ///     - It sets [layoutSize] (usually, just before return). The [layoutSize]
  ///       should be large enough to contain the whole area to which [BoxContainer.paint] will draw graphics.
  ///       This is the only requirement for leafs.
  ///     - On non-leafs only:
  ///       - On each child [__children] that need to be shown, invoke, in this order
  ///         - child.[applyParentConstraints]
  ///         - child.[layout]
  ///         - set child's [layoutSize]
  ///       - Calculate self [layoutSize] from children [layoutSize]s
  ///
  ///   - For an extension overriding SOME OF THE PUBLIC METHODS CALLED IN [layout] BUT NOT [layout],
  ///     to function in a [BoxContainerHierarchy] the requirements are:
  ///     - On leaf, override [layout_Post_Leaf_SetSize_FromInternals] and set [layoutSize].
  ///
  @override
  void layout() {
    buildAndReplaceChildren();

    _layout_IfRoot_DefaultTreePreprocessing();

    // A. node-pre-descend. When entered:
    //    - constraints on self are set from recursion
    //    - constraints on children are not set yet.
    //    - children to not have layoutSize yet
    _layout_TopRecurse();
  }

  // BoxLayouter section 3: Non-override new methods on this class, starting with layout methods -----------------------

  // BoxLayouter section 3.1: Layout methods

  void _layout_IfRoot_DefaultTreePreprocessing() {
    if (isRoot) {
      // todo-04 : rethink, what this size is used for. Maybe create a singleton 'uninitialized constraint' - maybe there is one already?
      assert(constraints.size != const ui.Size(-1.0, -1.0));
      // Removed forced Packing changes on deeper Row and Column
    }
  }

  void _layout_TopRecurse() {
    // A. node-pre-descend. Here, children to not have layoutSize yet. Constraint from root down should be set
    _layout_Pre_DistributeConstraintsToImmediateChildren(_children);

    // B. node-descend
    _layout_Descend();

    // C. node-post-descend. Children now have layoutSizes, used to layout children in me (place in rectangles in me),
    //    then rectangle offsets in me are applied on children as parent offset
    _layout_Post_IfLeaf_SetSize_IfNotLeaf_PositionThenOffsetChildren_ThenSetSize_Finally_AssertSizeInsideConstraints();
  }

  /// This [BoxLayouter]'s default implementation distributes this layouter 's unchanged
  /// and undivided constraints onto all it's immediate children before descending to children [layout].
  ///
  ///  This is not recursive - the constraints are applied only on immediate children.
  ///
  /// The semantics of 'distribute constraint to children' is layout specific:
  ///   - This implementation and any common layout: pass it's constraints onto it's children unchanged.
  ///     As a result, each child will be allowed to get up to it's parent constraints size.
  ///     If all children were to use the constraint sizes fully, and set their sizes that large,
  ///     the owner layouter would overflow, but the assumption is children only use a fraction of available constraints.
  ///   - Specific implementation (e.g. [IndividualChildConstrainingRow])
  ///     may 'divide' it's constraints evenly or unevenly to children, passing each
  ///     a fraction of it's constraint.
  ///
  void _layout_Pre_DistributeConstraintsToImmediateChildren(List<LayoutableBox> children) {
    for (var child in children) {
      child.applyParentConstraints(this, constraints);
    }
  }

  void _layout_Descend() {
    for (var child in _children) {
      // b1. child-pre-descend (empty)
      // b2. child-descend
      child.layout();
      // b3. child-post-descend (empty)
    }
  }

  /// The wrapper of the 'layouter specific processing' in post descend.
  ///
  /// Preconditions:
  ///   - all [constraints] are distributed in
  ///     pre-descend [_layout_Pre_DistributeConstraintsToImmediateChildren].
  ///
  /// Results:
  /// On leaf:
  ///   - The [layoutSize] is set from internals.
  /// On non-leaf:
  ///   - Children are offset depending on layouter and children [layoutSizes].
  ///   - The current container [layoutSizes] is calculated as [_boundingRectangle] of all chidlren.
  /// Common:
  ///   - The current container [layoutSizes] is asserted to be within [constraint]
  ///
  void
  _layout_Post_IfLeaf_SetSize_IfNotLeaf_PositionThenOffsetChildren_ThenSetSize_Finally_AssertSizeInsideConstraints() {
    if (isLeaf) {
      layout_Post_Leaf_SetSize_FromInternals();
    } else {
      _layout_Post_NotLeaf_PositionThenOffsetChildren_ThenSetSize();
    }
    __layout_Post_AssertSizeInsideConstraints();
  }

  /// Performs the CORE of the 'layouter specific processing',
  /// by finding all children positions in self,
  /// then using the positions to set children [offset]s and [layoutSize]s.
  ///
  /// Assumes that [constraints] have been set in [_layout_Pre_DistributeConstraintsToImmediateChildren].
  ///
  /// Final side effect result must always be setting the [layoutSize] on this node.
  ///
  /// Important override notes and rules for [_layout_Post_NotLeaf_PositionThenOffsetChildren_ThenSetSize] on extensions:
  ///   - On Non-positioning extensions using the default [layout],
  ///     best performance with non-positioning is when extensions override
  ///     this method and perform the role of  [_layout_Post_NotLeaf_SetSize_FromPositionedChildren],
  ///     setting the [layoutSize].
  ///     Then the default invoked [layout_Post_NotLeaf_PositionChildren], [_layout_Post_NotLeaf_OffsetChildren],
  ///     and [_layout_Post_NotLeaf_SetSize_FromPositionedChildren] would be bypassed and take no cycles.
  ///   - On positioning extensions of [BoxLayouter] using the default [layout],
  ///     the desired extension positioning effect is usually achieved by
  ///     overriding only the [layout_Post_NotLeaf_PositionChildren]. But extensions which [layoutSize]
  ///     is something else than [_children]'s bounding rectangle ([Greedy], [Padder])
  ///     also need to override [_layout_Post_NotLeaf_SetSize_FromPositionedChildren].
  void _layout_Post_NotLeaf_PositionThenOffsetChildren_ThenSetSize() {
    // Common processing for greedy and non-greedy:
    // First, calculate children offsets within self.
    // Note: - When the greedy child is re-layed out, it has a final size (remainder after non greedy sizes added up),
    //         we can deal with the greedy child as if non greedy child.
    //       - no-op on baseclass [BoxLayouter].
    List<ui.Rect> positionedRectsInMe = layout_Post_NotLeaf_PositionChildren(_children);

    // Apply the calculated positionedRectsInMe as offsets on children.
    _layout_Post_NotLeaf_OffsetChildren(positionedRectsInMe, _children);
    // Finally, when all children are at the right offsets within me, invoke
    // [_layout_Post_NotLeaf_SetSize_FromPositionedChildren] to set the [layoutSize] on me.
    //
    // My [layoutSize] CAN be calculated using one of two equivalent methods:
    //   1. Query all my children for offsets and sizes, create each child rectangle,
    //      then create bounding rectangle from them.
    //   2. Use the previously created [positionedRectsInMe], which is each child rectangle,
    //      then create bounding rectangle of [positionedRectsInMe].
    // In [_layout_Post_NotLeaf_SetSize_FromPositionedChildren] we use method 2, but assert sameness between them
    _layout_Post_NotLeaf_SetSize_FromPositionedChildren(positionedRectsInMe);
  }

  /// Positions the passed [children] in rectangles which are relative to, and inside [constraints]
  /// of this layouter, according to this layouter rules.
  ///
  /// Returns the rectangles in the same order as [_children].
  ///
  /// For example, for a [Column] layout with [Packing.loose] and [Align.center], the returned
  /// rectangles will be centered inside the [constraints]' [Size],
  /// and loosely fill the [Size].
  ///
  /// The reason [children] are passed (rather than using a member [BoxContainerHierarchy._children])
  /// is that some [BoxLayouter] derived classes may need to invoke this on a subset of children.
  ///
  /// Abstract in [BoxLayouter] and no-op in [BoxContainer] (where it applies zero offset to children).
  ///
  /// Implementations should lay out children of self [BoxLayouter],
  /// and return [List<ui.Rect>], a list of rectangles [List<ui.Rect>]
  /// where children will be placed relative to the invoker, in the order of the passed [children].
  /// If no [children] are passed, the implementation should use all member [_children].
  ///
  ///
  /// On a leaf node, implementations should return an empty list.
  ///
  /// *Important*: When invoked on a [BoxLayouter] instance, it is assumed it's children were already layed out;
  ///              so this should be invoked in any layout algorithm in the children-post-descend section.
  ///
  /// In the default [layout] implementation, this message [layout_Post_NotLeaf_PositionChildren]
  /// is send by the invoking [BoxLayouter] to self, during the children-past-descend.
  ///
  /// Important Definition:
  ///   If a method name has 'PositionChildren' in it's name, it means:
  ///    - It is invoked on a node that is a parent (so self = parent)
  ///    - The method should do the following:
  ///      - Arrange for self to ask children their layout sizes. Children MUST have already
  ///        been recursively layed out!! (Likely by invoking child.layout recursively).
  ///      - Arrange for self to use children layout sizes and it's positioning algorithm
  ///        to calculate (but NOT set) children positions (offsets) in itself
  ///        returning a list of rectangles, one for each child
  ///
  List<ui.Rect> layout_Post_NotLeaf_PositionChildren(List<LayoutableBox> children);

  /// An abstract method of the default [layout] which role is to
  /// offset the [children] by the pre-calculated offsets [positionedRectsInMe] .
  ///
  /// Important override notes and rules for [_layout_Post_NotLeaf_OffsetChildren] on extensions:
  ///
  ///   - Positioning extensions should invoke [BoxLayouter.applyParentOffset]
  ///     for all children in argument [children] and apply the [Rect.topLeft]
  ///     offset from the passed [positionedRectsInMe].
  ///   - Non-positioning extensions (notably BoxContainer) should make this a no-op.
  ///
  /// First argument should be the result of [layout_Post_NotLeaf_PositionChildren],
  /// which is a list of layed out rectangles [List<ui.Rect>] of [children].
  void _layout_Post_NotLeaf_OffsetChildren(List<ui.Rect> positionedRectsInMe, List<LayoutableBox> children);

  /// The responsibility of [_layout_Post_NotLeaf_SetSize_FromPositionedChildren]
  /// is to set the [layoutSize] of self.
  ///
  /// In the default [layout], when this method is invoked,
  /// all children have their [layoutSize]s and [offset]s set.
  ///
  /// The [layoutSize] in this default implementation is set
  /// to the size of "bounding rectangle of all positioned children".
  /// This "bounding rectangle of all positioned children" is calculated from the passed [positionedChildrenRects],
  /// which is the result of preceding invocation of [layout_Post_NotLeaf_PositionChildren].
  ///
  /// The bounding rectangle of all positioned children, is calculated by [util_flutter.boundingRectOfRects].
  ///
  /// Note:  The [layoutSize] CAN be calculated using one of two equivalent methods:
  ///        1. Query all my children for offsets and sizes, create each child rectangle,
  ///           then create bounding rectangle from them.
  ///        2. Use the previously created [positionedRectsInMe], which is each child rectangle,
  ///           then create bounding rectangle of [positionedRectsInMe].
  ///        We use method 2, but assert sameness between them.
  ///
  /// Important override notes and rules for [applyParentOrderedSkip] on extensions:
  ///   - Only override if self needs to set the layoutSize bigger than the outer rectangle of children.
  ///     Overriding extensions include layouts which do padding,
  ///     or otherwise increase their sizes, such as [Greedy], [Padder], [Aligner].
  ///   - [RollingBoxLayouter]s [Row] and [Column] use this
  ///     - although they override [layout], the method [_layout_Post_NotLeaf_PositionThenOffsetChildren_ThenSetSize]
  ///     which invokes this is default. These classes rely on this default
  ///     "bounding rectangle of all positioned children" implementation.
  ///
  void _layout_Post_NotLeaf_SetSize_FromPositionedChildren(List<ui.Rect> positionedChildrenRects) {

    ui.Rect positionedChildrenOuterRect = util_flutter
        .boundingRectOfRects(positionedChildrenRects.map((ui.Rect childRect) => childRect).toList(growable: false));

    __layout_Post_Assert_Layedout_Rects(positionedChildrenRects, positionedChildrenOuterRect);

    layoutSize = positionedChildrenOuterRect.size;
  }

  /// Leaf [BoxLayouter] extensions should override and set [layoutSize].
  ///
  /// Throws exception if sent to non-leaf, or sent to a leaf
  /// which did not override this method.
  void layout_Post_Leaf_SetSize_FromInternals() {
    if (!isLeaf) {
      throw StateError('Only a leaf can be sent this message.');
    }
    throw UnimplementedError('On leaf [BoxLayouter] which does NOT override [layout], this method named '
        '[layout_Post_Leaf_SetSize_FromInternals] must be overridden. Method called on $runtimeType instance=$this.');
  }

  ui.Rect __layout_Post_Assert_Layedout_Rects(List<ui.Rect> positionedChildrenRects, ui.Rect positionedChildrenOuterRect) {
    assert(!isLeaf);
    // childrenOuterRectangle is ONLY needed for asserts. Can be removed for performance.
    ui.Rect childrenOuterRectangle = util_flutter
        .boundingRectOfRects(_children.map((BoxLayouter child) => child._boundingRectangle()).toList(growable: false));
    util_flutter.assertSizeResultsSame(childrenOuterRectangle.size, positionedChildrenOuterRect.size);
    return positionedChildrenOuterRect;
  }

  /// Checks if [layoutSize] box is within the [constraints] box.
  ///
  /// Throws error otherwise.
  void __layout_Post_AssertSizeInsideConstraints() {
    if (!constraints.containsFully(layoutSize)) {
      String errText = 'Warning: Layout size of this layouter $this is $layoutSize,'
          ' which does not fit inside it\'s constraints $constraints';
      // Print a red error, but continue and let the paint show black overflow rectangle
      print(errText);
    }
  }

  /// Bounding rectangle of this [BoxLayouter].
  ///
  /// It should only be called after [layout] has been performed on this layouter.
  ui.Rect _boundingRectangle() {
    return offset & layoutSize;
  }

  /// Returns a list of lengths of [children] measured along the passed [layoutAxis].
  List<double> layoutSizesOfChildrenSubsetAlongAxis(
    LayoutAxis layoutAxis,
    List<LayoutableBox> children,
  ) =>
      children.map((layoutableBox) => layoutableBox.layoutSize.lengthAlong(layoutAxis)).toList();

  /// This top level function constructs a [BoundingBoxesBase] which this [BoxLayouter] would consider a
  /// minimum and maximum size of layed out passed [childrenBoxes].
  ///
  /// Effectively, the return value is the envelope of the layed out [childrenBoxes].
  /// This would be used in a two pass layout.
  BoundingBoxesBase envelopeOfChildrenAfterLayout({
    required covariant List<BoundingBoxesBase> childrenBoxes,
  }) {
    throw UnimplementedError('Implement in extensions');
  }
}


/// Base class for all containers and layouters.
///
/// Class name, roles and responsibilities of [Container] :
///   - [Container] refers to an object which:
///     - Is a hierarchy of [Container]s.
///       This hierarchy role of [Container] implies also a role of being a parent of it's children.
///     - Is able to present itself by painting itself in a graphical 2D window,
///       as a painted part of an application, or the painted application.
///     - Takes up, and is painted inside of, a contiguous area of the graphical window .
///       In particular, a [BoxContainer] takes up and paints a possibly
///       transformed (rotated, skewed etc) Rectangle in the application.
///     - Allows it's hierarchical children to show themselves within the contiguous area
///       painted by self by calling any child's [paint].
///
/// Effectively a [NonPositioningBoxLayouter] class.
/// The property of being [NonPositioningBoxLayouter] is inherited
/// from the [BoxLayouter] which is also a [NonPositioningBoxLayouter].
///
/// Mixin [BoxContainerHierarchy] is repeated here in [BoxContainer] and in [BoxLayouter]
/// to make clear that both [BoxContainer] and [BoxLayouter]
/// have the same [BoxContainerHierarchy] role (capability).
///
/// Children are either passed, or created in constructor body. Show example.
///
abstract class BoxContainer extends BoxContainerHierarchy with BoxLayouter implements LayoutableBox, Keyed, UniqueKeyedObjectsManager {
  /// Default generative constructor.
  BoxContainer({
    // todo-013 : can key and children be required, final, and non nullable?
    ContainerKey? key,
    List<BoxContainer>? children,
    ConstraintsWeight constraintsWeight = ConstraintsWeight.defaultWeight,
  }) {
    // Late initialize the constraintsWeight
    this.constraintsWeight = constraintsWeight;

    // Place self as the DoubleLinkedOwner of it's children
    doubleLinkedOwner = this;

    //if (parent != null) {
    //  this.parent = parent;
    //}
    _ensureKeySet(this, key);

    // Initialize children list to empty
    // __children = [];
    // [children] may be omitted (not passed, null), then concrete extension must create and
    // add [children] in the constructor using [addChildren], see [LegendContainer] as example
    if (children != null) {
      //  && this.children != ChildrenNotSetSingleton()) {
      __children.clear();
      __children.addAll(children);
      // Establish a 'nextSibling' linked list between __children
      linkAll();
    }

    // Having added children, ensure key uniqueness
    ensureKeyedMembersHaveUniqueKeys();

    // Make self a parent of all immediate children
    _makeSelfParentOf(this, __children);

    // NAMED GENERATIVE super() called implicitly here.
  }

  Map? sandbox;

  /// A no-op override of the abstract [BoxLayouter.layout_Post_NotLeaf_PositionChildren].
  ///
  /// No-op means this implementation does not apply parent offsets on the passed [children],
  /// it returns rectangles around each child's existing offset and size.
  ///
  /// The follow up method [_layout_Post_NotLeaf_OffsetChildren] uses the returned rectangles
  /// and applies this layouter's parent offset on the children.
  ///
  /// See the invoking [_layout_Post_NotLeaf_PositionThenOffsetChildren_ThenSetSize].
  ///
  @override
  List<ui.Rect> layout_Post_NotLeaf_PositionChildren(List<LayoutableBox> children) {
    // This is a no-op because it does not change children positions from where they are at their current offsets.
    // However, implementation is needed BoxContainer extensions which are positioning
    // - in other words, all, NOT NonPositioningBoxLayouter extensions.
    return children.map((LayoutableBox child) => child.offset & child.layoutSize).toList(growable: false);
  }

  /// Implementation of the abstract default [_layout_Post_NotLeaf_OffsetChildren]
  /// invoked in the default [layout].
  ///
  /// This class, as a non-positioning container should make this a no-op,
  /// resulting in no offsets applied on children during layout.
  @override
  void _layout_Post_NotLeaf_OffsetChildren(List<ui.Rect> positionedRectsInMe, List<LayoutableBox> children) {
    // No-op in this non-positioning base class
  }

  /// Painting base method of all [BoxContainer] extensions,
  /// which should paint self on the passed [canvas].
  ///
  /// This default [BoxContainer] implementation implements several roles:
  ///   - Overflow check: Checks for layout overflows, on overflow, paints a yellow-black rectangle
  ///   - Skip check: Checks for [orderedSkip], if true, returns as a no-op
  ///   - Paint forward: Forwards [paint] to [_children]
  ///
  /// On Leaf nodes, it should generally paint whatever primitives (lines, circles, squares)
  /// the leaf container consists of.
  ///
  /// On Non-Leaf nodes, it should generally forward the [paint] to its' children, as
  /// this default implementation does.
  ///
  /// Important override notes and rules for [paint] on extensions:
  ///  1) In non-leafs: [paint] override generally not needed. Details:
  ///    -  This default implementation, orderedSkip stops painting the node
  ///          under first parent that orders children to skip, which is generally needed.
  ///    - This default implementation forwards the [paint] to its' children, which is generally needed.
  ///  2) In leafs: [paint] override is always(?) needed.
  ///    - Override should do:
  ///      - `if (orderedSkip) return;` - this is required if the leaf's parent is the first up who ordered to skip
  ///      - Perform any canvas drawing needed by calling [canvas.draw]
  ///      - If the container contains Flutter-level widgets that have the [paint] method, also call paint on them,
  ///        for example, [LabelContainer._textPainter.paint]
  ///      - No super call needed.
  ///
  void paint(ui.Canvas canvas) {
    // Check for overflow on every non-leaf non-overridden paint.
    // This is probably not enough as leafs are not reached.
    // But in the new layouter, non-leafs should be fully correctly contained within parents, so checking parents is enough.
    paintWarningIfLayoutOverflows(canvas);

    if (orderedSkip) return;

    for (var child in _children) {
      child.paint(canvas);
    }
  }

  /// Paints a yellow-and-black warning rectangle about this BoxLayouter overflowing root constraints.
  void paintWarningIfLayoutOverflows(ui.Canvas canvas) {
    // Find constraints on top container - [get topContainerConstraints],
    //   and access them from any BoxContainer.
    BoxContainerConstraints rootConstraints = root.constraints;
    ui.Offset rootOffset = root.offset;
    ui.Rect rootConstraintsMaxRect = rootOffset & rootConstraints.maxSize; // assume constraints full box with maxSize

    ui.Rect myPaintedRect = offset & layoutSize;
    // Check if myPaintedRect is beyond the rootConstraints
    bool rootConstraintsContainMyPaintedRect = rootConstraints.whenOffsetContainsFullyOtherRect(
        rootOffset, myPaintedRect);
    if (!rootConstraintsContainMyPaintedRect) {
      // If rootConstraints do NOT FULLY contain myPaintedRect, find how much they intersect,
      //   or move myPaintedRect towards rootConstraints so they have 'visibly large' intersect
      // Then create a rectangle protrudingInThisDirection inside rootConstraints,
      //   on the general side of where myPaintedRect is protruding
      ui.Rect protrudingInThisDirection = rootConstraintsMaxRect.closestIntersectWith(myPaintedRect);
      // paint the protrudingInThisDirection rectangle
      canvas.drawRect(
        protrudingInThisDirection,
        ui.Paint()..color = material.Colors.black,
      );
    }
  }
}

/*
/// Mixin marks implementations as able to create and add [_children] *late*,
/// during [layout] of their parent.
///
/// Note: By default, [_children] should created *early* in the [BoxContainer] constructor.
///
/// This mixin should be used by extension of [BoxContainer]s
/// that need to wait constructing children later than in the constructor.
///
/// As an example, we have a chart with 'root container' which contains two hierarchy-sibling areas:
///   - the 'x axis container', which shows data labels that must not wrap, but
///     there may be too many labels to fit the width.
///   - The 'data container' which shows, among others, a dotted vertical line
///     in the center of each label.
///
/// An acceptable solution to the problem where 'x axis container' labels that must not wrap, but
/// there may be too many labels to fit the width, is for the chart to skip every N-th label.
/// The N only becomes known during the 'x axis container' [layout],
/// called from the 'root container' [layout].  But this situation creates a
/// dependency for drawing dotted lines above the labels. As the dotted lines are part
/// of 'data container', a sibling container to the 'x axis container',
/// we can mix this [BuilderOfChildrenDuringParentLayout] to the 'data container',
/// and call it's [buildAndReplaceChildren] during the 'root container' [layout].
///
/// This approach requires for the 'source' sibling 'x axis container' to *know* which sibling(s) 'sinks'
/// depend on the 'source' [layout], and the other way around.  Also, the 'source' and the 'sink' must
/// agree on the object to exchange the 'sink' create information - this is the object
/// returned from [findSourceContainersReturnLayoutResultsToBuildSelf]
///
/// In such situation, a hierarchy-parent during the [layout] would first call
/// this mixin's siblings' [layout], establishing the remaining space
/// ([constraints]) left over for this [BuilderOfChildrenDuringParentLayout] container, then
/// create an 'appropriate', 'non-overlapping' children of itself.
///
/// todo-doc-01 maybe remove or improve all below
/// Example:
///   - An example is the Y axis ([YContainer] instance), which creates only as many labels
///     ([YLabelContainer]s instances) as they fit, given how many pixels
///     the Y axis has available. Such pixel availability is applied on  [YContainer]
///
///
/// Important note:
///   - It is assumed that [constraints] are set on this [BoxContainer] before calling this,
///     likely in parent's [layout] that calls first [layout] on
///     one or more siblings, calculating the [constraints] remaining for this  [BoxContainer].
///   - Implementations MUST also call [layout] immediately after calling
///     the [buildAndReplaceChildren].

mixin BuilderOfChildrenDuringParentLayout on BoxContainer {

  /// Intended implementation is to find sibling 'source' [BoxContainer]s which [layout] results 'drive'
  /// the build of this 'sink' [BoxContainer] (the build is performed by [buildAndReplaceChildren]).
  ///
  /// Intended place of invocation is in this sink's [BoxContainer]'s [buildAndReplaceChildren], which
  /// builds and adds it's children, based on the information in the object returned from this method.
  ///
  /// All information regarding
  ///   - what sibling [BoxContainer]s are 'sources' which [layout] 'drives' the build of this [BoxContainer]
  ///   - how to find such siblings
  ///   - what is the returned object that serves as a message between the 'source' [BoxContainer]s [layout] results
  ///     and this 'sink' [buildAndReplaceChildren]
  ///  must be available to this [BoxContainer].
  ///
  /// The finding may be done using [ContainerKey] or simply hardcoded reaching to the siblings.
  ///
  /// Returns the object that serves as a message from the 'source' [BoxContainer]s to this 'sink' [BoxContainer],
  /// during the sink's [buildAndReplaceChildren].
  Object findSourceContainersReturnLayoutResultsToBuildSelf() {
    throw UnimplementedError(
        '$this.findSourceContainersReturnLayoutResultsToBuildSelf: '
            'Implementations invoking this method must implement it.');
  }
}
*/
// ---------- Positioning and non-positioning layouters, rolling positioning layouters, Row and Column, Greedy ---------

/// Abstract layouter which is allowed to offset it's children with non zero offset.
///
/// The default implementation overrides the [_layout_Post_NotLeaf_OffsetChildren] which changes children positions
/// by applying the offset from each top left rectangle passed in [positionedRectsInMe]
/// to each child in the same order.
///
/// The parameter[positionedRectsInMe] must be created by the layouter 's previous
/// computations in [layout_Post_NotLeaf_PositionChildren] from all children in order.
///
/// Important note: Because of this dependency, there are a few rules:
///   - [_layout_Post_NotLeaf_OffsetChildren] should generally not be overridden,
///   - BUT, if a derived class overrides [layout_Post_NotLeaf_PositionChildren] in a way that changes the order
///     in it's result, it must also override [_layout_Post_NotLeaf_OffsetChildren].
///
abstract class PositioningBoxLayouter extends BoxContainer {
  /// The required unnamed constructor
  PositioningBoxLayouter({
    List<BoxContainer>? children,
    ConstraintsWeight constraintsWeight = ConstraintsWeight.defaultWeight,
  }) : super(
          children: children,
          constraintsWeight: constraintsWeight,
        );

  /// Applies the offsets given with the passed [positionedRectsInMe]
  /// on the passed [LayoutableBox]es [children].
  ///
  /// The [positionedRectsInMe] are obtained by this [Layouter]'s
  /// extensions using [layout_Post_NotLeaf_PositionChildren].
  ///
  ///
  @override
  void _layout_Post_NotLeaf_OffsetChildren(List<ui.Rect> positionedRectsInMe, List<LayoutableBox> children) {
    assert(positionedRectsInMe.length == children.length);
    for (int i = 0; i < positionedRectsInMe.length; i++) {
      children[i].applyParentOffset(this, positionedRectsInMe[i].topLeft);
    }
  }

  @override
  void buildAndReplaceChildren() {
    buildAndReplaceChildrenDefault();
  }
}

/// Layouter which is NOT allowed to offset it's children, or only offset with zero offset.
abstract class NonPositioningBoxLayouter extends BoxContainer {
  /// The required generative constructor
  NonPositioningBoxLayouter({
    List<BoxContainer>? children,
  }) : super(
    children: children,
  );

  /// Override for non-positioning:
  /// Does not apply any offsets on the it's children (passed in [layout] internals.
  @override
  void _layout_Post_NotLeaf_OffsetChildren(List<ui.Rect> positionedRectsInMe, List<LayoutableBox> children) {}

  /// Override for non-positioning:
  /// Does not need to calculate position of children in self, as it will not apply offsets anyway.
  @override
  List<ui.Rect> layout_Post_NotLeaf_PositionChildren(List<LayoutableBox> children) {
    // This is a no-op because it does not change children positions from where they are at their current offsets.
    // Cannot just return [], as result is used in offsetting (which is empty, so OK there),
    // and setting layoutSize using the returned value
    // (which would fail, unless replaced with looking at children offsets)
    return children.map((LayoutableBox child) => child.offset & child.layoutSize).toList(growable: false);
  }

  @override
  void buildAndReplaceChildren() {
    buildAndReplaceChildrenDefault();
  }

}

/// Intermediate layout class uses the main/cross axis properties concept, but keeps layout from it's superclass.
///
/// Extensions are intended to split to external ticks layoter and rolling layouter.
abstract class MainAndCrossAxisBoxLayouter extends PositioningBoxLayouter {
  MainAndCrossAxisBoxLayouter({
    required List<BoxContainer> children,
    required Align mainAxisAlign,
    required Packing mainAxisPacking,
    required Align crossAxisAlign,
    required Packing crossAxisPacking,
    ConstraintsWeight mainAxisConstraintsWeight = ConstraintsWeight.defaultWeight,
  }) : super(
    children: children,
    constraintsWeight: mainAxisConstraintsWeight,
  ) {
    mainAxisLayoutProperties = LengthsPositionerProperties(
      align: mainAxisAlign,
      packing: mainAxisPacking,
    );
    crossAxisLayoutProperties = LengthsPositionerProperties(
      align: crossAxisAlign,
      packing: crossAxisPacking,
    );
  }

  LayoutAxis mainLayoutAxis = LayoutAxis.horizontal;

  // todo-013 : mainAxisLayoutProperties and crossAxisLayoutProperties could be private
  //            so noone overrides their 'packing: Packing.tight, align: Align.start'
  /// Properties of layout on main axis.
  ///
  /// Note: cannot be final, as _forceMainAxisLayoutProperties may re-initialize
  ///
  late LengthsPositionerProperties mainAxisLayoutProperties;
  late LengthsPositionerProperties crossAxisLayoutProperties;

}

  /// Base class for layouters which layout along two axes: the main axis, along which the layout
/// children flow in the axis direction without wrapping (although can overlap),
/// and the cross axis, along which the layout children can be positioned anywhere.
///
/// The intended derived layouters are [Row] and [Column], which both also allow to process [Greedy] children.
///
/// This base layouter supports various alignment and packing of children,
/// along both the main and the cross axes. The alignment and packing is set
/// by the named parameters [mainAxisAlign], [mainAxisPacking], [crossAxisAlign], [crossAxisPacking].
/// See [Align] and [Packing] for the supported values of the named parameters;
/// their values affect the resulting layout of the [children].
///
/// The members [mainAxisLayoutProperties] and [crossAxisLayoutProperties]
/// are private wrappers for alignment and packing properties.
///
/// Note that [Align] and [Packing] are needed to be set both on the 'main' direction,
/// as well as the 'cross' direction on this base class constructor.
///
/// Similar to Flex.
abstract class RollingBoxLayouter extends MainAndCrossAxisBoxLayouter {
  RollingBoxLayouter({
    required List<BoxContainer> children,
    required Align mainAxisAlign,
    required Packing mainAxisPacking,
    required Align crossAxisAlign,
    required Packing crossAxisPacking,
    ConstraintsWeight mainAxisConstraintsWeight = ConstraintsWeight.defaultWeight,
  }) : super(
    children: children,
    mainAxisAlign: mainAxisAlign,
    mainAxisPacking: mainAxisPacking,
    crossAxisAlign: crossAxisAlign,
    crossAxisPacking: crossAxisPacking,
    mainAxisConstraintsWeight: mainAxisConstraintsWeight,
  );

  /// [RollingBoxLayouter] overrides the base [BoxLayouter.layout] to support [Greedy] children
  ///
  /// - If [Greedy] children are not present, this implementation behaves the same as the overridden base,
  ///   obviously implementing the abstract functionality of the base layout:
  ///   - Distributes constraints to children in [_layout_Pre_DistributeConstraintsToImmediateChildren];
  ///     constraints given to each child are full parent's constraints.
  /// - If [Greedy] children are     present, this implementation first processed non [Greedy] children:
  ///   - Distributes constraints to non-greedy children in in [_layout_Pre_DistributeConstraintsToImmediateChildren];
  ///     (constraints on non-greedy are same as parent's, as if greedy were not present),
  ///   - Invokes child [layout] on non [Greedy] first
  ///   - Then uses the size unused by non-greedy [layoutSize] as constraint to the [Greedy] child which is layed out.
  ///
  @override
  void layout() {
    buildAndReplaceChildren();

    _layout_IfRoot_DefaultTreePreprocessing();

    // Process Non-Greedy children first, to find what size they use
    if (_hasNonGreedy) {
      // A. Non-Greedy pre-descend : Distribute and set constraints only to nonGreedyChildren, which will be layed out
      //      using the set constraints. Constraints are distributed by children weight if used, else full constraints
      //      from parent are used.
      _layout_Pre_DistributeConstraintsToImmediateChildren(_nonGreedyChildren);
      // B. Non-Greedy node-descend : layout non-greedy children first to get their [layoutSize]s.
      for (var child in _nonGreedyChildren) {
        child.layout();
      }
      // C. Non-greedy node-post-descend. Here, non-greedy children have layoutSize
      //      which we can get and use to lay them out to find constraints left for greedy children.
      //    But to position children in self, we need to run pre-position of children in self
      //      using left/tight to get sizes without spacing.
      _layout_Rolling_Post_NonGreedy_FindConstraintRemainingAfterNonGreedy_DivideIt_And_ApplyOnGreedy();
    } // same as current on Row and Column

    // At this point, both Greedy and non-Greedy children have constraints. In addition, non-Greedy children
    //   are fully recursively layed out, but not positioned in self yet - and so not parent offsets are
    //   set on non_Greedy. This will be done later in  _layout_Post_IfLeaf_SetSize(etc).
    //
    // So to fully layout self, there are 3 steps left:
    //   1. Need to recursively layout GREEDY children to get their size.
    //      Their greedy constraints were set in previous layout_Post,
    //        the _layout_Post_NonGreedy_FindConstraintRemainingAfterNonGreedy_DivideIt_And_ApplyOnGreedy.
    //      So we do NOT want to run a full [layout] on greedy children - we need to avoid setting
    //      child constraints again in  _layout_TopRecurse() -> _layout_Pre_DistributeConstraintsToImmediateChildren(children);
    //      We only want the descend part of _layout_TopRecurse(), even the layout_Post must be different
    //        as it must apply to all children, not just GREEDY.
    //   2. Position ALL children within self, using self axis layout properties (which is set back to original)
    //   3. Apply offsets from step 2 on children
    // Steps 2. and 3 already have a default method, the
    //       _layout_Post_IfLeaf_SetSize_IfNotLeaf_PositionThenOffsetChildren_ThenSetSize_Finally_AssertSizeInsideConstraints
    //       which must be applies on all children. (it is).

    // Step 1.
    for (var child in _greedyChildren) {
      child.layout();
    }
    // Step 2. and 3. is a base class method unchanged.
    _layout_Post_IfLeaf_SetSize_IfNotLeaf_PositionThenOffsetChildren_ThenSetSize_Finally_AssertSizeInsideConstraints();
    // } else {
    //   // Working processing for no greedy children present. Maybe we can reuse some code with the above?
    //   _layout_TopRecurse();
    // }
  }

  /// Distributes constraints to the passed [children] specifically for this layout, the
  ///
  /// Overridden from [BoxLayouter] to work like this:
  ///
  ///   - If all children have a weight defined
  ///     (that is, none have [ConstraintsWeight.defaultWeight], checked by [ConstraintsWeights.allDefined])
  ///     this method divides the self constraints to smaller pieces along the main axis, keeping the self constraint size
  ///     along the cross axis. Then distributes the divided constraints to children
  ///   - else if some children do not have weight defined (that is, some have [ConstraintsWeight.defaultWeight])
  ///     this method invokes super implementation equivalent, which distributes self constraints undivided to all children.
  @override
  void _layout_Pre_DistributeConstraintsToImmediateChildren(List<LayoutableBox> children) {
    ConstraintsWeights childrenWeights = ConstraintsWeights.from(
        constraintsWeightList: children.map((LayoutableBox child) => (child as BoxLayouter).constraintsWeight)
            .toList());
    if (childrenWeights.allDefined) {
      assert (childrenWeights.constraintsWeightList.length == children.length);
      // Create divided constraints for children according to defined weights
      List<BoundingBoxesBase> childrenConstraints = constraints.divideUsingStrategy(
        divideIntoCount: children.length,
        divideStrategy: ConstraintsDistribution.intWeights,
        layoutAxis:  mainLayoutAxis,
        intWeights: childrenWeights.intWeightList,
      );

      assert (childrenConstraints.length == children.length);

      // Apply the divided constraints on children
      for (int i = 0; i < children.length; i++) {
        _children[i].applyParentConstraints(this, childrenConstraints[i] as BoxContainerConstraints);
      }
    } else {
      // This code is the same as super implementation in [BoxLayouter]
      for (var child in children) {
        child.applyParentConstraints(this, constraints);
      }
    }
  }

  /// Implementation of the abstract method which lays out the invoker's children.
  ///
  /// It lay out children of self [BoxLayouter],
  /// and return [List<ui.Rect>], a list of rectangles [List<ui.Rect>]
  /// where children will be placed relative to the invoker,
  /// in the order of the passed [children].
  ///
  /// See [BoxLayouter.layout_Post_NotLeaf_PositionChildren] for requirements and definitions.
  ///
  /// Implementation detail:
  ///   - The processing is calling the [LayedoutLengthsPositioner.positionLengths], method.
  ///   - There are two instances of the [LayedoutLengthsPositioner] created, one
  ///     for the [mainLayoutAxis] (using the [mainAxisLayoutProperties]),
  ///     another and for axis perpendicular to [mainLayoutAxis] (using the [crossAxisLayoutProperties]).
  ///   - Both main and cross axis properties are members of this [RollingBoxLayouter].
  ///   - The offset on each notGreedyChild element is calculated using the [mainAxisLayoutProperties]
  ///     in the main axis direction, and the [crossAxisLayoutProperties] in the cross axis direction.
  @override
  List<ui.Rect> layout_Post_NotLeaf_PositionChildren(List<LayoutableBox> children) {
    /*
      if (isLeaf) {
      return [];
    }
    */

    return _MainAndCrossPositionedSegments(
      parentBoxLayouter: this,
      parentConstraints: constraints,
      children: children,
      mainAxisLayoutProperties: mainAxisLayoutProperties,
      crossAxisLayoutProperties: crossAxisLayoutProperties,
      mainLayoutAxis: mainLayoutAxis,
    ).asRectangles();
  }

  /// Specific for [RollingBoxLayouter.layout], finds constraints remaining for [Greedy] children,
  /// and applies them on [Greedy] the children.
  ///
  /// This post descend is called after NonGreedy children, are layed out, and their [layoutSize]s known.
  ///
  /// In some detail,
  ///   - finds the constraint on self that remains after NonGreedy are given the (non greedy) space they want
  ///   - divides the remaining constraints into smaller constraints for all Greedy children in the greedy ratio
  ///   - applies the smaller constraints on Greedy children.
  ///
  /// This is required before we can layout Greedy children.
  void _layout_Rolling_Post_NonGreedy_FindConstraintRemainingAfterNonGreedy_DivideIt_And_ApplyOnGreedy() {
    // Note: non greedy children have layout size when we reach here

    if (_hasGreedy) {

      // Get the NonGreedy [layoutSize](s), call this layouter layout method,
      // which returns [positionedRectsInMe] rectangles relative to self where children should be positioned.
      // We create [nonGreedyBoundingRect] that envelope the NonGreedy children, tightly layed out
      // in the Column/Row direction. This is effectively a pre-positioning of children is self
      List<ui.Rect> positionedRectsInMe = layout_Post_NotLeaf_PositionChildren(_nonGreedyChildren);
      ui.Rect nonGreedyBoundingRect = util_flutter.boundingRectOfRects(positionedRectsInMe);
      assert(nonGreedyBoundingRect.topLeft == ui.Offset.zero);

      // Create new constraints ~constraintsRemainingForGreedy~ which is a difference between
      //   self original constraints, and  [nonGreedyBoundingRect] size
      BoxContainerConstraints constraintsRemainingForGreedy = constraints.deflateWithSize(nonGreedyBoundingRect.size);

      // Weight-divide [constraintsRemainingForGreedy] into the ratios greed / sum(greed),
      //   creating [greedyChildrenConstraints].
      List<BoundingBoxesBase> greedyChildrenConstraints = constraintsRemainingForGreedy.divideUsingStrategy(
        divideIntoCount: _greedyChildren.length,
        divideStrategy: ConstraintsDistribution.intWeights,
        layoutAxis: mainLayoutAxis,
        intWeights: _greedyChildren.map((child) => child.greed).toList(),
      );

      // Apply on greedyChildren their newly weight-divided greedyChildrenConstraints
      assert(greedyChildrenConstraints.length == _greedyChildren.length);
      for (int i = 0; i < _greedyChildren.length; i++) {
        Greedy greedyChild = _greedyChildren[i];
        BoxContainerConstraints childConstraint = greedyChildrenConstraints[i] as BoxContainerConstraints;
        greedyChild.applyParentConstraints(this, childConstraint);
      }
    }
  }

  List<Greedy> get _greedyChildren => _children.whereType<Greedy>().toList();

  List<LayoutableBox> get _nonGreedyChildren {
    List<BoxContainer> nonGreedy = List.from(_children);
    nonGreedy.removeWhere((var child) => child is Greedy);
    return nonGreedy;
  }

  bool get _hasGreedy => _greedyChildren.isNotEmpty;

  bool get _hasNonGreedy => _nonGreedyChildren.isNotEmpty;

}

/// Layouter lays out children in a rolling row, which may overflow if there are too many or too large children.
class Row extends RollingBoxLayouter {
  Row({
    required List<BoxContainer> children,
    Align mainAxisAlign = Align.start,
    Packing mainAxisPacking = Packing.tight,
    Align crossAxisAlign = Align.center,
    Packing crossAxisPacking = Packing.matrjoska,
    ConstraintsWeight mainAxisConstraintsWeight = ConstraintsWeight.defaultWeight,
  }) : super(
    children: children,
    mainAxisAlign: mainAxisAlign,
    mainAxisPacking: mainAxisPacking,
    crossAxisAlign: crossAxisAlign,
    crossAxisPacking: crossAxisPacking,
    mainAxisConstraintsWeight: mainAxisConstraintsWeight,
  ) {
    // Fields declared in mixin portion of BoxContainer cannot be initialized in initializer,
    //   but in constructor here.
    // Important: As a result, mixin fields can still be final, bust must be late, as they are
    //   always initialized in concrete implementations.
    mainLayoutAxis = LayoutAxis.horizontal;
    mainAxisLayoutProperties = LengthsPositionerProperties(
      align: mainAxisAlign,
      packing: mainAxisPacking,
    );
    crossAxisLayoutProperties = LengthsPositionerProperties(
      align: crossAxisAlign,
      packing: crossAxisPacking,
    );
  }
}

/// Layouter lays out children in a column that keeps extending,
/// which may overflow if there are too many or too large children.
class Column extends RollingBoxLayouter {
  Column({
    required List<BoxContainer> children,
    Align mainAxisAlign = Align.start,
    Packing mainAxisPacking = Packing.tight,
    Align crossAxisAlign = Align.start,
    Packing crossAxisPacking = Packing.matrjoska,
    ConstraintsWeight mainAxisConstraintsWeight = ConstraintsWeight.defaultWeight,
  }) : super(
    children: children,
    mainAxisAlign: mainAxisAlign,
    mainAxisPacking: mainAxisPacking,
    crossAxisAlign: crossAxisAlign,
    crossAxisPacking: crossAxisPacking,
    mainAxisConstraintsWeight: mainAxisConstraintsWeight,
  ) {
    mainLayoutAxis = LayoutAxis.vertical;
    mainAxisLayoutProperties = LengthsPositionerProperties(
      align: mainAxisAlign,
      packing: mainAxisPacking,
    );
    crossAxisLayoutProperties = LengthsPositionerProperties(
      align: crossAxisAlign,
      packing: crossAxisPacking,
    );
  }
}

/// Layouter which positions it's children to a externally passed grid along the
/// main axis.
///
/// The 1D points on the grid are referred to as 'ticks'.
///
/// Extends the [MainAndCrossAxisBoxLayouter] from which it gains and keeps the concept of main and cross axis,
/// using a rolling one-row (or one-column) [Packing] layout along the main axis, and a [Packing] layout
/// within the one-row (or one-column) along the cross axis.
///
/// It is similar to [RollingBoxLayouter], but has a very different layout, so it is made to be  a sibling
/// class to it.
///
/// Importantly, it differs in the [layout] method from the [RollingBoxLayouter], in using
/// a different constraints distribution to children, and a different order of children [layout]
/// (in [RollingBoxLayouter] it is non-greedy first, greedy last, on this derived class
/// it is just in order of the ticks)
///
/// See comments in [layout_Post_NotLeaf_PositionChildren] for comments on core goals
/// of this class [layout] method and how it differs from it's base and sibling classes.
///
abstract class ExternalTicksBoxLayouter extends MainAndCrossAxisBoxLayouter {
  ExternalTicksBoxLayouter({
    required List<BoxContainer> children,
    required Align mainAxisAlign,
    // mainAxisPacking not allowed to be set, positions provided by external ticks: required Packing mainAxisPacking,
    required Align crossAxisAlign,
    required Packing crossAxisPacking,
    // External ticks layouter: weights make no sense.
    // If anything, weights could be generated from ticks, if asked by an argument.
    //   ConstraintsWeight mainAxisConstraintsWeight = ConstraintsWeight.defaultWeight,
    required ExternalTicksLayoutProvider mainAxisExternalTicksLayoutProvider,
    this.isDistributeConstraintsBasedOnTickSpacing = false,
  }) : super(
    children                  : children,
    mainAxisAlign             : mainAxisAlign,
    mainAxisPacking           : Packing.externalTicksProvided,
    crossAxisAlign            : crossAxisAlign,
    crossAxisPacking          : crossAxisPacking,
    mainAxisConstraintsWeight : ConstraintsWeight.defaultWeight,
  )
  {
    // mainLayoutAxis = LayoutAxis.vertical;
    mainAxisLayoutProperties = LengthsPositionerProperties(
      align: mainAxisAlign,
      packing: Packing.externalTicksProvided,
      externalTicksLayoutProvider: mainAxisExternalTicksLayoutProvider,
    );
    crossAxisLayoutProperties = LengthsPositionerProperties(
      align: crossAxisAlign,
      packing: crossAxisPacking,
    );
    if (isDistributeConstraintsBasedOnTickSpacing) {
      throw StateError('Not implemented yet. Difficult design decisions how to calculate children sizes '
          'from tick spacing, due to the ');
    }
  }

  final bool isDistributeConstraintsBasedOnTickSpacing;

  /// Overridden implementation of the abstract method which positions the invoker's children using
  /// two 1D positioners wrapped in class [_MainAndCrossPositionedSegments].
  ///
  /// The main goal of this layouter 's [layout] is to allow:
  ///
  /// - set [layoutSize] to full constraint size in main axis direction (NOT
  ///   just outer envelope of children)
  /// - before positioning children in [_MainAndCrossPositionedSegments], the
  ///   [ExternalTicksLayoutProvider.tickPixelsDomain] must be set to the full constraints size in main
  ///   axis direction (the full constraints size will become layoutSize in that direction, per point above).
  ///
  /// See [BoxLayouter.layout_Post_NotLeaf_PositionChildren] for more requirements and definitions.
  ///
  /// Implementation detail:
  ///   - Note: With it's class-hierarchy sibling, the [RollingBoxLayouter] this method shares the core
  ///           of children positioning, where the children's rectangles using two 1D positioners wrapped
  ///           in [_MainAndCrossPositionedSegments.asRectangles] . But it differs in that this tick layout
  ///           is greedy in the main axis direction.
  ///   - The algorithm invokes the [LayedoutLengthsPositioner.positionLengths], method.
  @override
  List<ui.Rect> layout_Post_NotLeaf_PositionChildren(List<LayoutableBox> children) {
    // if (isLeaf) { return []; }

    if (mainAxisLayoutProperties.externalTicksLayoutProvider == null) {
      throw StateError('externalTicksLayoutProvider is null');
    }
    // External ticks layouter is greedy along the main axis - MUST take full constraints along main axis direction.
    // Along main axis direction:
    //   - the constraints are ALSO the pixel domain to which the ticks will be lextr-ed!
    //   - the constraints will ALSO become the layout size! See [_layout_Post_NotLeaf_SetSize_FromPositionedChildren]
    //     for how the layoutSize is set
    double lengthAlongMainAxis = constraints.maxLengthAlongAxis(mainLayoutAxis);
    // So, knowing the size to which to lextr, create the range to which the [externalTicksLayoutProvider]
    //   will be lextr-ed, apply the pixel domain on the [externalTicksLayoutProvider], and lextr the ticks to pixels.
    var tickPixelsDomainFromOwnerConstraints = util_dart.Interval(0.0, lengthAlongMainAxis);
    mainAxisLayoutProperties.externalTicksLayoutProvider!.setTickPixelsDomainAndLextr(tickPixelsDomainFromOwnerConstraints);

    // The set ticks pixel domain to which to lextr, and the ticks lextr MUST be done before layout (positioning) below,
    //   as the positioning works on pixels. ACTUALLY: The ticks pixel domain MUST be set, lextr could
    //   be done after positioning.
    return _MainAndCrossPositionedSegments(
      parentBoxLayouter: this,
      parentConstraints: constraints,
      children: children,
      mainAxisLayoutProperties: mainAxisLayoutProperties,
      crossAxisLayoutProperties: crossAxisLayoutProperties,
      mainLayoutAxis: mainLayoutAxis,
    ).asRectangles();
  }

  /// Sets layoutSize from full constraint in the main axis direction, from OuterRect in cross axis direction.
  ///
  /// See [layout_Post_NotLeaf_PositionChildren] for description of overall [layout] goals.
  @override
  void _layout_Post_NotLeaf_SetSize_FromPositionedChildren(List<ui.Rect> positionedChildrenRects) {

    ui.Rect positionedChildrenOuterRect = util_flutter
        .boundingRectOfRects(positionedChildrenRects.map((ui.Rect childRect) => childRect).toList(growable: false));

    __layout_Post_Assert_Layedout_Rects(positionedChildrenRects, positionedChildrenOuterRect);

    // Set [layoutSize] in main axis direction to full constraints,
    //       in the cross direction set layoutSize to the bounding rectangle

    layoutSize = constraints.size.fromMySideAlongPassedAxisOtherSideAlongCrossAxis(
      other: positionedChildrenOuterRect.size,
      axis: mainLayoutAxis,
    );
  }

}

class ExternalTicksRow extends ExternalTicksBoxLayouter {
  ExternalTicksRow({
    required List<BoxContainer> children,
    Align mainAxisAlign = Align.start,
    // mainAxisPacking not set, positions provided by external ticks: Packing mainAxisPacking = Packing.tight,
    Align crossAxisAlign = Align.center,
    Packing crossAxisPacking = Packing.matrjoska,
    // ConstraintsWeight mainAxisConstraintsWeight = ConstraintsWeight.defaultWeight,
    required ExternalTicksLayoutProvider mainAxisExternalTicksLayoutProvider,
  }) : super(
    children: children,
    mainAxisAlign: mainAxisAlign,
    // done in super : mainAxisPacking: Packing.externalTicksProvided,
    crossAxisAlign: crossAxisAlign,
    crossAxisPacking: crossAxisPacking,
    mainAxisExternalTicksLayoutProvider: mainAxisExternalTicksLayoutProvider,

    // mainAxisConstraintsWeight: mainAxisConstraintsWeight,
  ) {
    mainLayoutAxis = LayoutAxis.horizontal;
  }
}

class ExternalTicksColumn extends ExternalTicksBoxLayouter {
  ExternalTicksColumn({
    required List<BoxContainer> children,
    // todo-00!! provide some way to express that for ExternalRollingTicks, Both Align and Packing should be Packing.externalTicksDefined.
    Align mainAxisAlign = Align.start,
    // mainAxisPacking not allowed to be set, positions provided by external ticks: Packing mainAxisPacking = Packing.tight,
    Align crossAxisAlign = Align.start,
    Packing crossAxisPacking = Packing.matrjoska,
    // ConstraintsWeight mainAxisConstraintsWeight = ConstraintsWeight.defaultWeight,
    required ExternalTicksLayoutProvider mainAxisExternalTicksLayoutProvider,
  }) : super(
    children: children,
    mainAxisAlign: mainAxisAlign,
    // done in super : mainAxisPacking: Packing.externalTicksProvided,
    crossAxisAlign: crossAxisAlign,
    crossAxisPacking: crossAxisPacking,
    mainAxisExternalTicksLayoutProvider: mainAxisExternalTicksLayoutProvider,

    // mainAxisConstraintsWeight: mainAxisConstraintsWeight,
  ) {
    mainLayoutAxis = LayoutAxis.vertical;
  }
}

// --------------------------- vvvvvvvvvv Table

/// If used on [TableLayoutDefiner], it aligns the table cells 'packed towards middle' as much as possible.
///
/// The intended use is in situations where the [TableLayout] should layout Flutter Charts.
/// In charts context, the X axis, Y axis, and data container should be aligned so the pack tight without spacing
/// between them.
///
/// This class allows to define cells alignment to achieve that, for a limited number of rows and cells..
///
/// All cells are aligned as follows:
/// ```
///   - Top    (Start)    Row,   push down  -  cell vertical align = End
///   - Middle (Center)   Row    center     -  cell vertical align = Center (IF Middle row EXISTS, only for 3 ROWS)
///   - Bottom (End)      Row,   push up    -  cell vertical align = Start
///   - Start             Column, push right - cell horizontal align = End
///   - Middle (Center)   Column, center     - cell horizontal align = Center (IF Middle col EXISTS, only for 3 COLUMNS)
///   - End               Column, push left  - cell horizontal align = Start
/// ```
///
/// Note: If there is only 1 row, it is considered end (bottom), if there is only 1 column, it is considered end.
///
class ChartTableLayoutCellsAlignerDefiner {
  ChartTableLayoutCellsAlignerDefiner({
    required this.numRows,
    required this.numColumns,
  }) : assert (0 < numRows && numRows <= 3 && 0 < numColumns && numColumns <= 3);

  ChartTableLayoutCellsAlignerDefiner.sizeOf({
    required List<List<TableLayoutCellDefiner>> cellDefinersTable,
  })  : numRows = cellDefinersTable.length,
        numColumns = cellDefinersTable.isNotEmpty ? cellDefinersTable[0].length : 0 {
    assert(0 < numRows && numRows <= 3 && 0 < numColumns && numColumns <= 3);
  }

  final int numRows;
  final int numColumns;

  bool isStart(int rowOrCol, int numRowsOrCols) {
    return numRowsOrCols >= 2 && rowOrCol == 0;
  }
  bool isMiddle(int rowOrCol, int numRowsOrCols) {
    return numRowsOrCols == 3 && rowOrCol == 1;
  }
  bool isEnd(int rowOrCol, int numRowsOrCols) {
    return rowOrCol == numRowsOrCols - 1;
  }

  /// All outside cells are aligned as follows:
  ///   - Top    (Start)    Row,   push down  -  vertical align = End
  ///   - Middle (Center)   Row    center     -  vertical align = Center (IF Middle row EXISTS, ONLY 3 ROWS or 1 ROW)
  ///   - Bottom (End)      Row,   push up    -  vertical align = Start
  ///   - Start             Column, push right - horizontal align = End
  ///   - Middle (Center)   Column, center     - horizontal align = Center (IF Middle column EXISTS, ONLY 3 COLUMNS)
  ///   - End               Column, push left  - horizontal align = Start
  Align alignFor(int rowOrCol, int numRowsOrCols) {
    if (isStart(rowOrCol, numRowsOrCols)) {
      return Align.end;
    } else if (isMiddle(rowOrCol, numRowsOrCols)) {
      return Align.center;
    } else if (isEnd(rowOrCol, numRowsOrCols)) {
      return Align.start;
    } else {
      throw StateError('Internal error: no alignment for rowOrCol=$rowOrCol, numRowsOrCols=$numRowsOrCols');
    }
  }
  
  /*
  void _validate(int row, int column) {
    if (row >= numRows)       throw StateError('row $row >= numRows $numRows: pass row < numRows');
    if (column >= numColumns) throw StateError('column $column >= numColumns $numColumns: pass column < numColumns');
  }
  */

}

/// Manages one cell layed out by the [TableLayouter].
///
/// Exists for the benefit of the [TableLayouter], during it's [TableLayouter.layout],
/// to allow child iteration in user-defined sequence [layoutSequence]
/// and creation of constraints for the next cell in layout sequence.
///
class TableLayoutCellDefiner {

  TableLayoutCellDefiner({
    required this.layoutSequence,
    this.horizontalAlign,
    this.verticalAlign,
    this.cellConstraints,
    this.cellMinSizer,
  });
  // Members

  final int layoutSequence;
  bool isLayoutOverflown = false;
  late final int row;
  late final int column;

  /// If remains null after construction, the [TableLayouter] is responsible for setting a value.
  Align? horizontalAlign;
  Align? verticalAlign;

  // Late final constraints, can be pre-set by client OR set during [layout],
  // this is especially useful for the first layed out: e.g. YContainer,
  // can set height up to 3/4 parent height, BUT IF DONE LIKE THIS,
  // THE ChartRootContainer AND the TableLayouter must add children in build,
  // because only then TableLayouter has constraints set!!!
  /// If set, expresses constraints on the member [cellContainer].
  ///
  /// To enforce a [BoxLayouter.layoutSize] constraint on the ember [cellContainer].
  /// they should be set by the client on creation of this instance.
  /// If not set by user, they should be calculated and set during layout.
  BoxContainerConstraints? cellConstraints;

  /// If set, expresses a minimum [layoutSize] on the member [cellContainer].
  ///
  /// In a way this represents and provides 'minimum constraints'.
  ///
  /// The important role of a cell definer which has a non null [cellMinSizer],
  /// is that, during the [TableLayouter.layout] it behaves as if if the cell was layed out to the min size,
  /// even if it is not. That causes all other cells (notably the first cell in layout sequence) to
  /// receive smaller constraints.
  late final TableLayoutCellMinSizer? cellMinSizer;

  bool get isHasCellMinSizer => cellMinSizer != null;

  /// Tracks if the [cellContainer] invoked [layout];
  /// is set to true after [cellContainer] invokes [BoxContainer.layout].
  bool isAlreadyLayedOut = false;

  bool get isAlreadyLayedOutOrHasCellMinSizer => isAlreadyLayedOut || isHasCellMinSizer;

  /// Minimum size which the table cell at [row] and [column] (which contains the [cellContainer]) should
  /// announce to the [TableLayouter] during the [TableLayouter.layout].
  ///
  /// Must be called on this [TableLayoutCellDefiner] only if
  ///   - either the container this cell is either layed out ([isAlreadyLayedOut] is true)
  ///   - or this cell has a non null [TableLayoutCellMinSizer] ([isHasCellMinSizer] is true).
  ///   (above conditions unified in [isAlreadyLayedOutOrHasCellMinSizer] is true)
  ///
  /// Invoked both:
  ///   1. During [TableLayouter.layout] Descend step,
  ///        in [__layout_descend_calculate_remaining_non_layedout_constraints_on_cell], where
  ///        it may be invoked repeatedly both before this cell is layed out, or after.
  ///   2. During the [TableLayouter.layout] Post step.
  ///
  /// Details of the invocation results:
  ///   1. In the Descend step, it can ONLY be called if this cell is layed out or has it cell sizer non null (see above)
  ///         1.1. Lifecycle before the [cellContainer] is layed out: the [TableLayoutCellMinSizer.minCellSize] along the dimensions
  ///              where the [TableLayoutCellMinSizer.minCellSize] is defined (this could be 0.0 along one dimension)
  ///         1.2. Lifecycle after the [cellContainer] is layed out: envelope of the above size
  ///              with [cellContainer.layoutSize].
  ///   2.  In the Post step, it is called on each cell (because it is layed out, see above) returns the same as 1.2.
  ///       if this cell has MinSizer, returns [layoutSize] otherwise.
  ///
  /// The above logic under different conditions guarantees that the result [Size],
  /// for cells that specify [cellMinSizer]:
  ///   - along the direction(s) where [TableLayoutCellMinSizer] IS defined: yields the same result before
  ///     and after the cell container is layed out (that is, both before and after layout, the min size)
  ///   - along the direction(s) where [TableLayoutCellMinSizer] IS NOT defined: yields workflow consistent results
  ///     with [TableLayoutCellDefiner] cells that do NOT specify [cellMinSizer]
  ///     (that is : before layout -  effectively 0.0 as it is not called, after layout - [layoutSize]).
  ///
  ui.Size minSizeOrLayoutSize({
    required BoxContainerConstraints? tableConstraints,
  }) {
    assert(isAlreadyLayedOutOrHasCellMinSizer == true);

    // A difficult decision, what should have precedence.
    // Basically, during layoutDescend, in the loop where some cells are layed out and some are not,
    // we first use the isHasCellMinSizer if it is defined, to always get the bigger size, else use layoutSize.
    //  (if neither exists, this should NOT be called at layoutDescend.
    // Later, during PostDescend, layoutSize already exists.
    // Here, to calculate row heights, and column widths, also use the bigger size,
    // but enveloped with the layoutSize. Cells wit no MinSizer, use layoutSize.

    if (isHasCellMinSizer) {
      ui.Size minCellSize = cellMinSizer!.minCellSize(
        tableConstraints: tableConstraints,
      );
      if (isAlreadyLayedOut) {
        return minCellSize.envelope([cellContainer.layoutSize]);
      }
      return minCellSize;
    } else if (isAlreadyLayedOut) {
      return cellContainer.layoutSize;
    } else {
      throw StateError('Must be called when isAlreadyLayedOut || isHasCellMinSizer is true');
    }
  }

  /// The [BoxContainer] cell child of the [TableLayouter] which layout order is
  /// defined by this [TableLayoutCellDefiner] instance.
  ///
  /// There is exactly one, because the cell definers 2D array [TableLayoutDefiner.cellDefinersTable]
  /// is same size as the table cells array [TableLayouter.cellsTable] which is layed out.
  late final BoxContainer cellContainer;

  // null means last
  late TableLayoutCellDefiner? nextCellDefinerInLayoutSequence;
}

/// Represents a minimum Size of a cell in [TableLayout].
///
/// By 'minimum Size of a cell in [TableLayout]' we mean that from the beginning of the [layout]
/// process in [TableLayout] the algorithm assumes the [BoxContainer] in the cell will have
/// at least the minimum Size. The side-effect of this fact is important: From the beginning of the [layout],
/// all other cells being layed out are given (smaller) constraints, assuming the 'minimum size of one cell'
/// is taken away.
///
/// todo-00-doc fix docs
/// The method by which the minimum Size is defined can be one of:
///   - providing minimum width and height for the cell
/// or a [BoxContainer] which produces constraints upon a 'test layout' for
/// a cell in [TableLayouter] - that is, minimum constraints for the cell defined by [TableLayoutCellDefiner].
/// todo-00-doc NO: with sequence [TableLayoutCellDefiner.layoutSequence] equal to zero.
///
/// Part of [TableLayoutDefiner], which will ensure the provided constraint
///
/// Motivation: During table layout, we often need to set a minimum size of a row
///             or a column - row width or column height, or both.
///             This class helps to express this need, either by specifying a minimum size directly,
///             or asking a [BoxContainer] to layout and use it's [layoutSize] as the minimum size.
/// How is this motivation implemented?  todo-00-doc
///
class TableLayoutCellMinSizer {
  TableLayoutCellMinSizer.fromMinima({
    //required this.attachedToLayoutSequence,
    required this.cellWidthMinimum,
    required this.cellHeightMinimum,
  })  : __isUseCellMinimum = true,
        __isUseTablePortion = false,
        __isUsePreLayout = false,
        isUseWidth = true,
        isUseHeight = true;

  TableLayoutCellMinSizer.fromPortionOfTableConstraint({
    //required this.attachedToLayoutSequence,
    required this.tableWidthPortion,
    required this.tableHeightPortion,
  })  : __isUseCellMinimum = false,
        __isUseTablePortion = true,
        __isUsePreLayout = false,
        isUseWidth = true,
        isUseHeight = true;

  TableLayoutCellMinSizer.fromCellPreLayout({
    //required this.attachedToLayoutSequence,
    required this.preLayoutCellToGainMinima,
    this.isUseWidth = true,
    this.isUseHeight = true,
  })  : __isUseCellMinimum = false,
        __isUseTablePortion = false,
        __isUsePreLayout = true;

  /// Exists to remove need for nulling instances when no minimizing sizer is used.
  TableLayoutCellMinSizer.none()
      : // attachedToLayoutSequence = 0,
        cellWidthMinimum = 0.0,
        cellHeightMinimum = 0.0,
        __isUseCellMinimum = false,
        __isUseTablePortion = false,
        __isUsePreLayout = false,
        isUseWidth = false,
        isUseHeight = false;

  /// The cell's [TableLayoutCellDefiner.layoutSequence] to which is this size-minimizing sizer attached.
  // final int attachedToLayoutSequence;

  late final double cellWidthMinimum;
  late final double cellHeightMinimum;
  late final double tableWidthPortion; // between 0.0 and 1.0
  late final double tableHeightPortion;
  /// If not null, must be prepared with constraints applied
  late final BoxContainer? preLayoutCellToGainMinima;
  late final bool isUseWidth;
  late final bool isUseHeight;

  // BoxContainerConstraints? preLayoutCellConstraints;
  BoxContainerConstraints? tableConstraints;

  /// Indicates which method to use to gain Minima,
  /// without having to query any late finals
  /// (as it is always a bad thing to query late final).
  late final bool __isUseCellMinimum;
  late final bool __isUseTablePortion;
  late final bool __isUsePreLayout;

  late final ui.Size __minLayoutSizeCached;
  bool __isMinLayoutSizeCached = false;

  ui.Size minCellSize({
    // required BoxContainerConstraints? preLayoutCellConstraints,
    required BoxContainerConstraints? tableConstraints,
  }) {
    if (__isMinLayoutSizeCached
        // && preLayoutCellConstraints == this.preLayoutCellConstraints
        && tableConstraints == this.tableConstraints
    ) {
      return __minLayoutSizeCached;
    }

    // this.preLayoutCellConstraints = preLayoutCellConstraints;
    this.tableConstraints = tableConstraints;
    ui.Size enforcedMinLayoutSize;

    if (__isUseCellMinimum) {
      enforcedMinLayoutSize = ui.Size(cellWidthMinimum, cellHeightMinimum);
    } else if (__isUseTablePortion) {
      assert (tableConstraints != null);
      enforcedMinLayoutSize = tableConstraints!.multiplySidesBy(ui.Size(tableWidthPortion, tableHeightPortion)).size;
    } else if (__isUsePreLayout) {
      assert(preLayoutCellToGainMinima != null);
      // todo-00! : parent == this will fail. Maybe allow apply to ignore.
      // preLayoutCellToGainMinima.applyParentConstraints(preLayoutCellToGainMinima as LayoutableBox, preLayoutCellConstraints!);
      preLayoutCellToGainMinima!.layout();
      enforcedMinLayoutSize = preLayoutCellToGainMinima!.layoutSize;
    } else {
      throw StateError('Invalid state.');
    }
    __isMinLayoutSizeCached = true;

    double width = 0.0;
    double height = 0.0;
    if (isUseWidth) width = enforcedMinLayoutSize.width;
    if (isUseHeight) height = enforcedMinLayoutSize.height;

    __minLayoutSizeCached = ui.Size(width, height);
    __isMinLayoutSizeCached = true;

    return __minLayoutSizeCached;
  }
}

/// Manages [TableLayoutCellDefiner]s for TableLayouter during layout.
///
/// Each instance requires validation of correctness, such as all rows must be the same length.
/// Validation is performed by [], but it should be called late, in the [TableLayouter] constructor
/// where the instance is passed to [TableLayouter] along with [TableLayouter.cellsTable], and both
/// should be validated and cross-validated for being the same format (number of rows and columns etc).
class TableLayoutDefiner {
  
  TableLayoutDefiner({
    required this.cellDefinersTable,
    this.horizontalAlign = Align.center,
    this.verticalAlign = Align.center,
    this.cellsAlignerDefiner,
  }) :
        numRows = cellDefinersTable.length,
        numColumns = cellDefinersTable.isNotEmpty ? cellDefinersTable.length : 0;

  /// Default creates an instance which [layoutSequence] follows the normal 'top to bottom, left to right'
  /// processing of cells, that is, row 1 columns from the left, then wraps to row 2,
  /// and repeats.
  ///
  /// The [cellDefinersTable] cell at position `row`, `column` receive [TableLayoutCellDefiner.layoutSequence]
  ///   `row * numColumns + column`.
  ///
  TableLayoutDefiner.defaultRowWiseForTableSize({
    required this.numRows,
    required this.numColumns,
    this.horizontalAlign = Align.center,
    this.verticalAlign = Align.center,
    this.cellsAlignerDefiner,
  }) : cellDefinersTable =
            List.generate(
              numRows,
              (int row) => List.generate(
                numColumns,
                (int column) => TableLayoutCellDefiner(
                layoutSequence: row * numColumns + column,
                // horizontalAlign: horizontalAlign,
                // verticalAlign: verticalAlign,
                // cellConstraints: null,
              ),
            ));

  /// Holds the 2D table of [TableLayoutCellDefiner]s.
  ///
  /// Each item in this table corresponds to one cell in the table which is being layed out.
  final List<List<TableLayoutCellDefiner>> cellDefinersTable;

  /// Caches number of rows in [cellDefinersTable].
  final int numRows;
  /// Caches number of rows in [cellDefinersTable].
  final int numColumns;

  /// Answers [true] if this [TableLayoutDefiner] has no cell definers in []
  late final bool isEmpty;
  late final bool isNotEmpty = !isEmpty;

  /// Should be set to the hierarchy-parent of the [TableLayouter],
  /// which this [TableLayoutDefiner] manages.
  late final BoxContainer tableLayouterContainer;

  final Align horizontalAlign;
  final Align verticalAlign;
  /// If not null, overrides alignment that may be set on individual cells, and also
  /// alignment set on this definer in [horizontalAlign] and [verticalAlign].
  final ChartTableLayoutCellsAlignerDefiner? cellsAlignerDefiner;

  /// [_cachedFlatCellDefiners] and [_isFlatCellDefinersCached] supports 
  /// fast access to [flatCellDefiners].
  late final Iterable<TableLayoutCellDefiner> _cachedFlatCellDefiners;
  bool _isFlatCellDefinersCached = false;
  /// Returns an unordered Iterable of cell definers.
  ///
  /// The 1D iterable is derived from the cell definers 2D table [cellDefinersTable].
  Iterable<TableLayoutCellDefiner> get flatCellDefiners {
    if (_isFlatCellDefinersCached) return _cachedFlatCellDefiners;
    _cachedFlatCellDefiners = cellDefinersTable.expand((element) => element);
    _isFlatCellDefinersCached = true;
    return _cachedFlatCellDefiners;
  }

  /// [_cachedFlatOrderedCellDefiners] and [_isFlatOrderedCellDefinersCached] supports 
  /// fast access to [flatCellDefiners].
  late final Iterable<TableLayoutCellDefiner> _cachedFlatOrderedCellDefiners;
  bool _isFlatOrderedCellDefinersCached = false;
  /// Returns an Iterable of cell definers, ordered by the user defined [TableLayoutCellDefiner.layoutSequence].
  ///
  /// The 1D iterable is derived from the cell definers 2D table [cellDefinersTable].
  Iterable<TableLayoutCellDefiner> get flatOrderedCellDefiners {
    if (_isFlatOrderedCellDefinersCached) return _cachedFlatOrderedCellDefiners;
    _cachedFlatOrderedCellDefiners = flatCellDefiners.toList()..sort((a, b) => a.layoutSequence - b.layoutSequence);
    _isFlatOrderedCellDefinersCached = true;
    return _cachedFlatOrderedCellDefiners;
  }

  /// Finds TableLayoutCellDefiner on row, column
  /// todo-00!!!! optimize, find it in cellDefinersTable instead !!!!
  TableLayoutCellDefiner find_cellDefiner_on(row, column) =>
      flatCellDefiners.firstWhere(
              (cellDefiner) => cellDefiner.row == row && cellDefiner.column == column,
          orElse: () => throw StateError('No cell in this $this matching row=$row, column=$column'));

  /// Returns priority-order align for a row and column.
  ///
  /// The priority is:
  ///   - IF defined, first priority is the cell align level at [TableLayoutCellDefiner.verticalAlign],
  ///   - next is the [cellsAlignerDefiner]
  ///   - last is this instance's [TableLayoutDefiner.verticalAlign] which is guaranteed not null.
  ///   todo-00!!!! : unify to one method, alignInDirectionOnCell(AxisDirection direction (horiz or vert), row, column, but first,
  ///                  add on cellDefiner method alignInDirection(horizontal, vertical), return horizontalAlign or vertical align
  Align verticalAlignFor(int row, int column) {
    var cellDefiner = find_cellDefiner_on(row, column);
    if (cellDefiner.verticalAlign != null) {
      return cellDefiner.verticalAlign!;
    }
    if (cellsAlignerDefiner != null) {
      return cellsAlignerDefiner!.alignFor(row, numRows);
    }
    return verticalAlign;
  }

  Align horizontalAlignFor(int row, int column) {
    var cellDefiner = find_cellDefiner_on(row, column);
    if (cellDefiner.horizontalAlign != null) {
      return cellDefiner.horizontalAlign!;
    }
    if (cellsAlignerDefiner != null) {
      return cellsAlignerDefiner!.alignFor(column, numColumns);
    }
    return horizontalAlign;
  }

}

/// Lays out [BoxContainer]s in the passed [cellsTable] as a table.
///
/// The layout order is specified by the passed [tableLayoutDefiner].
///
/// Unlike [RollingBoxLayouter], each cell (child) in the [TableLayouter]
/// receives it's constraints just before it's layout is called.
/// The received constraints are calculated as a constraints from this layouter, deflated (decreased in size)
/// by the [layoutSize]s of all previously layed out children.
///
/// The last layed out cell is 'greedy' in the sense it can take all [TableLayouter.constraints] remaining after all
/// previous cells were layed out.
/// 
class TableLayouter extends PositioningBoxLayouter {

  TableLayouter({
    required this.cellsTable,
    required this.tableLayoutDefiner,
    this.horizontalAlign = Align.center,
    this.verticalAlign = Align.center,
  }) {

    tableLayoutDefiner.tableLayouterContainer = this;

    // Validate sameness of structure of 2D [cellsTable] and [tableLayoutDefiner]'s
    // 2D [TableLayoutDefiner.cellDefinersTable], then late init the [tableLayoutDefiner] members
    _crossValidateDefinerWithCellsAndLateInitDefiner();

    // Still have to add children, even though TableLayouter cheats and uses
    // cell definers instead of cells, so without children [layout] complains on isLeaf.
    addChildren(
        tableLayoutDefiner.flatOrderedCellDefiners.map((cellDefiner) => cellDefiner.cellContainer).toList());
  }

  /// Represents rows and columns of the children layed out by this [TableLayouter]
  final List<List<BoxContainer>> cellsTable;

  /// Describes the layout directives (sequence) of cells in the [cellsTable].
  ///
  /// Dependency:
  ///   1. [tableLayoutDefiner] depends on [cellsTable] in the sense that this [tableLayoutDefiner]
  ///      must be the same size as [cellsTable],
  ///   2. In addition, all [TableLayoutCellDefiner] in [TableLayoutDefiner.cellDefinersTable]
  ///      must have their [TableLayoutCellDefiner.layoutSequence], [TableLayoutCellDefiner.row],
  ///      [TableLayoutCellDefiner.column], set correctly to address all [BoxContainer] cells in the [cellsTable]
  ///
  final TableLayoutDefiner tableLayoutDefiner;

  final Align horizontalAlign;
  final Align verticalAlign;

  late final int numRows;
  late final int numColumns;
  /// Heights of rows after layout, is max of individual [layoutSize] of all children
  /// in that row.
  late final List<double> rowHeights;
  late final List<double> columnWidths;

  /// Validates that the structure of 2D [cellsTable] and [tableLayoutDefiner]'s
  /// 2D [TableLayoutDefiner.cellDefinersTable] is the same.
  ///
  /// Also late initializes the members in the passed [tableLayoutDefiner].
  ///
  /// In more detail, this method validates and/or sets on [cellsTable] and [tableLayoutDefiner] :
  /// - cross validates numRows and numColumns on both 2D arrays:
  ///   - Same numRows on both 2D arrays.
  ///   - Each row has the same same numColumns on both 2D arrays.
  /// - late initializes the members in the passed [tableLayoutDefiner].
  /// - late initializes [numRows] and [numColumns] on this [TableLayouter]
  _crossValidateDefinerWithCellsAndLateInitDefiner() {

    List<List<TableLayoutCellDefiner>> cellDefinersTable = tableLayoutDefiner.cellDefinersTable;

    if (cellDefinersTable.length != cellsTable.length) {
      throw StateError('cellDefinersTable $cellDefinersTable and cellsTable $cellsTable must be same length.');
    }

    // Check if this object is configured correctly
    Set<int> collectedSequences = {};

    // Pick one of the arrays and iterate it row-wise then column-wise,
    // always checking the structure is the same.
    //
    // Once structure is confirmed on a row and column, we can set values on definers
    // in [cellDefinersTable]
    for (int row = 0; row < cellDefinersTable.length; row++){

      List<TableLayoutCellDefiner>? prevDefinersRow;
      List<TableLayoutCellDefiner> currDefinersRow = cellDefinersTable[row];
      List<BoxContainer> currCellsRow = cellsTable[row];

      if (currDefinersRow.length != currCellsRow.length) {
        throw StateError('cellDefinersTable and cellsTable do NOT have same length in row=$row');
      }

      for (int column = 0; column < currDefinersRow.length; column++) {

        // Late initialize fields on current cell definer. currDefiner is at [row][column]
        TableLayoutCellDefiner currDefiner = currDefinersRow[column];
        BoxContainer currCell = currCellsRow[column];

        currDefiner.row = row;
        currDefiner.column = column;
        currDefiner.verticalAlign = tableLayoutDefiner.verticalAlignFor(row, column);
        currDefiner.horizontalAlign = tableLayoutDefiner.horizontalAlignFor(row, column);
        currDefiner.cellContainer = currCell;

        // Collect layoutSequences and make sure they go from 0 to numColumns * numRows
        collectedSequences.add(currDefiner.layoutSequence);

        // Validations all rows must have the same length - use previous
        if (prevDefinersRow != null) {
          if (prevDefinersRow.length != currDefinersRow.length) {
            throw StateError('All rows "cellsTable" and "tableLayoutDefiner.cellDefinersTable" must be same length, '
                'but one of them differs between rows ${row-1} and $row. ');
          }
        }

        // this column is now previous
        prevDefinersRow = currDefinersRow;
      }
    }

    // Late set two other 'global' members on [tableLayoutDefiner]
    tableLayoutDefiner.isEmpty = tableLayoutDefiner.numRows == 0 || tableLayoutDefiner.numColumns == 0;

    // Late set to the same values, number of rows and columns on this TableLayouter.
    numRows = tableLayoutDefiner.numRows;
    numColumns = tableLayoutDefiner.numColumns;

    // todo-00-later : Replace asserts with exceptions, and add better messages.
    assert(collectedSequences.length == tableLayoutDefiner.numRows * tableLayoutDefiner.numColumns);
    assert(collectedSequences.reduceOrElse(math.min, orElse: () => 0) == 0);
    assert(collectedSequences.reduceOrElse(math.max, orElse: () => 0) == tableLayoutDefiner.numRows * tableLayoutDefiner.numColumns - 1);
  }

  // ############################## Layout methods

  @override
  void _layout_TopRecurse() {
    // A. node-pre-descend; Overridden to do nothing
    _layout_Pre_DistributeConstraintsToImmediateChildren(_children);

    // B. node-descend: Overridden so that each child first sets constraints, then layouts, then next child, etc,
    //                  rather than setting constraints for all children ahead of time.
    //                  The constraints set on each child are 'cautiously optimistic', in the sense
    //                  they remove the space taken by children layed out before. That is why the order
    //                  of layout is important. Only the last child being layed out can get exact constraints.
    _layout_Descend();
    
    // C. node-post-descend.
    //    Here, children have layoutSizes, which are used to lay them out in me, then offset them in me
    _layout_Post_IfLeaf_SetSize_IfNotLeaf_PositionThenOffsetChildren_ThenSetSize_Finally_AssertSizeInsideConstraints();


  }

  /// Overridden with a no-op implementation.
  ///
  /// Reason: This [TableLayouter.layout] does not pre-distribute constraints to all [children],
  ///         but it sets each child constraint just before the child's [layout] is invoked,
  ///         by calculating constraints using [TableLayoutDefiner.__layout_descend_calculate_remaining_non_layedout_constraints_on_cell].
  @override
  void _layout_Pre_DistributeConstraintsToImmediateChildren(List<LayoutableBox> children) {}

  /// Descends to children: Lays out table children (table cell containers), one after another,
  /// in the layout order of their cell definer's sequence [TableLayoutCellDefiner.layoutSequence].
  ///
  /// The sequences for all cells are defined by the cell definers list in the [TableLayouter.tableLayoutDefiner]'s
  /// table [TableLayoutDefiner.cellDefinersTable].
  ///
  /// In each child iteration step, the algorithm:
  ///   - first creates cellConstraints on the table cell, giving each cell
  ///     the rest of available space (table constraints minus the space taken by children cells already layed out)
  ///   - applies the cellConstraints as parent constraints on the child
  ///   - invokes child [layout].
  ///
  /// The desired layout order sequence is achieved by iterating the [TableLayoutDefiner.flatOrderedCellDefiners]
  ///
  /// Overridden to not set constraints on all children all at once in
  ///   [_layout_Pre_DistributeConstraintsToImmediateChildren],
  ///   but to wait with calculating and setting constraints
  ///   just before each child layout.
  ///
  /// Important note:
  ///   - Children have been resequenced (ordered) in layout order requested by [TableLayoutDefiner].
  ///
  /// Implementation comment:
  ///   - Iterates table children (cells) by iterating the cell definers in [tableLayoutDefiner].
  ///     Because the [tableLayoutDefiner] was validated to define all cells, this guarantees
  ///       all table cells are iterated.
  ///     Further, the order of the descend layout
  ///       is in the order of the layout sequence order [TableLayoutDefiner.cellDefinersTable],
  ///       from [TableLayoutDefiner.flatOrderedCellDefiners]
  ///
  @override
  void _layout_Descend() {

    // Descends into children, not directly, but via the table's cell definers
    // which methods are needed to create constraints for the next cell.
    for (var cellDefiner in tableLayoutDefiner.flatOrderedCellDefiners) {

      //---  b1. child-pre-descend: Calculate constraints left over by previously
      //         layed out children, and set the calculated constraints on the child.

      // If cellConstraints ??= not null, they were set (presumed from the cellDefiner), then keep it,
      //   otherwise calculate from non-layout cells.
      // Layedout cell get 'cautiously optimistic' constraints = space left from this table's constraints,
      //   minus added [layoutSize] of previously layed out 'non-row, non-colum' cells.
      // Note that the last cell (cellDefiner == tableLayoutDefiner.flatOrderedCellDefiners.last),
      //   ALWAYS gets constraints exactly the size of space remaining after all previous layed out cells -
      //   this is by the nature of the [calculate_available_constraint_on_cell] algorithm :
      //     it return the table direction-constraint, minus the sum of layed out row heights (or column widths)
      cellDefiner.cellConstraints ??= __layout_descend_calculate_remaining_non_layedout_constraints_on_cell(
        cellDefiner.row,
        cellDefiner.column,
      );

      var child = cellDefiner.cellContainer;

      // Apply constraints on child just before layout
      child.applyParentConstraints(this, cellDefiner.cellConstraints!);

      // --- b2. child-descend: layout the child
      child.layout();

      // --- b3. child-post-descend: mark the cell definer that it's child container is layedout
      cellDefiner.isAlreadyLayedOut = true;
    }
  }

  BoxContainerConstraints __layout_descend_calculate_remaining_non_layedout_constraints_on_cell(int row, int column) {

    /// Inner function calculates the added width of all layed out columns except the passed [column].
    ///
    /// Motivation and reason for existence:
    ///   - Exists for the benefit of the [TableLayouter] owned by [tableLayouterContainer].
    ///   - The [TableLayouter], after a container corresponding to a [TableLayoutCellDefiner] was layed out, sets
    ///     the constraints on the container which is next in layout order.
    ///     The layouter wants to specify, how much space (constraints) is left over for the next container.
    ///     This method encapsulates the calculation, by looking at all already layed out cells,
    ///     and finding the used up size (sum of [BoxContainer.layoutSize]).
    double descend_used_layedout_width_except_column(int column) {
      if (tableLayoutDefiner.isEmpty) {
        return 0.0;
      }
      int transposedColumn = 0;
      return util_dart.transposeRowsToColumns(tableLayoutDefiner.cellDefinersTable) // columns list
          .where((definersColumn) {
        // cannot use in transposed : definersColumn[0].row != column
        bool include = transposedColumn != column;
        transposedColumn++;
        return include;
      }) // cut out current column : NOTE: When transposing, column and row is reversed
          .map((definersColumn) => definersColumn.where((cellDefiner) => cellDefiner.isAlreadyLayedOutOrHasCellMinSizer)) // each column keep only layed out cells
          .map((definersColumn) => definersColumn.map((cellDefiner) => cellDefiner.minSizeOrLayoutSize(tableConstraints: constraints).width)) // each column, instead of cells, put cellDefiner layout width
          .map((definersColumn) => definersColumn.reduceOrElse(math.max<double>, orElse: () => 0.0)) // each column, reduce to one number - max of layout width
          .fold(0.0, (value, element) => value + element);
    }

    /// Calculates the added height of all layed out rows except the passed [row].
    ///
    /// See [calculate_layedout_used_width_except_column].
    ///
    double descend_used_layedout_height_except_row(int row) {
      if (tableLayoutDefiner.isEmpty) {
        return 0.0;
      }
      // go over all columns except the passed, column-wise, only keep cells where cellDefiner.isAlreadyLayedOut
      // and column-wise, calculate max layout width
      // then sum for all columns.
      return tableLayoutDefiner.cellDefinersTable // rows list
          .where((definersRow) => definersRow[0].row != row) // cut out current row
          .map((definersRow) => definersRow.where((cellDefiner) => cellDefiner.isAlreadyLayedOutOrHasCellMinSizer)) // each row keep only layed out cells
          .map((definersRow) => definersRow.map((cellDefiner) => cellDefiner.minSizeOrLayoutSize(tableConstraints: constraints).height)) // each row, instead of cells, put cellDefiner layout height
          .map((definersRow) => definersRow.reduceOrElse(math.max<double>, orElse: () => 0.0)) // each row, reduce to one number - max of layout height
          .fold(0.0, (value, element) => value + element);
    }

    TableLayoutCellDefiner cellDefiner = tableLayoutDefiner.find_cellDefiner_on(row, column);
    if (cellDefiner.isAlreadyLayedOut) {
      StateError('Cell $runtimeType $this on row=$row, column=$column is already layed out.');
    }
    double availableWidth = constraints.width - descend_used_layedout_width_except_column(column);
    double availableHeight = constraints.height - descend_used_layedout_height_except_row(row);
    return BoxContainerConstraints.insideBox(size: Size(availableWidth, availableHeight));
  }

  /// This [TableLayouter] override creates table-positioned rectangles around each child,
  /// possibly with spacing around each child up to the table cell size.
  ///
  /// The table cell size is generally bigger than the child's [layoutSize].
  ///
  /// Each child's [layoutSize] is aligned in the table cell  according to each cell's layout properties
  /// defined by it's cell definer [TableLayoutCellDefiner]
  /// (located in the same row, column position of the [TableLayouter.tableLayoutDefiner]).
  ///
  /// In other implementations, such as [Column], all children are layed out at once, because all children
  /// have the same [mainAxisLayoutProperties] and [crossAxisLayoutProperties]
  /// given the [mainLayoutAxis].
  ///
  /// The above is not the case in this [TableLayouter]:
  ///   Here, in principle, each cell container has different
  ///   [mainAxisLayoutProperties] and [crossAxisLayoutProperties] given the [mainLayoutAxis].
  ///   This method creates rectangles one by one for each cell container, then
  ///   table-positions the rectangles within this [TableLayouter]'s [constraints].
  ///
  /// Note: Both Post processing methods in this [TableLayouter],
  ///       [layout_Post_NotLeaf_PositionChildren] and [_layout_Post_NotLeaf_OffsetChildren]
  ///       are overridden from the base [BoxLayouter]
  ///
  /// Implementation note: Iterates rows and columns, rather than using
  ///   [tableLayoutDefiner.flatOrderedCellDefiners] as in [_layout_Descend].
  ///   Here, the order does not matter, so rows and columns are more clear.
  @override
  List<ui.Rect> layout_Post_NotLeaf_PositionChildren(List<LayoutableBox> children) {
    /* keep
      if (isLeaf) {
      return [];
    }
    */
    // Ignoring the passed children, operate on all tableLayoutDefiner.cellDefinersTable.

    // As all cells are layed out when we reached here, we can use cells' [layoutSize]
    // to calculate and set the max widths and heights of each row and column.
    // This is precondition of being able to then place each [layoutSize]d cell
    // inside the bigger constraint calculated and max widths and heights in this method.
    __layout_Post_CalculateAndSetMaxRowsHeightsAndMaxColumnWidths();

    // Once we calculated the max row heights and max column widths,
    // needed to offset children in cell constraint,
    // position all children within table, cell by cell, row first (although order is not relevant)
    double internalHeightOffset = 0.0;
    double internalWidthOffset = 0.0;
    List<ui.Rect> positionedChildren = [];

    List<List<TableLayoutCellDefiner>> cellDefinersTable = tableLayoutDefiner.cellDefinersTable;

    // Position containers (children) in each cell by finding container offset
    // in cell *which is bigger than container, unless it's biggest container in row or column*,
    // then offset the whole cell by moving it to the position for table row and column
    for (int row = 0; row < cellDefinersTable.length; row++) {
      List<TableLayoutCellDefiner> definerRow = cellDefinersTable[row];
      internalWidthOffset = 0; // new row, start width on the left (0)

      for (int column = 0; column < definerRow.length; column++) {
        TableLayoutCellDefiner cellDefiner = definerRow[column];

        // Constraint for child container in the cell: cell constraint is from rowHeights columnWidths
        var cellWidthHeightAsConstraintForChild = BoxContainerConstraints.insideBox(
          size: Size(
            columnWidths[column],
            rowHeights[row],
          ),
        );

        // For each child separately, create layout properties from the cell definer,
        // and obtain it's rectangle.
        // We can consider main axis horizontal, but it does not matter for result,
        // as long as we pass the Align on the corresponding axis
        var mainAxisLayoutProperties = LengthsPositionerProperties(
          align: cellDefiner.horizontalAlign!,
          packing: Packing.tight, // todo-00-later Write a test. This should not matter for one child!
        );
        var crossAxisLayoutProperties = LengthsPositionerProperties(
          align: cellDefiner.verticalAlign!,
          packing: Packing.tight,
        );
        var mainLayoutAxis = LayoutAxis.horizontal;

        // Use the 1Dim Positioner on main and cross direction, to position
        // [cellDefiner.cellForThisDefiner] inside the cell constraint [cellWidthHeightAsConstraintForChild]
        ui.Rect positionedRect = _MainAndCrossPositionedSegments(
          parentBoxLayouter: this,
          // Position one length of the single cellForThisDefiner inside the cellSize according to layoutProperties
          parentConstraints: cellWidthHeightAsConstraintForChild,
          children: [cellDefiner.cellContainer],
          mainAxisLayoutProperties: mainAxisLayoutProperties,
          crossAxisLayoutProperties: crossAxisLayoutProperties,
          mainLayoutAxis: mainLayoutAxis,
        ).asRectangles().first;

        // Now offset the rectangle by the left-top position of the (row, column) cell being layedout.
        positionedRect = positionedRect.shift(ui.Offset(internalWidthOffset, internalHeightOffset));

        // And add to the returned children, as one list, from concatenated rows in the table.
        positionedChildren.add(positionedRect);

        // current column processed, move internal width by one cell
        internalWidthOffset += columnWidths[column];
      }
      // current row processed, move internal height by one row
      internalHeightOffset += rowHeights[row];
    }

    return positionedChildren;
  }

  /// Calculates and sets the max widths and heights of each row and column from cells' .[layoutSize]s.
  ///
  /// This is possible if, when called, all cells are layed out.
  ///
  /// This is a precondition of later processing in [layout_Post_NotLeaf_PositionChildren]
  /// to be able to then position each [layoutSize]d cell inside the bigger constraint
  /// calculated as max widths and heights in this method.
  __layout_Post_CalculateAndSetMaxRowsHeightsAndMaxColumnWidths() {

    // Calculate and set the member max row heights and max column widths,
    // needed to offset children cell in this layouter table cells.
    rowHeights = tableLayoutDefiner.cellDefinersTable
        .map((definersRow) => definersRow
        .map((definer) {
          if (!definer.isAlreadyLayedOutOrHasCellMinSizer) throw StateError('definer $definer not layed out');
          ui.Size minSizeOrLayoutSize = definer.minSizeOrLayoutSize(
            tableConstraints: constraints,
          );
          if (!definer.isLayoutOverflown) {
            return minSizeOrLayoutSize.height;
          }
          return math.min(minSizeOrLayoutSize.height, definer.cellContainer.constraints.height);
        })
        .reduceOrElse(math.max, orElse: () => 0.0))
        .toList();

    columnWidths = util_dart.transposeRowsToColumns(tableLayoutDefiner.cellDefinersTable)
        .map((definersColumn) => definersColumn
        .map((definer) {

          if (!definer.isAlreadyLayedOutOrHasCellMinSizer) throw StateError('definer $definer not layed out');
          ui.Size minSizeOrLayoutSize = definer.minSizeOrLayoutSize(
            tableConstraints: constraints,
          );
          if (!definer.isLayoutOverflown) {
            return minSizeOrLayoutSize.width;
          }
          return math.min(minSizeOrLayoutSize.width, definer.cellContainer.constraints.width);
        })
        .reduceOrElse(math.max, orElse: () => 0.0))
        .toList();

  }

  /// This method which offsets children base on rectangles from
  /// [layout_Post_NotLeaf_PositionChildren] must be overridden to ensure the order we apply
  /// the rectangles 1D list to 2D children is for corresponding rectangle and child
  @override
  void _layout_Post_NotLeaf_OffsetChildren(List<ui.Rect> positionedRectsInMe, List<LayoutableBox> children) {
    assert(positionedRectsInMe.length == numRows * numColumns);

    List<List<TableLayoutCellDefiner>> cellDefinersTable = tableLayoutDefiner.cellDefinersTable;

    // Apply in-table offset, already calculated as rectangles on all table cells, to the cell.
    // Implementation note: We iterate same way as layout_Post_NotLeaf_PositionChildren, same result if we
    //    iterate cellsTable as the tables have contain corresponding cells
    for (int row = 0; row < cellDefinersTable.length; row++) {
      List<TableLayoutCellDefiner> definerRow = cellDefinersTable[row];
      for (int column = 0; column < definerRow.length; column++) {
        TableLayoutCellDefiner cellDefiner = definerRow[column];
        cellDefiner.cellContainer.applyParentOffset(this, positionedRectsInMe[row * numColumns + column].topLeft);
      }
    }

    /* KEEP
    for (int row = 0; row < cellsTable.length; row++) {
      List<BoxContainer> cellsRow = cellsTable[row];
      for (int column = 0; column < cellsRow.length; column++) {
        BoxContainer cell = cellsRow[column];
        cell.applyParentOffset(this, positionedRectsInMe[row * numRows + column].topLeft);
      }
    }
    */
  }

}

// --------------------------- ^^^^^^^^^^ Table

/// Layouter which asks it's parent [RollingBoxLayouter] to allocate as much space
/// as possible for it's single child .
///
/// It is NonPositioning, so it cannot honour it's parent [Align] and [Packing], and it's
/// child is positioned [Align.start] and [Packing.tight].
///
/// Uses base class [layout],
/// pre-descend sets full constraints on immediate children as normal
/// descend runs as normal, makes children make layoutSize available
/// post-descend runs as normal - does 'layout self'.
/// layoutSize is set to the calculated [_greedySizeAlongGreedyAxis].
///
class Greedy extends NonPositioningBoxLayouter {
  final int greed;

  Greedy({
    this.greed = 1,
    required BoxContainer child,
  }) : super(children: [child]);

  /// Override a standard hook in [layout] which sets the layout size.
  ///
  /// The set [layoutSize] of Greedy is not the default outer rectangle of children,
  /// instead, it is the full constraint side along the greedy axis,
  /// and children side along the cross-greedy axis
  @override
  void _layout_Post_NotLeaf_SetSize_FromPositionedChildren(List<ui.Rect> positionedChildrenRects) {
    assert(!isLeaf);
    // The Greedy layoutSize should be:
    //  - In the main axis direction (of it's parent), the constraint size of self,
    //    NOT the bounding rectangle of children.
    //    This is because children can be smaller, even if wrapped in Greedy,
    //    bu this Greedy should still expand in the main direction to it's allowed maximum.
    //  - In the cross-axis direction, take on the layout size of children outer rectangle, as
    //    ih the default implementation.
    ui.Rect positionedChildrenBoundingRect =  util_flutter
        .boundingRectOfRects(positionedChildrenRects.map((ui.Rect childRect) => childRect).toList(growable: false));
    // childrenOuterRectangle is ONLY needed for asserts. Can be removed for performance.
    ui.Rect childrenOuterRectangle = util_flutter
        .boundingRectOfRects(_children.map((BoxLayouter child) => child._boundingRectangle()).toList(growable: false));
    assert(childrenOuterRectangle.size == positionedChildrenBoundingRect.size);

    ui.Size greedySize = constraints.maxSize; // use the portion of this size along main axis
    ui.Size childrenLayoutSize = positionedChildrenBoundingRect.size; // use the portion of this size along cross axis

    if (_parent is! RollingBoxLayouter) {
      throw StateError('Parent of this Greedy container "$this" must be '
          'a ${(RollingBoxLayouter).toString()} but it is $_parent');
    }
    RollingBoxLayouter p = (_parent as RollingBoxLayouter);
    ui.Size size = _greedySizeAlongGreedyAxis(p.mainLayoutAxis, greedySize, childrenLayoutSize);

    // Set the layout size as the full constraint side along the greedy axis,
    // and children side along the cross-greedy axis
    layoutSize = size;
  }

  ui.Size _greedySizeAlongGreedyAxis(LayoutAxis greedyLayoutAxis, ui.Size greedySize, ui.Size childrenLayoutSize) {
    double width, height;
    switch (greedyLayoutAxis) {
      case LayoutAxis.horizontal:
        width = greedySize.width;
        height = childrenLayoutSize.height;
        break;
      case LayoutAxis.vertical:
        width = childrenLayoutSize.width;
        height = greedySize.height;
        break;
    }
    return ui.Size(width, height);
  }

  @override
  void buildAndReplaceChildren() {
    buildAndReplaceChildrenDefault();
  }

}

/// Default non positioning layouter does not position it's children, but it is concrete, unlike [BoxContainer].
class DefaultNonPositioningBoxLayouter extends NonPositioningBoxLayouter {
  DefaultNonPositioningBoxLayouter({
    List<BoxContainer>? children,
  }) : super(children: children);

}

/// Layouter which lays out it's single child surrounded by [EdgePadding] within itself.
///
/// [Padder] behaves as follows:
///   - Decreases own constraint by [edgePadding and provides it do a child
///   - When child returns it's [layoutSize], this layouter sets it's size as that of the child, surrounded with
///     the [edgePadding].
///
/// This governs implementation:
///   - [Padder] uses the default [BoxLayouter]'s [layout] except the
///     [_layout_Post_NotLeaf_OffsetChildren] is from immediate superclass [PositioningBoxLayouter].
///   - [Padder] changes the constraint before sending it to it's child, so
///     the [_layout_Pre_DistributeConstraintsToImmediateChildren] must be overridden.
///   - [Padder] is positioning, so the [layout_Post_NotLeaf_PositionChildren] is overridden,
///     while the [_layout_Post_NotLeaf_OffsetChildren] uses the default super implementation, which
///     applies the offsets returned by [layout_Post_NotLeaf_PositionChildren] onto the child.
class Padder extends PositioningBoxLayouter {
  Padder({
    required this.edgePadding,
    required BoxContainer child,
  }) : super(children: [child]);

  final EdgePadding edgePadding;

  /// Applies constraints on child.
  ///
  /// The constraints are self constraints deflated by padding
  /// (which will be added back onto self layoutSize).
  /// This ensures padded child will fit in self constraints.
  @override
  void _layout_Pre_DistributeConstraintsToImmediateChildren(List<LayoutableBox> children) {
    children[0].applyParentConstraints(this, constraints.deflateWithPadding(edgePadding));
  }


  /// Returns the future child position by offsetting child's layout size down and right
  /// by Offset created from Padding.
  @override
  List<ui.Rect> layout_Post_NotLeaf_PositionChildren(List<LayoutableBox> children) {
    ui.Offset childOffset = ui.Offset(edgePadding.start, edgePadding.top);
    return [childOffset & children[0].layoutSize];
  }

  /// Sets self [layoutSize], which is child layoutSize increased by EdgePadding in all directions.
  ///
  /// This self [layoutSize] is guaranteed to fit into self constraints.
  @override
  void _layout_Post_NotLeaf_SetSize_FromPositionedChildren(List<ui.Rect> positionedChildrenRects) {
    // Take the passed rectangle (which is same size as child, but offset from the self
    // origin right and down of padding start and top), and inflate it by padding
    // This will move the rectangle back to self origin (irrelevant), and it's inflated
    // size set as layout size.
    // So self layoutSize is increased from child layoutSize by EdgePadding in all directions.
    // in all directions
    ui.Rect thisRect = positionedChildrenRects[0].inflateWithPadding(edgePadding);

    layoutSize = thisRect.size;
  }
}

/// A positioning layouter that sizes self from the child
/// by relative ratios [childWidthBy] and [childHeightBy],
/// then aligns the single child within the sized self.
///
/// The sizing of self makes self typically larger than the child, although not necessarily.
///
/// The self sizing from child is defined by the multiples of child width and height,
/// the members [childWidthBy] and [childHeightBy].
///
/// The align process of the single child within self is defined by the member [alignment].
///
/// See [Alignment] for important notes and calculations on how child positioning
/// is calculated given [childWidthBy], [childHeightBy] and [alignment].
class Aligner extends PositioningBoxLayouter {
  Aligner({
    required this.childWidthBy,
    required this.childHeightBy,
    this.alignment = Alignment.center,
    required BoxContainer child,
  }) :
        assert(childWidthBy >= 1 && childHeightBy >= 1),
        alignmentTransform = AlignmentTransform(
          childWidthBy: childWidthBy,
          childHeightBy: childHeightBy,
          alignment: alignment,
        ),
        super(children: [child]);

  /// The alignment specification
  final Alignment alignment;
  /// Defines the width of this [Aligner], in terms of child width.
  ///
  /// For example, if child width is `childWidth`, the width of this [Aligner] is `childWidth * childWidthBy`
  final double childWidthBy;
  final double childHeightBy;
  final AlignmentTransform alignmentTransform;

  /// This override applies constraints on the immediate children of this [Aligner].
  ///
  /// The applied constraints are deflated from self constraints by the
  /// [childWidthBy] and [childHeightBy]
  @override
  void _layout_Pre_DistributeConstraintsToImmediateChildren(List<LayoutableBox> children) {
    LayoutableBox child = children[0];
    BoxContainerConstraints childConstraints = constraints.multiplySidesBy(ui.Size(1.0 / childWidthBy, 1.0 / childHeightBy));
    child.applyParentConstraints(this, childConstraints);
  }

  /// Position the only child in self, as mandated by this [Aligner]'s
  /// formulas for self size and child position in self.
  ///
  /// The self size mandate is implemented in [_selfLayoutSizeFromChild],
  /// the child position in self mandate is implemented in [_positionChildInSelf].
  @override
  List<ui.Rect> layout_Post_NotLeaf_PositionChildren(List<LayoutableBox> children) {
    LayoutableBox child = children[0];

    // Create and return the rectangle where the single child will be positioned.
    // Note that this layouter needs to know it's selfLayoutSize without setting it (done later).
    // The selfLayoutSize is needed here early to position children (end of selfLayoutSize is needed
    // to align to the end!!). This is the nature of this layouter - it defines selfLayoutSize from childSize,
    // so selfLayoutSize is known once child is layed out - true when this method is invoked.
    List<ui.Rect> positionedRectsInMe = [
      _positionChildInSelf(
        childSize: child.layoutSize,
      )
    ];

    return positionedRectsInMe;
  }

  /// Calculates and returns this [Aligner]-mandated [layoutSize]
  /// without setting it.
  ///
  /// This [Aligner] mandates that it's [layoutSize]
  /// is calculated by multiplying the [childLayoutSize]
  /// sides by [childWidthBy] and [childHeightBy].
  /// This method implements the self [layoutSize] mandate.
  ui.Size _selfLayoutSizeFromChild(ui.Size childLayoutSize) {
    return childLayoutSize.multiplySidesBy(ui.Size(childWidthBy, childHeightBy));
  }

  //_layout_Post_NotLeaf_OffsetChildren(positionedRectsInMe, children); using default implementation.

  /// Sets self [layoutSize] to the child layoutSize multiplied along axes
  /// by [childWidthBy], [childHeightBy], as mandated by this [Aligner].
  ///
  /// This multiplication is wrapped as [_selfLayoutSizeFromChild].
  @override
  void _layout_Post_NotLeaf_SetSize_FromPositionedChildren(List<ui.Rect> positionedChildrenRects) {
    layoutSize = _selfLayoutSizeFromChild(positionedChildrenRects[0].size);
  }

  /// Positions child in self, delegated to [_offsetChildInSelf].
  ///
  /// See [_offsetChildInSelf] for details
  ///
  /// Used in overridden [layout_Post_NotLeaf_PositionChildren] to position child in this [Aligner].
  ui.Rect _positionChildInSelf({
    required ui.Size childSize,
  }) {
    return alignmentTransform.childOffsetWhenAlignmentApplied(
          childSize: childSize,
        ) &
        childSize;
  }

}

// Helper classes ------------------------------------------------------------------------------------------------------

/// This class controls how layouters implementing the mixin [ExternalTicksRolling] position their children
/// along their main axis.
///
/// It manages all the directives the [ExternalTicksRolling] need to position their children
/// in their main axis direction.
///
/// It's useful role is provided by the method [lextrValuesToPixels], which,
/// given the axis pixels range, (assumed in the pixel coordinate range), extrapolates the [tickValues]
/// to layouter-relative positions on the axis, to which the layouter children will be positioned.
///
/// Specifically, this class provides the following directives for the layouters
/// that are [ExternalTicksRolling]:
///   - [tickValues] is the relative positions on which the children are placed
///   - [tickValuesDomain] is the interval in which the relative positions [tickValues] are.
///     [tickValuesDomain] must include all [tickValues];
///     it's boundaries may be larger than the envelope of all [tickValues]
///   - [isAxisPixelsAndDisplayedValuesInSameDirection] defines whether the axis pixel positions and [tickValues]
///     are run in the same direction.
///   - [externalTickAtPosition] the information what point on the child should be placed at the tick value:
///     child's start, center, or end. This is expressed by [ExternalTickAtPosition.childStart] etc.
///
/// Note: The parameter names use the term 'value' not 'position', as they represent
///        data values ('transformed' but NOT 'extrapolated to pixels').
///
/// Important note: Although not clear from this class, should ONLY position along the main axis.
///                 This is reflected in one-dimensionality of [tickValues] and [externalTickAtPosition]
///
class ExternalTicksLayoutProvider {

  ExternalTicksLayoutProvider({
    required this.tickValues,
    required this.tickValuesDomain,
    required this.isAxisPixelsAndDisplayedValuesInSameDirection,
    required this.externalTickAtPosition,
});

  /// Represent future positions of children of the layouter controlled
  /// by this ticks provider [ExternalTicksLayoutProvider].
  /// 
  /// By 'future positions' we mean the [tickValues] after extrapolation to axis pixels, 
  /// to be precise, [tickValues] extrapolated by [lextrValuesToPixels] when passed axis pixels range.
  /// 
  final List<double> tickValues;

  final util_dart.Interval tickValuesDomain;

  /// Calculated late, after tickPixelsDomain is set
  late final List<double> tickPixels;

  /// Set late, during layout, Post, after children are layed out, from the full constraints along main axis.
  /// Actually equals the [layoutSize] portion along main axis, which is also the constraints of the owner
  /// [ExternalTicksBoxLayouter].
  late final util_dart.Interval tickPixelsDomain;

  final bool isAxisPixelsAndDisplayedValuesInSameDirection;

  final ExternalTickAtPosition externalTickAtPosition;

  /// Sets the domain for the ticks in [tickValues]; this is pixel-lextr-equivalent of [tickValuesDomain].
  void setTickPixelsDomainAndLextr(util_dart.Interval tickPixelsDomainFromOwnerConstraints) {
    tickPixelsDomain = tickPixelsDomainFromOwnerConstraints;
    tickPixels = lextrValuesToPixels();
  }

  /// Returns tha [tickValues] Linearly extrapolated to the passed [axisPixelsRange].
  ///
  /// Important Note: [tickValues] are always in increasing order, and [axisPixelsRange]
  ///                 minimum is less than maximum.
  ///                 When displayed on screen, the horizontal pixels axis is always ordered left-to-right,
  ///                 the vertical pixels axis is always ordered top-to-bottom
  ///                 The [isAxisPixelsAndDisplayedValuesInSameDirection] should be set as follows:
  ///                   - On the horizontal axis:
  ///                     - If we want the [tickValues] be displayed left-to-right, set it to [true] (default).
  ///                     - Else set it to [false]
  ///                   - On the vertical axis:
  ///                     - If we want the [tickValues] be displayed bottom-to-tom, set it to [false] (default).
  ///                     - Else set it to [false]
  ///
  List<double> lextrValuesToPixels() {
    /* todo-00! Maybe something like this is needed
    // Special case, if _labelsGenerator.dataRange=(0.0,0.0), there are either no data, or all data 0.
    // Lerp the result to either start or end of the axis pixels, depending on [isAxisAndLabelsSameDirection]
    if (dataRange == const util_dart.Interval(0.0, 0.0)) {
      double pixels;
      if (!isAxisPixelsAndDisplayedValuesInSameDirection) {
        pixels = axisPixelsMax;
      } else {
        pixels = axisPixelsMin;
      }
      return pixels;
    }    
    */
    
    return tickValues
        .map((double value) => util_dart.ToPixelsExtrapolation1D(
              fromValuesMin: tickValuesDomain.min,
              fromValuesMax: tickValuesDomain.max,
              toPixelsMin: tickPixelsDomain.min,
              toPixelsMax: tickPixelsDomain.max,
              doInvertToDomain: !isAxisPixelsAndDisplayedValuesInSameDirection,
            ).apply(value))
        .toList();
  }

}

enum ExternalTickAtPosition {
  childStart,
  childCenter,
  childEnd,
}

enum LayoutAxis {
  horizontal,
  vertical,
}

LayoutAxis axisPerpendicularTo(LayoutAxis layoutAxis) {
  switch (layoutAxis) {
    case LayoutAxis.horizontal:
      return LayoutAxis.vertical;
    case LayoutAxis.vertical:
      return LayoutAxis.horizontal;
  }
}

class NullLikeListSingleton extends custom_collection.CustomList<BoxContainer> {

  /// Generative PRIVATE NAMED constructor allows to create private-only instances.
  ///
  /// Note: The  1 UNNAMED already used up by factory [NullLikeListSingleton] constructor.
  NullLikeListSingleton._privateNamedConstructor() : super(growable: false);

  /// The single private instance returned from the factory every time.
  static final _instance = NullLikeListSingleton._privateNamedConstructor();

  /// Factory UNNAMED constructor.
  ///
  /// This existence of UNNAMED prevents UNNAMED GENERATIVE 'NullLikeListSingleton()'
  ///   to be code-generated. So, the only way to create instance is
  ///   via [NullLikeListSingleton._privateNamedConstructor].
  /// We could use it create multiple instances, but only in this library file container_layouter_base.dart.
  ///
  /// In this library, we only ever create the single [_instance] to make this class a singleton.
  factory NullLikeListSingleton() {
    return _instance;
  }
}

/// On behalf of layouters which can layout their children using [Packing], and [Align],
/// calculates holds on the results of 1Dimensional positions of children
/// along the main and cross axis, calculated
///
/// The 1Dimensional positions are held in [mainAxisPositionedSegments] and [crossAxisPositionedSegments]
/// as [PositionedLineSegments.lineSegments].
///
/// The method [_convertPositionedSegmentsToRects] allows to convert
/// such 1Dimensional positions along main and cross axis
/// into rectangles [List<ui.Rect>], where children of self [BoxLayouter] node should be positioned.
///
class _MainAndCrossPositionedSegments {

  /// Constructs an instance given the [children] which may be smaller than full children list,
  /// and their [parentBoxLayouter].
  ///
  /// Uses the passed [mainAxisLayoutProperties], [crossAxisLayoutProperties] and the [mainLayoutAxis]
  /// to find children positions in the [parentBoxLayouter].
  ///
  /// This method:
  ///   - Created two instances of [LayedoutLengthsPositioner], one for the main axis, one for the cross axis,
  ///     and invokes their [LayedoutLengthsPositioner.positionLengths] on each.
  ///
  ///   - The result is the children 1D positions using the [LayedoutLengthsPositioner],
  ///     and keeps the children positions on state in a 'primitive one-dimensional format',
  ///     in [mainAxisPositionedSegments] and [crossAxisPositionedSegments]
  ///     which contain the 1D [LayedOutLineSegments] along main and cross axis.
  ///
  /// Note that, in the[LayedoutLengthsPositioner.positionLengths],  the offset on each element
  /// is calculated using the [mainAxisLayoutProperties] in the main axis direction,
  /// and the [crossAxisLayoutProperties] in the cross axis direction.
  ///
  /// The method [asRectangles] can convert the 1D positions into rectangles representing [children]
  /// positions in [parentBoxLayouter].
  ///
  _MainAndCrossPositionedSegments({
    required this.parentBoxLayouter,
    required this.parentConstraints,
    required this.children,
    required this.mainLayoutAxis,
    required this.mainAxisLayoutProperties,
    required this.crossAxisLayoutProperties,
  })
  {
    // From the sizes of the [children] create a LayedoutLengthsPositioner along each axis (main, cross).
    var crossLayoutAxis = axisPerpendicularTo(mainLayoutAxis);

    LayedoutLengthsPositioner mainAxisLayedoutLengthsPositioner = LayedoutLengthsPositioner(
      lengths: parentBoxLayouter.layoutSizesOfChildrenSubsetAlongAxis(mainLayoutAxis, children),
      lengthsPositionerProperties: mainAxisLayoutProperties,
      lengthsConstraint: parentConstraints.maxLengthAlongAxis(mainLayoutAxis),
    );

    LayedoutLengthsPositioner crossAxisLayedoutLengthsPositioner = LayedoutLengthsPositioner(
      lengths: parentBoxLayouter.layoutSizesOfChildrenSubsetAlongAxis(crossLayoutAxis, children),
      lengthsPositionerProperties: crossAxisLayoutProperties,
      // todo-010 : Investigate : If we use, instead of 0.0,
      //                 the logical lengthsConstraintAlongLayoutAxis: constraints.maxLengthAlongAxis(axisPerpendicularTo(mainLayoutAxis)), AND
      //                 if legend starts with column, the legend column is on the left of the chart
      //                 if legend starts with row   , the legend row    is on the bottom of the chart
      //                 Probably need to address when the whole chart is layed out using the new layouter.
      //                 The 0.0 forces that in the cross-direction (horizontal or vertical),
      //                 we provide zero length constraint, so no length padding.
      lengthsConstraint: 0.0, // constraints.maxLengthAlongAxis(crossLayoutAxis),
    );

    // Layout the lengths along each axis to line segments (offset-ed lengths).
    // This is layouter specific - each layouter does 'layout the lengths' according to it's specific rules,
    // controlled by [Packing] (tight, loose, center) and [Align] (start, end, matrjoska).
    // The [layoutLengths] method actually includes positioning the lengths, and also calculating the totalLayedOutLengthIncludesPadding,
    //   which is the total length of children.
    mainAxisPositionedSegments = mainAxisLayedoutLengthsPositioner.positionLengths();
    crossAxisPositionedSegments = crossAxisLayedoutLengthsPositioner.positionLengths();
  }

  /// The [BoxLayouter] parent of the [children] for which we seek the positions within self.
  ///
  /// It is necessary, as it provides the constraints where all the children should fit
  /// in one 1D direction given their layout properties along that direction.
  /// If children do not fit, the [util_dart.LineSegment]s in the respective
  /// [mainAxisPositionedSegments] or [crossAxisPositionedSegments] are marked as
  /// [PositionedLineSegments.isOverflown].
  final BoxLayouter parentBoxLayouter;
  /// Constraints that the [children] should fit in.
  ///
  /// [PositionedLineSegments.isOverflown] is set to [true] if children do not fit.
  /// Constraints are by default from [parentBoxLayouter.constraints], but not necessarily,
  /// so it is passed separately.
  final BoxContainerConstraints parentConstraints;
  final List<LayoutableBox> children;
  final LayoutAxis mainLayoutAxis;
  final LengthsPositionerProperties mainAxisLayoutProperties;
  final LengthsPositionerProperties crossAxisLayoutProperties;
  late final PositionedLineSegments mainAxisPositionedSegments;
  late final PositionedLineSegments crossAxisPositionedSegments;

  /// Converts the line segments from [mainAxisPositionedSegments] and [crossAxisPositionedSegments]
  /// (they correspond to children widths and heights that have been layed out)
  /// to [ui.Rect]s, the rectangles where children of self [BoxLayouter] node should be positioned.
  ///
  /// Children should be offset later in [layout] by the obtained [Rect.topLeft] offsets;
  ///   this method does not change any offsets of self or children.
  List<ui.Rect> _convertPositionedSegmentsToRects() {

    if (mainAxisPositionedSegments.lineSegments.length != crossAxisPositionedSegments.lineSegments.length) {
      throw StateError('Segments differ in lengths: main=$mainAxisPositionedSegments, cross=$crossAxisPositionedSegments');
    }

    List<ui.Rect> positionedRects = [];

    for (int i = 0; i < mainAxisPositionedSegments.lineSegments.length; i++) {
      ui.Rect rect = __convertMainAndCrossSegmentsToRect(
        mainLayoutAxis: mainLayoutAxis,
        mainSegment: mainAxisPositionedSegments.lineSegments[i],
        crossSegment: crossAxisPositionedSegments.lineSegments[i],
      );
      positionedRects.add(rect);
    }
    return positionedRects;
  }

  /// Converts two [util_dart.LineSegment] to [Rect] according to [mainLayoutAxis].
  ///
  /// The offset of the rectangle is [Rect.topLeft];
  ui.Rect __convertMainAndCrossSegmentsToRect({
    required LayoutAxis mainLayoutAxis,
    required util_dart.LineSegment mainSegment,
    required util_dart.LineSegment crossSegment,
  }) {
    // Only the segments' beginnings are used for offset on BoxLayouter.
    // The segments' ends are already taken into account in BoxLayouter.size.
    switch (mainLayoutAxis) {
      case LayoutAxis.horizontal:
        return ui.Offset(mainSegment.min, crossSegment.min) &
        ui.Size(mainSegment.max - mainSegment.min, crossSegment.max - crossSegment.min);
      case LayoutAxis.vertical:
        return ui.Offset(crossSegment.min, mainSegment.min) &
        ui.Size(crossSegment.max - crossSegment.min, mainSegment.max - mainSegment.min);
    }
  }

  List<ui.Rect> asRectangles() {
    // print(
    //     'mainAxisLayedOutSegments.lineSegments = ${mainAndCrossLayedOutSegments.mainAxisLayedOutSegments.lineSegments}');
    // print(
    //     'crossAxisLayedOutSegments.lineSegments = ${mainAndCrossLayedOutSegments.crossAxisLayedOutSegments.lineSegments}');

    if (parentBoxLayouter.isLeaf) {
      return [];
    }
    // Convert the line segments to [Offset]s (in each axis). Children will be moved (offset) by the obtained [Offset]s.
    List<ui.Rect> positionedRectsInMe = _convertPositionedSegmentsToRects();
    // print('positionedRectsInMe = $positionedRectsInMe');
    return positionedRectsInMe;
  }

}

// Functions and Helper classes ----------------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------------------------------------------
/* END of BoxContainer: KEEP
  // todo-04 : Replace ParentOffset with ParentTransform. ParentTransform can be ParentOffsetTransform,
  //           ParentTiltTransform, ParentSheerTransform etc.
  /// Maintains current tiltMatrix, a sum of all tiltMatrixs
  /// passed in subsequent calls to [applyParentTransformMatrix] during object
  /// lifetime.
  vector_math.Matrix2 _transformMatrix = vector_math.Matrix2.identity();

  /// Provides access to tiltMatrix for extension's [paint] methods.
  vector_math.Matrix2 get transformMatrix => _transformMatrix;

  /// Tilt may apply to the whole [BoxContainer].
  /// todo-2 unused? move to base class? similar to offset?
  void applyParentTransformMatrix(vector_math.Matrix2 transformMatrix) {
    if (transformMatrix == vector_math.Matrix2.identity()) return;
    _transformMatrix = _transformMatrix * transformMatrix;
  }
  */


/* --------------------------
  Removed forced Packing changes on deeper Row and Column

  1. was on : RollingBoxLayouter
  void _forceMainAxisLayoutProperties({
    required _FirstRollingLayouterTracker rollingTracker,
    required Packing packing,
    required Align align,
    required externalTicksLayoutProvider,
  }) {
    mainAxisLayoutProperties = LengthsPositionerProperties(
      align: align,
      packing: packing,
      externalTicksLayoutProvider: externalTicksLayoutProvider,
    );
  }

  // 2. Was on: _layout_IfRoot_DefaultTreePreprocessing

  // On nested levels [Row]s OR [Column]s force non-positioning layout properties.
  // A hack makes this baseclass [BoxLayouter] depend on it's extensions [Column] and [Row]
  _static_ifRoot_Force_Deeper_Row_And_Column_LayoutProperties_To_NonPositioning(
    rollingTracker: _FirstRollingLayouterTracker(
      firstRowFromTopFoundBefore: false,
      firstColumnFromTopFoundBefore: false,
    ),
    parentContainer: this,
  );


  // 3. Was in : RollingBoxLayouter
          method _layout_Rolling_Post_NonGreedy_FindConstraintRemainingAfterNonGreedy_DivideIt_And_ApplyOnGreedy
          section if (_hasGreedy)
  LengthsPositionerProperties storedLayout = mainAxisLayoutProperties;
      _forceMainAxisLayoutProperties(
        align: mainAxisLayoutProperties.align, // Keep alignment
        packing: Packing.tight,
        externalTicksLayoutProvider: mainAxisLayoutProperties.externalTicksLayoutProvider,
        // rollingTracker is irrelevant here
        rollingTracker: _FirstRollingLayouterTracker(
          firstRowFromTopFoundBefore: false,
          firstColumnFromTopFoundBefore: false,
        ),
      );

      List<ui.Rect> positionedRectsInMe = layout_Post_NotLeaf_PositionChildren(_nonGreedyChildren);
      ui.Rect nonGreedyBoundingRect = util_flutter.boundingRectOfRects(positionedRectsInMe);
      assert(nonGreedyBoundingRect.topLeft == ui.Offset.zero);

  // After pre-positioning to obtain children sizes without any spacing, put back axis properties
  //  - next time this layouter will layout children using the original properties
      _forceMainAxisLayoutProperties(
        align: storedLayout.align,
        packing: storedLayout.packing,
        externalTicksLayoutProvider: mainAxisLayoutProperties.externalTicksLayoutProvider,
        // rollingTracker is irrelevant here
        rollingTracker: _FirstRollingLayouterTracker(
          firstRowFromTopFoundBefore: false,
          firstColumnFromTopFoundBefore: false,
        ),
      );


  4. Was in: this file, top level at the end

/// Tracks found rolling layouters on behalf of
/// [_static_ifRoot_Force_Deeper_Row_And_Column_LayoutProperties_To_NonPositioning].
class _FirstRollingLayouterTracker {
  _FirstRollingLayouterTracker({
    required this.firstRowFromTopFoundBefore,
    required this.firstColumnFromTopFoundBefore,
    // List<BoxLayouter> foundRows = const [],
    // List<BoxLayouter> foundColumns = const [],
  });

  bool firstRowFromTopFoundBefore;
  bool firstColumnFromTopFoundBefore;
  /// Rolling layouters found along the way, first found is first.
  List<BoxLayouter> foundRows = [];
  List<BoxLayouter> foundColumns = [];

}

/// Forces default non-positioning axis layout properties [LengthsPositionerProperties]
/// on the nested hierarchy nodes of type [Row] and [Column] nodes.
///
/// Motivation: The one-pass layout we use allows only the topmost [Row] or [Column]
///              to specify values that cause non-zero offset.
///
///              Only [Packing.tight] and [Align.start] do not cause offset and
///              are allowed on nested level [Row] or [Column].
///
///              But such behavior is contra intuitive for users to set, so
///              this method enforces that, even though it makes
///              a baseclass [BoxLayouter] to know about it's extensions
///              [Row] or [Column] (by calling this method in the baseclass [BoxLayouter]).
///              We make this a library level function to at least visually remove it from the  baseclass [BoxLayouter].
///
/// This method forces the deeper level values to the non-offsetting.
void _static_ifRoot_Force_Deeper_Row_And_Column_LayoutProperties_To_NonPositioning({
  required _FirstRollingLayouterTracker rollingTracker,
  required BoxLayouter parentContainer,
}) {
  if (__is_Row_for_rewrite(parentContainer) && !rollingTracker.firstRowFromTopFoundBefore) {
    rollingTracker.firstRowFromTopFoundBefore = true;
    rollingTracker.foundRows.add(parentContainer);
  }

  if (__is_Column_for_rewrite(parentContainer) && !rollingTracker.firstColumnFromTopFoundBefore) {
    rollingTracker.firstColumnFromTopFoundBefore = true;
    rollingTracker.foundColumns.add(parentContainer);
  }

  for (var currentContainer in parentContainer._children) {
    if (__is_Row_for_rewrite(currentContainer) && rollingTracker.firstRowFromTopFoundBefore) {
      (currentContainer as RollingBoxLayouter)._forceMainAxisLayoutProperties(
        rollingTracker: rollingTracker,
        align: currentContainer.mainAxisLayoutProperties.align, // Keep alignment
        packing: Packing.tight,
        externalTicksLayoutProvider: currentContainer.mainAxisLayoutProperties.externalTicksLayoutProvider,
      );
    }
    if (__is_Column_for_rewrite(currentContainer) && rollingTracker.firstColumnFromTopFoundBefore) {
      (currentContainer as RollingBoxLayouter)._forceMainAxisLayoutProperties(
        rollingTracker: rollingTracker,
        align: currentContainer.mainAxisLayoutProperties.align, // Keep alignment
        packing: Packing.matrjoska,
        externalTicksLayoutProvider: currentContainer.mainAxisLayoutProperties.externalTicksLayoutProvider,
      );
    }

    // in-child continue to child's children with the potentially updated values 'foundFirst'
    _static_ifRoot_Force_Deeper_Row_And_Column_LayoutProperties_To_NonPositioning(
      rollingTracker: rollingTracker,
      parentContainer: currentContainer,
    );
  }
}

bool __is_Row_for_rewrite(BoxLayouter container)    => container is Row    && container is! ExternalTicksRow;
bool __is_Column_for_rewrite(BoxLayouter container) => container is Column && container is! ExternalTicksColumn;

 */

/*


/// buildAndReplaceChildrenDefault - does not modify the passed [LayoutContext] and returns.


/// no-op class that should handle passing information during hierarchy building.
///
/// Allows siblings which were layed out before this element, to pass information
/// that control layout of this element.
class LayoutContext {
  LayoutContext._forUnused();
  static final LayoutContext unused = LayoutContext._forUnused();
}
*/