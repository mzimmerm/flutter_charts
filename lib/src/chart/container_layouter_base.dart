import 'dart:ui' as ui show Size, Offset, Rect, Canvas, Paint;
import 'dart:math' as math show Random;
import 'package:flutter/material.dart' as material show Colors;
import 'package:flutter/services.dart';

// this level or equivalent
import 'container_edge_padding.dart' show EdgePadding;
import 'layouter_one_dimensional.dart'
    show
    Align,
    Packing,
    LengthsPositionerProperties,
    LayedoutLengthsPositioner,
    PositionedLineSegments,
    ConstraintsDistribution;
import 'container_alignment.dart' show Alignment;
import '../morphic/rendering/constraints.dart' show BoundingBoxesBase, BoxContainerConstraints;
import '../util/extensions_flutter.dart' show SizeExtension, RectExtension;
import '../util/util_dart.dart' as util_dart show LineSegment, Interval, ToPixelsExtrapolation1D;
import '../util/util_flutter.dart' as util_flutter show boundingRectOfRects, assertSizeResultsSame;
import '../util/collection.dart' as custom_collection show CustomList;
import '../container/container_key.dart'
    show
    ContainerKey,
    Keyed,
    UniqueKeyedObjectsManager;

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
  BoxContainer? _parent; // null. will be set to non-null when addChild(this) is called on this parent

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

  /// Method that allows [BoxContainer] children to be created and set (or replaced) during [layout]
  /// of their parent.
  ///
  /// Implementations use this as follows:
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
  ///     2.  instance.buildAndReplaceChildren(LayoutContext.unused); // or a concrete LayoutContext
  ///     3.  instance.layout();
  ///     4.  instance.applyParentOffset(this, instanceParentOffset);
  ///   ```
  ///   The reason is, there are legitimite reasons for the [buildAndReplaceChildren]
  ///   to need the instance's [constraints].
  ///
  void buildAndReplaceChildren(covariant LayoutContext layoutContext);

  /// Default implementation of [buildAndReplaceChildren] is a no-op,
  /// does not modify this node's children, does not modify container's internal state,
  /// does not modify the passed [LayoutContext] and returns.
  ///
  /// Default should be called from [buildAndReplaceChildren] by any container
  /// that creates it's whole child hierarchy in its constructor.
  ///
  /// Containers that wish to only set *immediate children* in their constructor
  /// (while intending that the hierarchy will be built deeper down),
  /// should not call this default method in [buildAndReplaceChildren], but use
  /// [buildAndReplaceChildren] to do the intended deeper hierarchy building.
  ///
  void buildAndReplaceChildrenDefault(covariant LayoutContext layoutContext) {
    // As a test, replace children with self. Remove later when this proves to work
    // replaceChildrenWith(_children);
  }


  /// Set children list
  // set _children(List<BoxContainer> children) { __children = children; }

  bool get isRoot => _parent == null;

  bool get isLeaf => __children.isEmpty;

  BoxContainer? _root;

  BoxContainer get root {
    if (_root != null) {
      return _root!;
    }

    if (_parent == null) {
      _root = _children[0]._parent; // cannot be 'this' as 'this' is ContainerHiearchy, so go through children, must be one
      return _root!;
    }

    BoxContainer rootCandidate = _parent!;

    while (rootCandidate._parent != null) {
      rootCandidate = rootCandidate._parent!;
    }
    _root = rootCandidate;
    return _root!;
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
  /// and applies the passed function on the passed [object].
  /// 
  /// The [object] is passed to the function [useElementWith] as second parameter after the
  /// processed element.
  void applyOnAllElements(Function(E, dynamic passedObject) useElementWith, dynamic object) {

    if (hasLinkedElements) {
      for (E element = firstLinked(); ; element = element.next) {
        // e.g. newPointContainerList.add(element.generateViewChildrenEtc());
        useElementWith(element, object);
        if (!(element as DoubleLinked).hasNext) {
          break;
        }
      }
    }
  }

  /// Iterates all owned [DoubleLinked] elements starting with the last,
  /// and applies the passed function on the passed [object].
  ///
  /// See [applyOnAllElements] for details.
  void applyOnAllElementsReversed(Function(E, dynamic passedObject) useElementWith, dynamic object) {

    if (hasLinkedElements) {
      for (E element = lastLinked(); ; element = element.previous) {
        // e.g. newPointContainerList.add(element.generateViewChildrenEtc());
        useElementWith(element, object);
        if (!(element as DoubleLinked).hasPrevious) {
          break;
        }
      }
    }
  }
}

/// On a child [BoxLayouter], defines how constraints should be distributed among it's siblings.
/// 
/// Definition: Weights with value of 0 [defaultWeight] or negative values are all classified as *undefined weight*
///             [BoxLayouter] with [BoxLayouter.constraintsWeight] set to [defaultWeight] or negative value
///             is also classified as *undefined weight* layouter.
///
/// Important note: On [BoxLayouter] children where at least one sibling has *undefined weight*,
///                 layout algorithm should pass to all children a full constraint of parent.
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
  ///  1) Generally, neither leafs nor non-leafs need to override [applyParentOffset],
  ///     as this method is integral part of the layout process (implemented in [layout]).
  ///  2) Exception that need to override would be those using manual
  ///     layout process. Those would generally (always?) be leafs, and they would do the following:
  ///       - Override [layout] (no super call), do manual layout calculations,
  ///         likely store the result as member (see [LabelContainer._tiltedLabelEnvelope],
  ///         and set [layoutSize] at the end, so parent can pick it up
  ///       - Override [applyParentOffset] as follows:
  ///          - likely call super [applyParentOffset] to set overall offset in parent.
  ///          - potentially re-offset the position as a result of the manual layout
  ///            (see [LabelContainer.offsetOfPotentiallyRotatedLabel]) and store result as member.
  ///        - Override [paint] by painting on the calculated (parent also applied) offset,
  ///           (see [LabelContainer.paint].
  ///  3) As a lemma of 1), generally, there is no need to call [super.applyParentOffset] ;
  ///     Extensions covered in 2) which do override, are those manual layout classes
  ///     which maintain some child [BoxContainer]s in addition to [BoxContainerHierarchy._children].
  ///     Those should call [super.applyParentOffset] first, to offset the [BoxContainerHierarchy._children],
  ///     then offset the additionally maintained children by the same offset as the [BoxContainerHierarchy._children].
  ///
  void applyParentOffset(LayoutableBox caller, ui.Offset offset);

  /// todo-doc-01 fully, also write : Important override notes and rules for [applyParentOrderedSkip] on extensions:
  /// Expresses that parent ordered this [BoxLayouter] instance to be skipped during
  /// the [layout] and [paint] processing.
  ///
  void applyParentOrderedSkip(LayoutableBox caller, bool orderedSkip);

  /// Set constraints from parent of this [LayoutableBox].
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
  ///   - For an extension overriding [layout] to function in a [BoxContainerHierarchy] the requirements are:
  ///     - The [layout] sets [layoutSize] (usually, just before return) which should contain the whole
  ///       area to which [BoxContainer.paint] will draw graphics.
  ///       This is the only requirement for leafs.
  ///     - On non-leafs only:
  ///       - On each child [__children] that need to be shown, invoke, in this order
  ///         - child.[applyParentConstraints]
  ///         - child.[layout]
  ///         - store of child [layoutSize]
  ///       - Calculate self [layoutSize] from children [layoutSize]s
  ///
  ///   - For an extension overriding SOME OF THE PUBLIC METHODS CALLED IN [layout] BUT NOT [layout],
  ///     to function in a [BoxContainerHierarchy] the requirements are:
  ///     - On leaf, override [layout_Post_Leaf_SetSize_FromInternals] and set [layoutSize].
  ///
  @override
  void layout() {
    buildAndReplaceChildren(LayoutContext.unused);

    _layout_IfRoot_DefaultTreePreprocessing();

    // A. node-pre-descend. When entered:
    //    - constraints on self are set from recursion
    //    - constraints on children are not set yet.
    //    - children to not have layoutSize yet
    _layout_DefaultRecurse();
  }

  // BoxLayouter section 3: Non-override new methods on this class, starting with layout methods -----------------------

  // BoxLayouter section 3.1: Layout methods

  void _layout_IfRoot_DefaultTreePreprocessing() {
    if (isRoot) {
      // todo-04 : rethink, what this size is used for. Maybe create a singleton 'uninitialized constraint' - maybe there is one already?
      assert(constraints.size != const ui.Size(-1.0, -1.0));
      // On nested levels [Row]s OR [Column]s force non-positioning layout properties.
      // A hack makes this baseclass [BoxLayouter] depend on it's extensions [Column] and [Row]
      _static_ifRoot_Force_Deeper_Row_And_Column_LayoutProperties_To_NonPositioning(
        foundFirstRowFromTop: false,
        foundFirstColumnFromTop: false,
        boxLayouter: this,
      );
    }
  }

  void _layout_DefaultRecurse() {
    // A. node-pre-descend. Here, children to not have layoutSize yet. Constraint from root down should be set
    _layout_Pre_DistributeConstraintsToImmediateChildren(_children);

    // B. node-descend
    for (var child in _children) {
      // b1. child-pre-descend (empty)
      // b2. child-descend
      child.layout();
      // b3. child-post-descend (empty)
    }
    // C. node-post-descend.
    //    Here, children have layoutSizes, which are used to lay them out in me, then offset them in me
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
    _layout_Post_AssertSizeInsideConstraints();
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

  /// [layout_Post_NotLeaf_PositionChildren] is a core method of the default [layout]
  /// which positions the invoker's children in self.
  ///
  /// [layout_Post_NotLeaf_PositionChildren] is abstract in [BoxLayouter] and no-op in [BoxContainer] (returning empty list,
  /// which causes no positioning of children.
  ///
  /// Implementations should lay out children of self [BoxLayouter],
  /// and return [List<ui.Rect>], a list of rectangles [List<ui.Rect>]
  /// where children will be placed relative to the invoker, in the order of the passed [children].
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
  ///   - [RollingPositioningBoxLayouter]s [Row] and [Column] use this
  ///     - although they override [layout], the method [_layout_Post_NotLeaf_PositionThenOffsetChildren_ThenSetSize]
  ///     which invokes this is default. These classes rely on this default
  ///     "bounding rectangle of all positioned children" implementaion.
  ///
  void _layout_Post_NotLeaf_SetSize_FromPositionedChildren(List<ui.Rect> positionedChildrenRects) {
    assert(!isLeaf);
    ui.Rect positionedChildrenOuterRects = util_flutter
        .boundingRectOfRects(positionedChildrenRects.map((ui.Rect childRect) => childRect).toList(growable: false));
    // childrenOuterRectangle is ONLY needed for asserts. Can be removed for performance.
    ui.Rect childrenOuterRectangle = util_flutter
        .boundingRectOfRects(_children.map((BoxLayouter child) => child._boundingRectangle()).toList(growable: false));
    util_flutter.assertSizeResultsSame(childrenOuterRectangle.size, positionedChildrenOuterRects.size);

    layoutSize = positionedChildrenOuterRects.size;
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

  /// Checks if [layoutSize] box is within the [constraints] box.
  ///
  /// Throws error otherwise.
  void _layout_Post_AssertSizeInsideConstraints() {
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

  /// Override of the abstract [layout_Post_NotLeaf_PositionChildren] on instances of this base [BoxContainer].
  ///
  /// [layout_Post_NotLeaf_PositionChildren] is abstract in [BoxLayouter] and no-op here in [BoxContainer].
  /// The no-op is achieved by returning, the existing children rectangles, without re-positioning children;
  /// the follow up methods use the returned value and apply this offset, without re-offsetting children.
  ///
  /// Returning an empty list here causes no offsets on children are applied,
  /// which is desired on this non-positioning base class [BoxContainer].
  ///
  /// See the invoking [_layout_Post_NotLeaf_PositionThenOffsetChildren_ThenSetSize] for more override posibilities.
  ///
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
    // Find a way to find constraints on top container - ~get topContainerConstraints~, and access them from any BoxContainer
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

/// no-op class that should handle passing information during hierarchy building.
///
/// Allows siblings which were layed out before this element, to pass information
/// that control layout of this element.
class LayoutContext {
  LayoutContext._forUnused();
  static final LayoutContext unused = LayoutContext._forUnused();
}

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
  void buildAndReplaceChildren(covariant LayoutContext layoutContext) {
    buildAndReplaceChildrenDefault(layoutContext);
  }
}

/// Layouter which is NOT allowed to offset it's children, or only offset with zero offset.
abstract class NonPositioningBoxLayouter extends BoxContainer {
  /// The required unnamed constructor
  NonPositioningBoxLayouter({
    List<BoxContainer>? children,
  }) : super(children: children);

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
  void buildAndReplaceChildren(covariant LayoutContext layoutContext) {
    buildAndReplaceChildrenDefault(layoutContext);
  }

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
abstract class RollingPositioningBoxLayouter extends PositioningBoxLayouter {
  RollingPositioningBoxLayouter({
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

  LayoutAxis mainLayoutAxis = LayoutAxis.horizontal;

  // isLayout should be implemented differently on layouter and container. But it's not really needed
  // bool get isLayout => mainLayoutAxis != LayoutAxis.defaultHorizontal;

  // todo-013 : mainAxisLayoutProperties and crossAxisLayoutProperties could be private
  //            so noone overrides their 'packing: Packing.tight, align: Align.start'
  /// Properties of layout on main axis.
  ///
  /// Note: cannot be final, as _forceMainAxisLayoutProperties may re-initialize
  late LengthsPositionerProperties mainAxisLayoutProperties;
  late LengthsPositionerProperties crossAxisLayoutProperties;

  /// [RollingPositioningBoxLayouter] overrides the base [BoxLayouter.layout] to support [Greedy] children
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
    buildAndReplaceChildren(LayoutContext.unused);

    _layout_IfRoot_DefaultTreePreprocessing();

    // if (_hasGreedy) {
    // Process Non-Greedy children first, to find what size they use
    if (_hasNonGreedy) {
      // A. Non-Greedy pre-descend : Distribute intended constraints only to nonGreedyChildren, which we will layout
      //                         using the constraints. Uses default constraints distribution method from [BoxLayouter],
      //                         All children obtain full self (parent) constraints.
      _layout_Pre_DistributeConstraintsToImmediateChildren(_nonGreedyChildren);
      // B. Non-Greedy node-descend : must layout non-greedy to get their sizes. But this will mess up finality of constraints, layoutSizes etc.
      for (var child in _nonGreedyChildren) {
        // Non greedy should run full layout of children.
        child.layout();
      }
      // C. Non-greedy node-post-descend. Here, non-greedy children have layoutSize
      //      which we can get and use to lay them out to find constraints left for greedy
      //    But positioning children in self, we need to run pre-position of children in self
      //      using left/tight to get sizes without spacing.
      _layout_Post_NonGreedy_FindConstraintRemainingAfterNonGreedy_DivideIt_And_ApplyOnGreedy();
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
    //      child constraints again in  _layout_DefaultRecurse() -> _layout_Pre_DistributeConstraintsToImmediateChildren(children);
    //      We only want the descend part of _layout_DefaultRecurse(), even the layout_Post must be different
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
    //   _layout_DefaultRecurse();
    // }
  }

  List<Greedy> get _greedyChildren => _children.whereType<Greedy>().toList();

  List<LayoutableBox> get _nonGreedyChildren {
    List<BoxContainer> nonGreedy = List.from(_children);
    nonGreedy.removeWhere((var child) => child is Greedy);
    return nonGreedy;
  }

  bool get _hasGreedy => _greedyChildren.isNotEmpty;

  bool get _hasNonGreedy => _nonGreedyChildren.isNotEmpty;

  /// Distributes constraints to the passed [children] specifically for this layout, the
  ///
  /// Overridden from [BoxLayouter] to work like this:
  ///
  ///   - If all children have a weight defined
  ///     (that is, not [ConstraintsWeight defaultWeight], checked by [ConstraintsWeights.allDefined])
  ///     method divides the self constraints to smaller pieces along the main axis, keeping the self constraint size
  ///     along the cross axis. Then distributes the divided constraints to children
  ///   - else method invokes super implementation equivalent, which distributes self constraints undivided to all children.
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

  /// Post descend after NonGreedy children, finds and applies constraints on Greedy children.
  ///
  /// In some detail,
  ///   - finds the constraint on self that remains after NonGreedy are given the (non greedy) space they want
  ///   - divides the remaining constraints into smaller constraints for all Greedy children in the greedy ratio
  ///   - applies the smaller constraints on Greedy children.
  ///
  /// This is required before we can layout Greedy children.
  void _layout_Post_NonGreedy_FindConstraintRemainingAfterNonGreedy_DivideIt_And_ApplyOnGreedy() {
    // Note: non greedy children have layout size when we reach here

    if (_hasGreedy) {
      // Force Align=left, Packing=tight, no matter what the Row properties are. Rects
      // The reason we want to use tight left align, is that if there are greedy children, we want them to take
      //   all remaining space. So any non-tight packing, center or right align, does not make sense if Greedy are present.
      LengthsPositionerProperties storedLayout = mainAxisLayoutProperties;
      _forceMainAxisLayoutProperties(align: Align.start, packing: Packing.tight);

      // Get the NonGreedy [layoutSize](s), call this layouter layout method,
      // which returns [positionedRectsInMe] rectangles relative to self where children should be positioned.
      // We create [nonGreedyBoundingRect] that envelope the NonGreedy children, tightly layed out
      // in the Column/Row direction. This is effectively a pre-positioning of children is self
      List<ui.Rect> positionedRectsInMe = layout_Post_NotLeaf_PositionChildren(_nonGreedyChildren);
      ui.Rect nonGreedyBoundingRect = util_flutter.boundingRectOfRects(positionedRectsInMe);
      assert(nonGreedyBoundingRect.topLeft == ui.Offset.zero);

      // After pre-positioning to obtain children sizes without any spacing, put back axis properties
      //  - next time this layouter will layout children using the original properties
      _forceMainAxisLayoutProperties(packing: storedLayout.packing, align: storedLayout.align);

      // Create new constraints ~constraintsRemainingForGreedy~ which is a difference between
      //   self original constraint, and  nonGreedyChildrenSize
      BoxContainerConstraints constraintsRemainingForGreedy = constraints.deflateWithSize(nonGreedyBoundingRect.size);

      // Divides constraintsRemainingForGreedy~into the ratios greed / sum(greed), creating ~greedyChildrenConstaints~
      List<BoundingBoxesBase> greedyChildrenConstraints = constraintsRemainingForGreedy.divideUsingStrategy(
        divideIntoCount: _greedyChildren.length,
        divideStrategy: ConstraintsDistribution.intWeights,
        layoutAxis: mainLayoutAxis,
        intWeights: _greedyChildren.map((child) => child.greed).toList(),
      );

      // Apply on greedyChildren their new greedyChildrenConstraints
      assert(greedyChildrenConstraints.length == _greedyChildren.length);
      for (int i = 0; i < _greedyChildren.length; i++) {
        Greedy greedyChild = _greedyChildren[i];
        BoxContainerConstraints childConstraint = greedyChildrenConstraints[i] as BoxContainerConstraints;
        greedyChild.applyParentConstraints(this, childConstraint);
      }
    }
  }

  /// Support which allows to enforce non-positioning of nested extensions.
  ///
  /// To explain, in one-pass layout, if we want to keep the flexibility
  /// of children getting full constraint from their parents,
  /// only the topmost [Row] can offset their children.
  ///
  /// Nested [Row]s must not offset, as for example right alignment on a nested
  /// [Row] would make all children to take up the whole available constraint from parent,
  /// and the next  [Row] up has no choice but to move it to the right.
  void _forceMainAxisLayoutProperties({
    required Packing packing,
    required Align align,
  }) {
    mainAxisLayoutProperties = LengthsPositionerProperties(
      align: align,
      packing: packing,
    );
  }

  /* Keep
  void _forceCrossAxisLayoutProperties({
    required Packing packing,
    required Align align,
  }) {
    crossAxisLayoutProperties = LengthsPositionerProperties(packing: packing, align: align);
  }
  */

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
  ///   - Both main and cross axis properties are members of this [RollingPositioningBoxLayouter].
  ///   - The offset on each notGreedyChild element is calculated using the [mainAxisLayoutProperties]
  ///     in the main axis direction, and the [crossAxisLayoutProperties] in the cross axis direction.
  @override
  List<ui.Rect> layout_Post_NotLeaf_PositionChildren(List<LayoutableBox> children) {
    if (isLeaf) {
      return [];
    }
    // Create a LayedoutLengthsPositioner along each axis (main, cross), convert it to LayoutSegments,
    // then package into a wrapper class.
    _MainAndCrossPositionedSegments mainAndCrossPositionedSegments =
    _positionChildrenUsingOneDimAxisLayouter_As_PositionedLineSegments(children);
    // print(
    //     'mainAxisLayedOutSegments.lineSegments = ${mainAndCrossLayedOutSegments.mainAxisLayedOutSegments.lineSegments}');
    // print(
    //     'crossAxisLayedOutSegments.lineSegments = ${mainAndCrossLayedOutSegments.crossAxisLayedOutSegments.lineSegments}');

    // Convert the line segments to [Offset]s (in each axis). Children will be moved (offset) by the obtained [Offset]s.
    List<ui.Rect> positionedRectsInMe = mainAndCrossPositionedSegments._convertPositionedSegmentsToRects(
      mainLayoutAxis: mainLayoutAxis,
      children: children,
    );
    // print('positionedRectsInMe = $positionedRectsInMe');
    return positionedRectsInMe;
  }

  /// Given the [children], which may be smaller than full children list,
  /// uses this [RollingPositioningBoxLayouter] [mainAxisLayoutProperties] and [crossAxisLayoutProperties]
  /// to find children positions in self.
  ///
  /// This method finds and returns the children positions in a 'primitive one-dimensional format',
  /// using [LayedOutLineSegments] along main and cross axis, as [_MainAndCrossLayedOutSegments].
  ///
  /// Further methods convert the returned 'primitive one-dimensional format'
  /// [_MainAndCrossLayedOutSegments], into rectangles representing children positions in self.
  ///
  _MainAndCrossPositionedSegments _positionChildrenUsingOneDimAxisLayouter_As_PositionedLineSegments(List<LayoutableBox> children) {
    // From the sizes of the [children] create a LayedoutLengthsPositioner along each axis (main, cross).
    var crossLayoutAxis = axisPerpendicularTo(mainLayoutAxis);

    LayedoutLengthsPositioner mainAxisLayedoutLengthsPositioner = LayedoutLengthsPositioner(
      lengths: layoutSizesOfChildrenSubsetAlongAxis(mainLayoutAxis, children),
      lengthsPositionerProperties: mainAxisLayoutProperties,
      lengthsConstraint: constraints.maxLengthAlongAxis(mainLayoutAxis),
    );

    LayedoutLengthsPositioner crossAxisLayedoutLengthsPositioner = LayedoutLengthsPositioner(
      lengths: layoutSizesOfChildrenSubsetAlongAxis(crossLayoutAxis, children),
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
    PositionedLineSegments mainAxisPositionedSegments = mainAxisLayedoutLengthsPositioner.positionLengths();
    PositionedLineSegments crossAxisPositionedSegments = crossAxisLayedoutLengthsPositioner.positionLengths();

    _MainAndCrossPositionedSegments mainAndCrossPositionedSegments = _MainAndCrossPositionedSegments(
      mainAxisPositionedSegments: mainAxisPositionedSegments,
      crossAxisPositionedSegments: crossAxisPositionedSegments,
    );
    return mainAndCrossPositionedSegments;
  }
}

/// Layouter lays out children in a rolling row, which may overflow if there are too many or too large children.
class Row extends RollingPositioningBoxLayouter {
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
class Column extends RollingPositioningBoxLayouter {
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

/// Mixin provides the role of a layouter which uses externally-defined positions (ticks) to position it's children.
///
/// The externally-defined positions (ticks) are brought in by the [ExternalTicksLayoutProvider].
// todo-00! DO WE EVEN NEED THIS mixin?? PROBABLY NOT,
mixin ExternalRollingPositioningTicks on RollingPositioningBoxLayouter {
  // knows _ExternalTicksLayoutProvider
  // overrides from RollingPositioningBoxLayouter:
  //   - method which calculates positions with children rectangles from positioned
}

class ExternalTicksColumn extends Column with ExternalRollingPositioningTicks {
  ExternalTicksColumn({
    required List<BoxContainer> children,
    // todo-00!! provide some way to express that for ExternalRollingPositioningTicks, Both Align and Packing should be Packing.externalTicksDefined.
    Align mainAxisAlign = Align.start,
    // mainAxisPacking not set, positions provided by external ticks: Packing mainAxisPacking = Packing.tight,
    Align crossAxisAlign = Align.start,
    Packing crossAxisPacking = Packing.matrjoska,
    ConstraintsWeight mainAxisConstraintsWeight = ConstraintsWeight.defaultWeight,
    required ExternalTicksLayoutProvider mainAxisExternalTicksLayoutProvider,
  }) : super(
    children: children,
    mainAxisAlign: mainAxisAlign,
    mainAxisPacking: Packing.externalTicksProvided,
    crossAxisAlign: crossAxisAlign,
    crossAxisPacking: crossAxisPacking,
    mainAxisConstraintsWeight: mainAxisConstraintsWeight,
  ) {
    // done in Column : mainLayoutAxis = LayoutAxis.vertical;
    mainAxisLayoutProperties = LengthsPositionerProperties(
      align: mainAxisAlign,
      packing: Packing.externalTicksProvided, // mainAxisPacking,
      externalTicksLayoutProvider: mainAxisExternalTicksLayoutProvider,
    );
    crossAxisLayoutProperties = LengthsPositionerProperties(
      align: crossAxisAlign,
      packing: crossAxisPacking,
    );
  }
}

class ExternalTicksRow extends Row with ExternalRollingPositioningTicks {
  ExternalTicksRow({
    required List<BoxContainer> children,
    Align mainAxisAlign = Align.start,
    // mainAxisPacking not set, positions provided by external ticks: Packing mainAxisPacking = Packing.tight,
    Align crossAxisAlign = Align.center,
    Packing crossAxisPacking = Packing.matrjoska,
    ConstraintsWeight mainAxisConstraintsWeight = ConstraintsWeight.defaultWeight,
    required ExternalTicksLayoutProvider mainAxisExternalTicksLayoutProvider,
  }) : super(
    children: children,
    mainAxisAlign: mainAxisAlign,
    mainAxisPacking: Packing.externalTicksProvided,
    crossAxisAlign: crossAxisAlign,
    crossAxisPacking: crossAxisPacking,
    mainAxisConstraintsWeight: mainAxisConstraintsWeight,
  ) {
    // done in Column : mainLayoutAxis = LayoutAxis.vertical;
    mainAxisLayoutProperties = LengthsPositionerProperties(
      align: mainAxisAlign,
      packing: Packing.externalTicksProvided, // mainAxisPacking,
      externalTicksLayoutProvider: mainAxisExternalTicksLayoutProvider,
    );
    crossAxisLayoutProperties = LengthsPositionerProperties(
      align: crossAxisAlign,
      packing: crossAxisPacking,
    );
  }
}

/// Layouter which asks it's parent [RollingPositioningBoxLayouter] to allocate as much space
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
    ui.Rect positionedChildrenOuterRects =  util_flutter
        .boundingRectOfRects(positionedChildrenRects.map((ui.Rect childRect) => childRect).toList(growable: false));
    // childrenOuterRectangle is ONLY needed for asserts. Can be removed for performance.
    ui.Rect childrenOuterRectangle = util_flutter
        .boundingRectOfRects(_children.map((BoxLayouter child) => child._boundingRectangle()).toList(growable: false));
    assert(childrenOuterRectangle.size == positionedChildrenOuterRects.size);

    ui.Size greedySize = constraints.maxSize; // use the portion of this size along main axis
    ui.Size childrenLayoutSize = positionedChildrenOuterRects.size; // use the portion of this size along cross axis

    if (_parent is! RollingPositioningBoxLayouter) {
      throw StateError('Parent of this Greedy container "$this" must be '
          'a ${(RollingPositioningBoxLayouter).toString()} but it is $_parent');
    }
    RollingPositioningBoxLayouter p = (_parent as RollingPositioningBoxLayouter);
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
  void buildAndReplaceChildren(covariant LayoutContext layoutContext) {
    buildAndReplaceChildrenDefault(layoutContext);
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
///   - Decreases own constraint by Padding and provides it do a child
///   - When child returns it's [layoutSize], this layouter sets it's size as that of the child, surrounded with
///     the [EdgePadding] [edgePadding].
///
/// This governs implementation:
///   - [Padder] uses the default [layout].
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
/// then aligns the single child within resized self.
///
/// The resizing of self makes self typically larger than the child, although not necessarily.
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
  }) : super(children: [child]) {
    assert(childWidthBy >= 1 && childHeightBy >= 1);
  }

  final Alignment alignment;
  final double childWidthBy;
  final double childHeightBy;

  /// This override passes the immediate children of this [Aligner]
  /// the constraints that are deflated from self constraints by the
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
    ui.Size selfLayoutSize = _selfLayoutSizeFromChild(child.layoutSize);
    List<ui.Rect> positionedRectsInMe = [
      _positionChildInSelf(
        selfSize: selfLayoutSize,
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
    required ui.Size selfSize,
    required ui.Size childSize,
  }) {
    return _offsetChildInSelf(
      selfSize: selfSize,
      childSize: childSize,
    ) &
    childSize;
  }

  /// Child offset function implements the positioning the child in self, mandated by this [Aligner].
  ///
  /// Given a [selfSize], a [childSize], returns the child offset in self,
  /// calculated from members [alignment],  [childWidthBy], [childHeightBy].
  ///
  /// See discussion in [Alignment] for the positioning of child in [Aligner], given [Alignment].
  ui.Offset _offsetChildInSelf({
    required ui.Size selfSize,
    required ui.Size childSize,
  }) {
    double childWidth = childSize.width;
    double childHeight = childSize.height;

    /// The child is then positioned in the [Aligner] at offset controlled by [alignX] and [alignY]:
    double childTopLefOffsetX = (childWidth * (childWidthBy - 1)) * (alignment.alignX + 1) / 2;
    double childTopLefOffsetY = (childHeight * (childHeightBy - 1)) * (alignment.alignY + 1) / 2;

    return ui.Offset(childTopLefOffsetX, childTopLefOffsetY);
  }
}

// Helper classes ------------------------------------------------------------------------------------------------------

/// This class controls how layouters implementing the mixin [ExternalTicksRollingPositioning] position their children
/// along their main axis.
///
/// It manages all the directives the [ExternalTicksRollingPositioning] need to position their children
/// in their main axis direction.
///
/// It's useful role is provided by the method [lextrValuesToPixels], which,
/// given the axis pixels range, (assumed in the pixel coordinate range), extrapolates the [tickValues]
/// to layouter-relative positions on the axis, to which the layouter children will be positioned.
///
/// Specifically, this class provides the following directives for the layouters
/// that are [ExternalTicksRollingPositioning]:
///   - [tickValues] is the relative positions on which the children are placed
///   - [tickValuesDomain] is the interval in which the relative positions [tickValues] are.
///     [tickValuesDomain] must include all [tickValues];
///     it's boundaries may be larger than the envelope of all [tickValues]
///   - [isAxisPixelsAndDisplayedValuesInSameDirection] defines whether the axis pixel positions and [tickValues]
///     are run in the same direction.
///   - [externalTickAt] the information what point on the child should be placed at the tick value:
///     child's start, center, or end. This is expressed by [ExternalTickAt.childStart] etc.
///
/// Note: The parameter names use the term 'value' not 'position', as they represent
///        data values ('transformed' but NOT 'extrapolated to pixels').
///
/// Important note: Although not clear from this class, should ONLY position along the main axis.
///                 This is reflected in one-dimensionality of [tickValues] and [externalTickAt]
///
class ExternalTicksLayoutProvider {

  ExternalTicksLayoutProvider({
    required this.tickValues,
    required this.tickValuesDomain,
    required this.isAxisPixelsAndDisplayedValuesInSameDirection,
    required this.externalTickAt,
});

  /// Represent future positions of children of the layouter controlled
  /// by this ticks provider [ExternalTicksLayoutProvider].
  /// 
  /// By 'future positions' we mean the [tickValues] after extrapolation to axis pixels, 
  /// to be precise, [tickValues] extrapolated by [lextrValuesToPixels] when passed axis pixels range.
  /// 
  final List<double> tickValues;

  final util_dart.Interval tickValuesDomain;

  final bool isAxisPixelsAndDisplayedValuesInSameDirection;

  final ExternalTickAt externalTickAt;

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
  List<double> lextrValuesToPixels(util_dart.Interval axisPixelsRange) {
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
              toPixelsMin: axisPixelsRange.min,
              toPixelsMax: axisPixelsRange.max,
              doInvertToDomain: !isAxisPixelsAndDisplayedValuesInSameDirection,
            ).apply(value))
        .toList();
  }
/*

  double lextrValueToPixels({
    required double value,
    required double axisPixelsMin,
    required double axisPixelsMax,
  }) {
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
    // lextr the data value range [dataRange] on this [DataRangeLabelInfosGenerator] to the pixel range.
    // The pixel range must be the pixel range available to axis after [BoxLayouter.layout].
    return util_dart.ToPixelsExtrapolation1D(
      fromValuesMin: dataRange.min,
      fromValuesMax: dataRange.max,
      toPixelsMin: axisPixelsYMin,
      toPixelsMax: axisPixelsYMax,
      doInvertToDomain: !isAxisPixelsAndDisplayedValuesInSameDirection,
    ).apply(value);
  }
*/


}

enum ExternalTickAt {
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

/// On behalf of [RollingPositioningBoxLayouter], holds on the results of 1Dimensional positions of children
/// along the main and cross axis, calculated
/// by [RollingPositioningBoxLayouter._positionChildrenUsingOneDimAxisLayouter_As_PositionedLineSegments].
///
/// The 1Dimensional positions are held in [mainAxisPositionedSegments] and [crossAxisPositionedSegments]
/// as [PositionedLineSegments.lineSegments].
///
/// The method [_convertPositionedSegmentsToRects] allows to convert such 1Dimensional positions along main and cross axis
/// into rectangles [List<ui.Rect>], where children of self [BoxLayouter] node should be positioned.
///
class _MainAndCrossPositionedSegments {
  _MainAndCrossPositionedSegments({
    required this.mainAxisPositionedSegments,
    required this.crossAxisPositionedSegments,
  });

  PositionedLineSegments mainAxisPositionedSegments;
  PositionedLineSegments crossAxisPositionedSegments;

  /// Converts the line segments from [mainAxisPositionedSegments] and [crossAxisPositionedSegments]
  /// (they correspond to children widths and heights that have been layed out)
  /// to [ui.Rect]s, the rectangles where children of self [BoxLayouter] node should be positioned.
  ///
  /// Children should be offset later in [layout] by the obtained [Rect.topLeft] offsets;
  ///   this method does not change any offsets of self or children.
  List<ui.Rect> _convertPositionedSegmentsToRects({
    required LayoutAxis mainLayoutAxis,
    required List<LayoutableBox> children,
  }) {

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

}

// Functions----- ------------------------------------------------------------------------------------------------------

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
  required bool foundFirstRowFromTop,
  required bool foundFirstColumnFromTop,
  required BoxLayouter boxLayouter,
}) {
  if (boxLayouter is Row && !foundFirstRowFromTop) {
    foundFirstRowFromTop = true;
  }

  if (boxLayouter is Column && !foundFirstColumnFromTop) {
    foundFirstColumnFromTop = true;
  }

  for (var child in boxLayouter._children) {
    // pre-child, if this node or nodes above did set 'foundFirst', rewrite the child values
    // so that only the top layouter can have non-start and non-tight/matrjoska
    // todo-04 : Only push the force on children of child which are NOT Greedy - reason is, Greedy does
    //           obtain smaller constraint which should allow children further down to be rows with any align and packing.
    //           but this is not simple.
    if (child is Row && foundFirstRowFromTop) {
      child._forceMainAxisLayoutProperties(
        align: Align.start,
        packing: Packing.tight,
      );
    }
    if (child is Column && foundFirstColumnFromTop) {
      child._forceMainAxisLayoutProperties(
        align: Align.start,
        packing: Packing.matrjoska,
      );
    }

    // in-child continue to child's children with the potentially updated values 'foundFirst'
    _static_ifRoot_Force_Deeper_Row_And_Column_LayoutProperties_To_NonPositioning(
      foundFirstRowFromTop: foundFirstRowFromTop,
      foundFirstColumnFromTop: foundFirstColumnFromTop,
      boxLayouter: child,
    );
  }
}

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
