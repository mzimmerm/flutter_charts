import 'dart:ui' as ui show Size, Offset, Rect, Canvas, Paint;
import 'package:flutter/material.dart' as material;
import 'package:flutter_charts/flutter_charts.dart';
// import 'package:flutter_charts/src/chart/container.dart';

import 'package:flutter_charts/src/chart/layouter_one_dimensional.dart'
    show
    Align,
    Packing,
    LengthsPositionerProperties,
    LayedoutLengthsPositioner,
    PositionedLineSegments,
    DivideConstraintsToChildren;
import 'package:flutter_charts/src/morphic/rendering/constraints.dart' show BoundingBoxesBase, BoxContainerConstraints;
import 'package:flutter_charts/src/util/util_dart.dart' as util_dart show LineSegment;
import 'package:flutter_charts/src/util/util_flutter.dart' as util_flutter show boundingRectOfRects;

import '../util/collection.dart' as custom_collection show CustomList;

mixin BoxContainerHierarchy {
  late final BoxContainer? parent; // will be initialized when addChild(this) is called on this parent
  // Important:
  //  1. Removed the late final on children. Some extensions (eg. LineChartContainer)
  //          need to start with empty array, initialized in BoxContainer.
  //          Some others, e.g. BoxLayouter need to pass it (which fails if already initialized
  //          in BoxContainer)
  //  2. can we make children a getter, or hide it somehow, so establishing hierarchy parent/children is in methods?
  // todo-01-last : work on incorporating this null-like singleton ChildrenNotSetSingleton everywhere, and add asserts as appropriate
  List<BoxContainer> children = NullLikeListSingleton();

  bool get isRoot => parent == null;

  bool get isLeaf => children.isEmpty;

  BoxContainer? _root;

  BoxContainer get root {
    if (_root != null) {
      return _root!;
    }

    if (parent == null) {
      _root = children[0].parent; // cannot be 'this' as 'this' is ContainerHiearchy, so go through children, must be one
      return _root!;
    }

    BoxContainer rootCandidate = parent!;

    while (rootCandidate.parent != null) {
      rootCandidate = rootCandidate.parent!;
    }
    _root = rootCandidate;
    return _root!;
  }

  @Deprecated(
      '[addChildToHierarchyDeprecated] is deprecated, since BoxContainerHierarchy should be fully built using its children array')
  void addChildToHierarchyDeprecated(BoxContainer thisBoxContainer, BoxContainer childOfThis) {
    childOfThis.parent = thisBoxContainer;
    children.add(childOfThis);
    // throw StateError('This is deprecated.');
  }
}

// todo-01-document as interface for [BoxLayouter] and [BoxContainer].
// todo-00 : Why do we really need this? For use in places where a box only has layoutSize, but no children etc? For positioning in parent??
abstract class LayoutableBox {
  /// Size after the box has been layed out.
  ///
  /// Each [BoxContainer] node method [newCoreLayout] must be able to set this [layoutSize]
  ///    on itself after all children were layed out.
  ///
  /// todo-01-last
  /// Important note: [layoutSize] is not set by parent, but it is accessed (get) by parent.
  ///                So maybe setter could be here, getter also here
  ui.Size layoutSize = ui.Size.zero;

  // todo-00-last : moved here as interface to BoxLayouter
  ui.Offset get offset => const ui.Offset(0.0, 0.0);


  void applyParentOffset(BoxLayouter caller, ui.Offset offset);

  void applyParentOrderedSkip(BoxLayouter caller, bool orderedSkip);

  void applyParentConstraints(BoxLayouter caller, BoxContainerConstraints constraints);

  void newCoreLayout();
}

/// Mixin provides role of a generic layouter for a one [LayoutableBox] or a list of [LayoutableBox]es.
///
/// The core functions of this class is to position their children
/// using [_post_NotLeaf_PositionChildren] in self,
/// then apply the positions as offsets onto children in [_post_NotLeaf_OffsetChildren].
///
/// Layouter classes with this mixin can be divided into two categories,
/// if they use the default [newCoreLayout] :
///
///   - *positioning* layouters position their children in self (potentially and likely to non-zero position).
///     This also implies that during layout, the position is converted into offsets , applied to it's children.
///     As a result, we consider extensions being *positioning* is equivalent to being *offsetting*.
///     Implementation-wise, *positioning* (and so *offsetting*)
///     extensions must implement both [_post_NotLeaf_PositionChildren] and [_post_NotLeaf_OffsetChildren].
///     Often, the offset method can use the default, but the positioning method should be overriden.
///
///   - *non-positioning* (equivalent to *non-offsetting*) should implement both positioning
///     and offsetting methods as non-op.
///     If the positioning method is implemented does not hurt (but it's useless)
///     as long as the offssetting method is no-op.
///

mixin BoxLayouter on BoxContainerHierarchy implements LayoutableBox {
  // Important Note: Mixin fields can still be final, bust must be late, as they are
  //   always initialized in concrete implementations constructors or their initializer list.

  // 1. Overrides implementing all methods from implemented interface [LayoutableBox] ---------------------------------

  /// Manages the layout size, the result of [newCoreLayout].
  ///
  /// Set late in [newCoreLayout], once the layout size is known after all children were layed out.
  /// Extensions of [BoxLayouter] should not generally override, even with their own layout.
  // todo-00-last : is this override needed?
  @override
  late final ui.Size layoutSize;

  // offset ---
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

  /// Allows a parent container to move this container after [layout].
  ///
  /// Override if parent move needs to propagate to internals of
  /// this [BoxLayouter].
  ///
  /// Important override notes and rules for [applyParentOffset] on extensions:
  ///  1) Generally, neither leafs nor non-leafs need to override [applyParentOffset],
  ///     as this method is integral part of autolayout (as is [newCoreLayout]).
  ///  2) Exception would be [BoxLayouter]s that want to use manual or semi-manual
  ///     layout process. Those would generally (always?) be leafs, and they would do the following:
  ///       - Override [newCoreLayout] (no super call), do manual layout calculations,
  ///         likely store the result as member (see [LabelContainer._tiltedLabelEnvelope],
  ///         and set [layoutSize] at the end, so parent can pick it up
  ///       - Override [applyParentOffset] as follows:
  ///          - likely call super [applyParentOffset] to set overall offset in parent.
  ///          - potentially re-offset the position as a result of the manual layout
  ///            (see [LabelContainer.offsetOfPotentiallyRotatedLabel]) and store result as member.
  ///        - Override [paint] by painting on the calculated (parent also applied) offset,
  ///           (see [LabelContainer.paint].
  ///
  @override
  void applyParentOffset(BoxLayouter caller, ui.Offset offset) {
    _assertCallerIsParent(caller);

    if (orderedSkip) return;

    _offset += offset;

    for (var child in children) {
      child.applyParentOffset(this, offset);
    }
  }

  // orderedSkip ---
  bool _orderedSkip = false; // want to be late final but would have to always init.

  /// [orderedSkip] is set by parent; instructs this container that it should not be
  /// painted or layed out - as if it collapsed to zero size.
  ///
  /// When set to true, implementations must add appropriate support for collapse.
  bool get orderedSkip => _orderedSkip;

  /// Set private member [_orderedSkip] with assert that caller is parent
  ///
  /// todo-00-document   /// Important override notes and rules for [applyParentOrderedSkip] on extensions:
  @override
  void applyParentOrderedSkip(BoxLayouter caller, bool orderedSkip) {
    _assertCallerIsParent(caller);
    _orderedSkip = orderedSkip;
  }

  // constraints ---
  /// Constraints set by parent.
  late final BoxContainerConstraints _constraints;

  BoxContainerConstraints get constraints => _constraints;

  /// Set private member [_constraints] with assert that the caller is parent
  @override
  void applyParentConstraints(BoxLayouter caller, BoxContainerConstraints constraints) {
    _assertCallerIsParent(caller);
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
  /// GreedyLayouter would take layoutSize infinity, but do not check that here, as layoutSize is late and not yet set
  ///   when this is called in [newCoreLayout].
  bool get isGreedy => false;

  bool get hasGreedyChild => children.where((child) => child.isGreedy).isNotEmpty;

  BoxLayouter get firstGreedyChild => children.firstWhere((child) => child.isGreedy);

  // ------------------------------------------------------------------------------------------------------------------------

  /// Sandbox-type helper field : none so far

  // ------------------------------------------------------------------------------------------------------------------------
  void _assertCallerIsParent(BoxLayouter caller) {
    if (parent != null) {
      if (!identical(caller, parent)) {
        throw StateError('on this $this, parent $parent should be == to caller $caller');
      }
    }
  }

  /// Old layout forwards to [newCoreLayout].
  // todo-01-last : pass BoxLayouter not BoxContainer
  void layout(BoxContainerConstraints boxConstraints, BoxContainer parentBoxContainer) {
    if (this is LegendItemContainer ||
        this is LegendIndicatorRectContainer ||
        // this is LabelContainer ||
        // Remove as new layout rendering starts with RowLayouter : this is RowLayouter ||
        this is ColumnLayouter) {
      throw StateError('Should not be called on $this');
    }
    newCoreLayout();
  }

  /// todo-01-document fully
  ///
  /// Assumptions:
  ///   1. Before calling this method, [constraints] must be set at least on the root of the [BoxContainerHierarchy].
  /// Important override notes and rules for [newCoreLayout] on extensions:
  ///   1: Everywhere in docs, by 'layouter specific processing', we mean there is code which auto-layouts all known layouters
  ///      [RowLayouter], [ColumnLayouter] etc, using their set values of [Packing] and [Align].
  ///
  ///   2: General rules for [newCoreLayout] on extensions
  ///      1) Generally, leafs do not need to override [newCoreLayout],
  ///         as their only role in the layout process is to set and announce their [layoutSize]
  ///         to their parents
  ///      2) Non-leafs do often need to override some methods invoked from [newCoreLayout],
  ///         or the whole [newCoreLayout]. Some details on Non-Leafs
  ///         - Non-positioning Non-leafs: Generally only need to override [_post_NotLeaf_PositionChildren] to return .
  ///           If mostly do not need to override [newCoreLayout] at all,
  ///           unless they wish to distribute constraints to children differently from the default,
  ///           passing the full constraint to all children.
  ///           The empty
  ///         as this method is integral part of autolayout (as is [applyParentOffset]).
  ///      2) Exception would be [BoxLayouter]s that want to use manual or semi-manual
  ///         layout process.
  ///           - On Leaf: override [newCoreLayout] (no super call), do manual layout calculations,
  ///             likely store the result as member (see [LabelContainer._tiltedLabelEnvelope],
  ///             and set [layoutSize] at the end. This is already described in [BoxLayouter.applyParentOffset]
  ///           - Potentially - this would be a hack PARENT of the leaf also may need to override[newCoreLayout], where it :
  ///             - Perform layout logic to set some size-related value on it's child. We do not have example,
  ///               as we moved this stuff from [LabelContainer] parent [LegendItemContainer] to [LabelContainer] .
  ///               See around [_layoutLogicToSetMemberMaxSizeForTextLayout]
  ///
  @override
  void newCoreLayout() {
    // print('In newCoreLayout: this = $this. this.children = $children.');
    // print('In newCoreLayout: parent of $this = $parent.');

    _layout_IfRoot_DefaultTreePreprocessing();

    // A. node-pre-descend. Here, children to not have layoutSize yet. Constraint from root down should be set
    _layout_DefaultRecurse();
  }

  // 2. Non-override new methods on this class, starting with layout methods -------------------------------------------

  // 2.1 Layout methods

  void _layout_IfRoot_DefaultTreePreprocessing() {
    if (isRoot) {
      // todo-01 : rethink, what this size is used for. Maybe create a singleton 'uninitialized constraint' - maybe ther is one already?
      assert(constraints.size != const ui.Size(-1.0, -1.0));
      // On nested levels [RowLayouter]s OR [ColumnLayouter]s
      // force non-positioning layout properties.
      // This is a hack that unfortunately make this baseclass [BoxLayouter]
      // to depend on it's extensions [ColumnLayouter] and [RowLayouter]
      _static_ifRoot_Force_Deeper_Row_And_Column_LayoutProperties_To_NonPositioning(
        foundFirstRowLayouterFromTop: false,
        foundFirstColumnLayouterFromTop: false,
        boxLayouter: this,
      );
    }
  }

  void _layout_DefaultRecurse() {
    // A. node-pre-descend. Here, children to not have layoutSize yet. Constraint from root down should be set
    _preDescend_DistributeConstraintsToImmediateChildren(children);

    // B. node-descend
    for (var child in children) {
      // 1. child-pre-descend (empty)
      // 2. child-descend
      child.newCoreLayout();
      // 3. child-post-descend (empty)
    }
    // C. node-post-descend.
    //    Here, children have layoutSizes, which are used to lay them out in me, then offset them in me
    _postDescend_IfLeaf_SetSize_IfNotLeaf_PositionThenOffsetChildren_ThenSetSize_Finally_AssertSizeInsideConstraints();
  }

  /// This [BoxLayouter]'s default implementation distributes this layouter's unchanged
  /// and undivided constraints onto it's immediate children before descending to children [newCoreLayout].
  ///
  ///  This is not recursive - the constraints are applied only on immediate children.
  ///
  /// The semantics of 'distribute constraint to children' is layout specific:
  ///   - This implementation and any common layout: pass it's constraints onto it's children unchanged.
  ///     As a result, each child will be allowed to get up to it's parent constraints size.
  ///     If all children were to use the constraint sizes fully, and set their sizes that large,
  ///     the owner layouter would overflow, but the assumption is children only use a fraction of available constraints.
  ///   - Specific implementation (e.g. [IndividualChildConstrainingRowLayouter])
  ///     may 'divide' it's constraints evenly or unevenly to children, passing each
  ///     a fraction of it's constraint.
  ///
  void _preDescend_DistributeConstraintsToImmediateChildren(List<BoxContainer> children) {
    // todo-00-later : not yet : wait for expand=false as default : crossAxisLayoutProperties.totalLength = constraints.maxLengthAlongAxis(axisPerpendicularTo(mainLayoutAxis));
    for (var child in children) {
      child.applyParentConstraints(this, constraints);
    }
  }

  /// The wrapper of the 'layouter specific processing' in post descend.
  ///
  /// Preconditions:
  ///   - all [constraints] are distributed in
  ///     pre-descend [_preDescend_DistributeConstraintsToImmediateChildren].
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
      _postDescend_IfLeaf_SetSize_IfNotLeaf_PositionThenOffsetChildren_ThenSetSize_Finally_AssertSizeInsideConstraints() {
    if (isLeaf) {
      post_Leaf_SetSize_FromInternals();
    } else {
      _post_NotLeaf_PositionThenOffsetChildren_ThenSetSize();
    }
    _post_AssertSizeInsideConstraints();
  }

  /// Performs the CORE of the 'layouter specific processing',
  /// by finding all children [offset]s according to layout, then setting the [layoutSize] of non-leaf nodes.
  ///
  /// Assumes that [constraints] have been set in [_preDescend_DistributeConstraintsToImmediateChildren].
  ///
  /// Final side effect result must always be to set [layoutSize] on this node.
  void _post_NotLeaf_PositionThenOffsetChildren_ThenSetSize() {
    // Common processing for greedy and non-greedy:
    // First, calculate children offsets within self.
    // Note: - When the greedy child is re-layed out, it has a final size (remainder after non greedy sizes added up),
    //         we can deal with the greedy child as if non greedy child.
    //       - no-op on baseclass [BoxLayouter].
    List<ui.Rect> positionedRectsInMe = _post_NotLeaf_PositionChildren(children);

    // Apply the calculated layedOutRectsInMe as offsets on children.
    _post_NotLeaf_OffsetChildren(positionedRectsInMe, children);
    // Finally, when all children are at the right offsets within me, invoke
    // [_post_NotLeaf_SetSize_FromPositionedChildren] to set the layoutSize on me.
    //
    // My [layoutSize] CAN be calculated using one of two equivalent methods:
    //   1. Query all my children for offsets and sizes, create each child rectangle,
    //      then create bounding rectangle from them.
    //   2. Use the previously created [positionedRectsInMe], which is each child rectangle,
    //      then create bounding rectangle of [positionedRectsInMe].
    // In [_post_NotLeaf_SetSize_FromPositionedChildren] we use method 2, but assert sameness between them
    // todo-00-last-last-last : try to pass positionedChildrenRects, and change implementations
    //                          to use that instead of quering child positions.
    //                          this opens some interesting asserts, that the results from children must agree
    //                          also rename to  _post_NotLeaf_SetSize_FromChildrenPositionedRects
    // must do tests before / after
    _post_NotLeaf_SetSize_FromPositionedChildren(positionedRectsInMe);
  }

  /// [_post_NotLeaf_PositionChildren] is a core method of the default [newCoreLayout]
  /// which positions the invoker's children in self.
  ///
  /// [_post_NotLeaf_PositionChildren] is abstract in [BoxLayouter] and no-op in [BoxContainer] (returning empty list,
  /// which causes no positioning of children.
  ///
  /// Implementations should lay out children of the invoking [BoxLayouter],
  /// and return [List<ui.Rect>], a list of rectangles [List<ui.Rect>]
  /// where children will be placed relative to the invoker, in the order of the passed [children].
  ///
  /// On a leaf node, implementations should return an empty list.
  ///
  /// *Important*: When invoked on a [BoxLayouter] instance, it is assumed it's children were already layed out;
  ///              so this should be invoked in any layout algorithm in the children-post-descend section.
  ///
  /// In the default [newCoreLayout] implementation, this message [_post_NotLeaf_PositionChildren]
  /// is send by the invoking [BoxLayouter] to self, during the children-past-descend.
  ///
  /// Important Definition:
  ///   If a method name has 'PositionChildren' in it's name, it means:
  ///    - It is invoked on a node that is a parent (so self = parent)
  ///    - The method should do the following:
  ///      - Arrange for self to ask children their layout sizes. Children MUST have already
  ///        been recursively layed out!! (Likely by invoking child.newCoreLayout recursively).
  ///      - Arrange for self to use children layout sizes and it's positioning algorithm
  ///        to calculate (but NOT set) children positions (offsets) in itself
  ///        returning a list of rectangles, one for each child
  ///
  List<ui.Rect> _post_NotLeaf_PositionChildren(List<LayoutableBox> children);

  /// An abstract method of the default [newCoreLayout] which role is to
  /// offset the [children] by the pre-calculated offsets [layedOutRectsInMe] .
  ///
  /// Important override notes and rules for [_post_NotLeaf_OffsetChildren] on extensions:
  ///
  ///   - Positioning extensions should invoke [BoxLayouter.applyParentOffset]
  ///     for all children in argument [children] and apply the [Rect.topLeft]
  ///     offset from the passed [layedOutRectsInMe].
  ///   - Non-positioning extensions (notably BoxContainer) should make this a no-op.
  ///
  /// First argument should be the result of [_post_NotLeaf_PositionChildren],
  /// which is a list of layed out rectangles [List<ui.Rect>] of [children].
  void _post_NotLeaf_OffsetChildren(List<ui.Rect> positionedRectsInMe, List<LayoutableBox> children);

  /// The responsibility of [_post_NotLeaf_SetSize_FromPositionedChildren]
  /// is to set the [layoutSize] of self.
  ///
  /// In the default [newCoreLayout], at invocation time,
  /// all children have their [layoutSize]s and [offset]s set.
  ///
  /// The [layoutSize] in this default implementation is set
  /// to the size of "bounding rectangle of all positioned children".
  /// This "bounding rectangle of all positioned children" is calculated from the passed [positionedChildrenRects],
  /// which is the result of preceding invocation of [_post_NotLeaf_PositionChildren].
  ///
  /// The bounding rectangle of all positioned children, is calculated by [util_flutter.boundingRectOfRects].
  ///
  /// Note:  My [layoutSize] CAN be calculated using one of two equivalent methods:
  ///        1. Query all my children for offsets and sizes, create each child rectangle,
  ///           then create bounding rectangle from them.
  ///        2. Use the previously created [positionedRectsInMe], which is each child rectangle,
  ///           then create bounding rectangle of [positionedRectsInMe].
  ///        We use method 2, but assert sameness between them
  ///
  /// Important override notes and rules for [applyParentOrderedSkip] on extensions:
  ///   -  Only override if self needs to set the layoutSize bigger than the outer rectangle of children.
  ///      Overriding extensions include layouts which do padding,
  ///      or otherwise increase their sizes, such as [GreedyLayouter].
  ///
  /// todo-00-last-last-last : Add parameter List<ui.Rect> positionedChildrenRects the result of from [_post_NotLeaf_PositionChildren]
  ///                          and change implementation
  void _post_NotLeaf_SetSize_FromPositionedChildren(List<ui.Rect> positionedChildrenRects) {
    assert(!isLeaf);
    // todo-00-last-last-last : After changing the imlemention (Rect of children used), keep this code
    //                            but add assert that the childrenOuterRectangle.size matches the passed rect.size.
    //                          ALSO, childrenOuterRectangle.offset must be positionedChildrenRects.offset .

    ui.Rect positionedChildrenOuterRects =  util_flutter
        .boundingRectOfRects(positionedChildrenRects.map((ui.Rect childRect) => childRect).toList(growable: false));
    // childrenOuterRectangle is ONLY needed for asserts. Can be removed for performance.
    ui.Rect childrenOuterRectangle = util_flutter
        .boundingRectOfRects(children.map((BoxLayouter child) => child._boundingRectangle()).toList(growable: false));
    assert(childrenOuterRectangle.size == positionedChildrenOuterRects.size); // todo-00-last-last-last : folse for column :

    layoutSize = positionedChildrenOuterRects.size;
  }

  void _post_NotLeaf_SetSize_FromPositionedChildren_OLD() {
    assert(!isLeaf);
    ui.Rect childrenOuterRectangle = util_flutter
        .boundingRectOfRects(children.map((BoxLayouter child) => child._boundingRectangle()).toList(growable: false));
    layoutSize = childrenOuterRectangle.size;
  }

  /// Leaf [BoxLayouter] extensions should override and set [layoutSize].
  ///
  /// Throws exception if sent to non-leaf, or sent to a leaf
  /// which did not override this method.
  void post_Leaf_SetSize_FromInternals() {
    if (!isLeaf) {
      throw StateError('Only a leaf can be sent this message.');
    }
    throw UnimplementedError('Method must be overriden by leaf BoxLayouters');
  }

  /// Checks if [layoutSize] box is within the [constraints] box.
  ///
  /// Throws error otherwise.
  void _post_AssertSizeInsideConstraints() {
    if (!constraints.containsFully(layoutSize)) {
      String errText = 'Layout size of this layouter $this is $layoutSize,'
          ' which does not fit inside it\'s constraints $constraints';
      // Print a red error, but continue and let the paint show black overflow rectangle
      print(errText);
      //throw StateError(errText);
    }

  }

  /// Bounding rectangle of this [BoxLayouter].
  ///
  /// It should only be called after [newCoreLayout] has been performed on this layouter.
  ui.Rect _boundingRectangle() {
    return offset & layoutSize;
  }

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
/// Effectively a [NonPositioning] class (this is inherited from [BoxLayouter] which is also [NonPositioning].
///
/// Mixin [BoxContainerHierarchy] is repeated here in [BoxContainer] and in [BoxLayouter]
/// to make clear that both [BoxContainer] and [BoxLayouter]
/// have the same  [BoxContainerHierarchy] role (capability).
///
/// Important migration notes:
/// When migrating from old layout to new layout,
///   - The child containers creation code: move from [layout] to [buildContainerOrSelf].
///   - if we move the container fully to autolayout:
///      - The 'old layouter' code should not be used;
///   - else if keeping the manual layout (see LabelContainer)
///       - the 'old layouter' code should go to [newCoreLayout].
///       - some layout values calculated from old layout that used to be passed as members to child containers creation:
///          - We need to, in the child class:
///            - make the members 'late' if final
///            - remove setting those members from child container constructors,
///            - replace with setters
///          - Then set those layout values calculated from old layout on member children in [newCoreLayout] in the new setters
///
///   - [layout] should not be called on new layout, except on 'fake' root.
///
abstract class BoxContainer extends Object with BoxContainerHierarchy, BoxLayouter implements LayoutableBox {
  /// Default empty generative constructor.
  // todo-01-last : Make ChartOptions a Singleton, so we do not have to add it here as member and constructor parameter
  BoxContainer({
    List<BoxContainer>? children,
  }) {
    if (children != null) {
      //  && this.children != ChildrenNotSetSingleton()) {
      this.children = children;
    }
    // Important: Enforce either children passed, or set in here by calling buildContainerOrSelf
    if (children == null) {
      //  &&  this.children == ChildrenNotSetSingleton()) {
      BoxContainer builtContainer = buildContainerOrSelf();
      if (builtContainer != this) {
        this.children = [builtContainer];
      } else {
        // This may require consideration .. maybe exception, because buildContainerOrSelf is never called, but
        //  I guess still can be called manually.
        this.children = [];
      }
    }
    // Make self a parent of all immediate children
    for (var child in this.children) {
      child.parent = this;
    }
  }

  /// Override of the abstract [_post_NotLeaf_PositionChildren] on instances of this base [BoxContainer].
  ///
  /// [_post_NotLeaf_PositionChildren] is abstract in [BoxLayouter] and no-op here in [BoxContainer] - by Returning empty list,
  /// results in no positioning of children,
  ///
  /// Returning an empty list here causes no offsets on children are applied,
  /// which is desired on this non-positioning base class [BoxContainer].
  ///
  /// Note: No offsets application is also achieved if [_post_NotLeaf_OffsetChildren]
  ///       does nothing. However, making [_post_NotLeaf_PositionChildren] to return empty list is a faster path,
  ///       as no layout is invoked, and empty list of children is passed to
  ///       it, which causes no offset (because of the empty list).
  ///
  @override
  List<ui.Rect> _post_NotLeaf_PositionChildren(List<LayoutableBox> children) {
    // todo-00-last : do we need this? Ah yes, before we extend BoxContainer to NonPositioningBoxLayouter, and that becomes the base class of all elements in charts
    // todo-00-last-last return [];
    // This is a no-op because it does not change children positions from where they are at their current offsets.
    return children.map((LayoutableBox child) => child.offset & child.layoutSize).toList(growable: false);
  }

  /// Implementation of the abstract default [_post_NotLeaf_OffsetChildren]
  /// invoked in the default [newCoreLayout].
  ///
  /// This class, as a non-positioning container should make this a no-op,
  /// resulting in no offsets applied on children during layout.
  @override
  void _post_NotLeaf_OffsetChildren(List<ui.Rect> positionedRectsInMe, List<LayoutableBox> children) {
    // No-op in this non-positioning base class
  }

  // todo-01-last : after new layout is used everywhere : make abstract, each Container must implement. Layouter has this no-op.
  /// todo-01-last  Important override notes and rules for [buildContainerOrSelf] on extensions:
  // Create children one after another, or do nothing if children were created in constructor.
  // Any child created here must be added to the list of children.
  //   - if (we do not want any children created here (may exist from constructor)) return
  //   - create childN
  //   - addChild(childN)
  //   - etc
  BoxContainer buildContainerOrSelf() {
    return this;
  }

  /// Painting base method of all [BoxContainer] extensions,
  /// which should paint self on the passed [canvas].
  ///
  /// This default [BoxContainer] implementation does several things:
  ///   1. Checks for layout overflows, on overflow, paints a yellow-black rectangle
  ///   2. Checks for [orderedSkip], if true, returns as no-op
  ///   3. Forwards [paint] to [children]
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

    for (var child in children) {
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

/// Layouter which is allowed to offset it's children with non zero offset.
abstract class PositioningBoxLayouter extends BoxContainer {
  /// The required unnamed constructor
  PositioningBoxLayouter({
    List<BoxContainer>? children,
  }) : super(children: children);

  /// Applies the offsets [layedOutRectsInMe] obtained by this specific [Layouter]
  /// on the [LayoutableBox]es [children].
  @override
  void _post_NotLeaf_OffsetChildren(List<ui.Rect> positionedRectsInMe, List<LayoutableBox> children) {
    assert(positionedRectsInMe.length == children.length);
    for (int i = 0; i < positionedRectsInMe.length; i++) {
      children[i].applyParentOffset(this, positionedRectsInMe[i].topLeft);
    }
  }
}

// ^ base non-positioning classes BoxLayouter and BoxContainer
// ---------------------------------------------------------------------------------------------------------------------
// v positioning classes, rolling positioning, RowLayouter and ColumnLayouter, GreedyLayouter

/// Layouter which is NOT allowed to offset it's children, or only offset with zero offset.
abstract class NonPositioningBoxLayouter extends BoxContainer {
  /// The required unnamed constructor
  NonPositioningBoxLayouter({
    List<BoxContainer>? children,
  }) : super(children: children);

  /// Override for non-positioning:
  /// Does not apply any offsets on the it's children (passed in [newCoreLayout] internals.
  @override
  void _post_NotLeaf_OffsetChildren(List<ui.Rect> positionedRectsInMe, List<LayoutableBox> children) {}

  /// Override for non-positioning:
  /// Does not need to calculate position of children in self, as it will not apply offsets anyway.
  @override
  List<ui.Rect> _post_NotLeaf_PositionChildren(List<LayoutableBox> children) {
    // todo-00-last-last return [];
    // This is a no-op because it does not change children positions from where they are at their current offsets.
    return children.map((LayoutableBox child) => child.offset & child.layoutSize).toList(growable: false);
  }
}

/// Base class for [RowLayouter] and [ColumnLayouter].
///
/// The role of this class is to lay out their children along the main axis and the cross axis,
/// in continuous flow; [RowLayouter] and [BoxLayouter] are the intended extensions.
///
/// The layouter supports different alignment and packing of children ([Align] and [Packing]),
/// set by the [mainAxisAlign], [mainAxisPacking], [crossAxisAlign], [crossAxisPacking].
///
/// [mainAxisLayoutProperties] and [crossAxisLayoutProperties]
/// are private wrappers of alignment and packing properties .
///
/// Note that [Align] and [Packing] are needed both on the 'main' direction,
/// as well as the 'cross' direction: this corresponds to layout out both widths and heights of the boxes.
///
/// Similar to Flex.
abstract class RollingPositioningBoxLayouter extends PositioningBoxLayouter {
  RollingPositioningBoxLayouter({
    required List<BoxContainer> children,
    required Align mainAxisAlign,
    required Packing mainAxisPacking,
    required Align crossAxisAlign,
    required Packing crossAxisPacking,
  }) : super(children: children) {
    mainLayoutAxis = LayoutAxis.vertical;
    mainAxisLayoutProperties = LengthsPositionerProperties(align: mainAxisAlign, packing: mainAxisPacking);
    crossAxisLayoutProperties = LengthsPositionerProperties(align: crossAxisAlign, packing: crossAxisPacking);
  }

  LayoutAxis mainLayoutAxis = LayoutAxis.horizontal;

  // isLayout should be implemented differently on layouter and container. But it's not really needed
  // bool get isLayout => mainLayoutAxis != LayoutAxis.defaultHorizontal;

  // todo-00-last : these should be private so noone overrides their 'packing: Packing.tight, align: Align.start'
  LengthsPositionerProperties mainAxisLayoutProperties = LengthsPositionerProperties(packing: Packing.tight, align: Align.start);
  LengthsPositionerProperties crossAxisLayoutProperties = LengthsPositionerProperties(packing: Packing.tight, align: Align.start);

  /// Override of the core layout on [RollingPositioningBoxLayouter].
  @override
  void newCoreLayout() {
    _layout_IfRoot_DefaultTreePreprocessing();

    // if (_hasGreedy) {
    // Process Non-GreedyLayouter children first, to find what size they use
    if (_hasNonGreedy) {
      // A. Non-GreedyLayouter pre-descend : Distribute intended constraints only to nonGreedyChildren, which we will layout
      //                         using the constraints. Everything for _nonGreedyChildren is same as default layout.
      _preDescend_DistributeConstraintsToImmediateChildren(_nonGreedyChildren);
      // B. Non-GreedyLayouter node-descend : must layout non-greedy to get their sizes. But this will mess up finality of constraints, layoutSizes etc.
      for (var child in _nonGreedyChildren) {
        // Non greedy should run full layout of children.
        child.newCoreLayout();
      }
      // C. Non-greedy node-post-descend. Here, non-greedy children have layoutSize
      //      which we can get and use to lay them out to find constraints left for greedy
      //    But positioning children in self, we need to run pre-position of children in self
      //      using left/tight to get sizes without spacing.
      _postDescend_NonGreedy_FindConstraintRemainingAfterNonGreedy_DivideIt_And_ApplyOnGreedy();
    } // same as current on Row and Column

    // At this point, both GreedyLayouter and non-GreedyLayouter children have constraints. In addition, non-GreedyLayouter children
    //   are fully recursively layed out, but not positioned in self yet - and so not parent offsets are
    //   set on non_Greedy. This will be done later in  _postDescend_IfLeaf_SetSize(etc).
    //
    // So to fully layout self, there are 3 things left:
    //   1. Need to recursively layout GREEDY children to get their size.
    //      Their greedy constraints were set in previous postDescend,
    //        the _postDescend_NonGreedy_FindConstraintRemainingAfterNonGreedy_DivideIt_And_ApplyOnGreedy.
    //      So we do NOT want to run a full [newCoreLayout] on greedy children - we need to avoid setting
    //      child constraints again in  _layout_DefaultRecurse() -> _preDescend_DistributeConstraintsToImmediateChildren(children);
    //      We only want the descend part of _layout_DefaultRecurse(), even the postDescend must be different
    //        as it must apply to all children, not just GREEDY.
    //   2. Position ALL children within self, using self axis layout properties (which is set back to original)
    //   3. Apply offsets from step 2 on children
    // Steps 2. and 3 already have a default method, the
    //       _postDescend_IfLeaf_SetSize_IfNotLeaf_PositionThenOffsetChildren_ThenSetSize_Finally_AssertSizeInsideConstraints
    //       which must be applies on all children. (it is).

    // Step 1.
    for (var child in _greedyChildren) {
      child.newCoreLayout();
    }
    // Step 2. and 3. is a base class method unchanged.
    _postDescend_IfLeaf_SetSize_IfNotLeaf_PositionThenOffsetChildren_ThenSetSize_Finally_AssertSizeInsideConstraints();
    // } else {
    //   // Working processing for no greedy children present. Maybe we can reuse some code with the above?
    //   _layout_DefaultRecurse();
    // }
  }

  List<GreedyLayouter> get _greedyChildren => children.whereType<GreedyLayouter>().toList();

  List<BoxContainer> get _nonGreedyChildren {
    List<BoxContainer> nonGreedy = List.from(children);
    nonGreedy.removeWhere((var child) => child is GreedyLayouter);
    return nonGreedy;
  }

  bool get _hasGreedy => _greedyChildren.isNotEmpty;

  bool get _hasNonGreedy => _nonGreedyChildren.isNotEmpty;

  /// Post descend after NonGreedy children, finds and applies constraints on GreedyLayouter children.
  ///
  /// In some detail,
  ///   - finds the constraint on self that remains after NonGreedy are given the (non greedy) space they want
  ///   - divides the remaining constraints into smaller constraints for all GreedyLayouter children in the greedy ratio
  ///   - applies the smaller constraints on GreedyLayouter children.
  ///
  /// This is required before we can layout GreedyLayouter children.
  void _postDescend_NonGreedy_FindConstraintRemainingAfterNonGreedy_DivideIt_And_ApplyOnGreedy() {
    // Note: non greedy children have layout size when we reach here

    if (_hasGreedy) {
      // Force Align=left, Packing=tight, no matter what the Row properties are. Rects
      // The reason we want to use tight left align, is that if there are greedy children, we want them to take
      //   all remaining space. So any non-tight packing, center or right align, does not make sense if GreedyLayouter are present.
      LengthsPositionerProperties storedLayout = mainAxisLayoutProperties;
      _forceMainAxisLayoutProperties(align: Align.start, packing: Packing.tight);

      // Get the NonGreedy [layoutSize](s), call this layouter layout method,
      // which returns [layedOutRectsInMe] rectangles relative to self where children should be positioned.
      // We create [nonGreedyBoundingRect] that envelope the NonGreedy children, tightly layed out
      // in the Column/Row direction. This is effectively a pre-positioning of children is self
      List<ui.Rect> positionedRectsInMe = _post_NotLeaf_PositionChildren(_nonGreedyChildren);
      ui.Rect nonGreedyBoundingRect = boundingRectOfRects(positionedRectsInMe);
      assert(nonGreedyBoundingRect.topLeft == ui.Offset.zero);

      // After pre-positioning to obtain children sizes without any spacing, put back axis properties
      //  - next time this layouter will layout children using the original properties
      _forceMainAxisLayoutProperties(packing: storedLayout.packing, align: storedLayout.align);

      // Create new constraints ~constraintsRemainingForGreedy~ which is a difference between
      //   self original constraint, and  nonGreedyChildrenSize
      BoxContainerConstraints constraintsRemainingForGreedy = constraints - nonGreedyBoundingRect.size;

      // Divides constraintsRemainingForGreedy~into the ratios greed / sum(greed), creating ~greedyChildrenConstaints~
      List<BoundingBoxesBase> greedyChildrenConstraints = constraintsRemainingForGreedy.divideUsingStrategy(
        divideIntoCount: _greedyChildren.length,
        divideStrategy: DivideConstraintsToChildren.intWeights,
        layoutAxis: mainLayoutAxis,
        intWeights: _greedyChildren.map((child) => child.greed).toList(),
      );

      // Apply on greedyChildren their new greedyChildrenConstraints
      assert(greedyChildrenConstraints.length == _greedyChildren.length);
      for (int i = 0; i < _greedyChildren.length; i++) {
        GreedyLayouter greedyChild = _greedyChildren[i];
        BoxContainerConstraints childConstraint = greedyChildrenConstraints[i] as BoxContainerConstraints;
        greedyChild.applyParentConstraints(this, childConstraint);
      }
    }
  }

  /// Converts the line segments (which correspond to children widths and heights that have been layed out)
  /// to [Rect]s, the rectangles where children of the invoking [BoxLayouter] node should be positioned.
  ///
  /// Children should be offset later in [newCoreLayout] by the obtained [Rect.topLeft] offsets;
  ///   this method does not change any offsets of self or children.
  List<ui.Rect> _convertPositionedSegmentsToRects({
    required LayoutAxis mainLayoutAxis,
    required _MainAndCrossPositionedSegments mainAndCrossPositionedSegments,
    required List<LayoutableBox> children,
  }) {
    PositionedLineSegments mainAxisPositionedSegments = mainAndCrossPositionedSegments.mainAxisPositionedSegments;
    PositionedLineSegments crossAxisPositionedSegments = mainAndCrossPositionedSegments.crossAxisPositionedSegments;

    if (mainAxisPositionedSegments.lineSegments.length != crossAxisPositionedSegments.lineSegments.length) {
      throw StateError('Segments differ in lengths: main=$mainAxisPositionedSegments, cross=$crossAxisPositionedSegments');
    }

    List<ui.Rect> positionedRects = [];

    for (int i = 0; i < mainAxisPositionedSegments.lineSegments.length; i++) {
      ui.Rect rect = _convertMainAndCrossSegmentsToRect(
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
  ui.Rect _convertMainAndCrossSegmentsToRect({
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
            // todo-00-last-last-last : fixed : ui.Size(mainSegment.max - mainSegment.min, crossSegment.max - crossSegment.min);
        ui.Size(crossSegment.max - crossSegment.min, mainSegment.max - mainSegment.min);
    }
  }

  /// Converts two [util_dart.LineSegment] to [Offset] according to the passed [LayoutAxis], [mainLayoutAxis].
  ui.Size _convertLengthsToSize(
    LayoutAxis mainLayoutAxis,
    double mainLength,
    double crossLength,
  ) {
    switch (mainLayoutAxis) {
      case LayoutAxis.horizontal:
        return ui.Size(mainLength, crossLength);
      case LayoutAxis.vertical:
        return ui.Size(crossLength, mainLength);
    }
  }

  /// Returns the passed [size]'s width or height along the passed [layoutAxis].
  double _lengthAlong(
    LayoutAxis layoutAxis,
    ui.Size size,
  ) {
    switch (layoutAxis) {
      case LayoutAxis.horizontal:
        return size.width;
      case LayoutAxis.vertical:
        return size.height;
    }
  }

  /// Creates a [LayedoutLengthsPositioner] for the passed [children].
  ///
  /// This layouter can layout children in the dimension along the passed [layoutAxis],
  /// according the passed [axisLayoutProperties]. The passed [lengthsConstraintAlongLayoutAxis]
  /// serves as a constraint along the layout axis.
  ///
  /// See [LayedoutLengthsPositioner] for details of how the returned layouter lays out the children's
  /// sides along the [layoutAxis].
  ///
  /// The passed objects must both correspond to either main axis or the cross axis.
  LayedoutLengthsPositioner _layedoutLengthsPositionerAlongAxis({
    required LayoutAxis layoutAxis,
    required LengthsPositionerProperties axisLayoutProperties,
    required double lengthsConstraintAlongLayoutAxis,
    required List<LayoutableBox> children,
  }) {
    List<double> lengthsAlongAxis = _layoutSizesOfChildrenAlong(layoutAxis, children);
    LayedoutLengthsPositioner lengthsPositionerAlongAxis = LayedoutLengthsPositioner(
      lengths: lengthsAlongAxis,
      lengthsPositionerProperties: axisLayoutProperties,
      lengthsConstraint: lengthsConstraintAlongLayoutAxis,
    );
    return lengthsPositionerAlongAxis;
  }

  /// Creates and returns a list of lengths of the [LayoutableBox]es [children]
  /// measured along the passed [layoutAxis].
  List<double> _layoutSizesOfChildrenAlong(
    LayoutAxis layoutAxis,
    List<LayoutableBox> children,
  ) =>
      // This gets the layoutableBox.layoutSize
      //     but when those lengths are calculated, we have to set the layoutSize on parent,
      //     as envelope of all children offsets and sizes!
      children.map((layoutableBox) => _lengthAlong(layoutAxis, layoutableBox.layoutSize)).toList();

  /// Support which allows to enforce non-positioning of nested extensions.
  ///
  /// To explain, in one-pass layout, if we want to keep the flexibility
  /// of children getting full constraint from their parents,
  /// only the topmost [RowLayouter] can offset their children.
  ///
  /// Nested [RowLayouter]s must not offset, as for example right alignment on a nested
  /// [RowLayouter] would make all children to take up the whole available constraint from parent,
  /// and the next  [RowLayouter] up has no choice but to move it to the right.
  void _forceMainAxisLayoutProperties({
    required Packing packing,
    required Align align,
  }) {
    mainAxisLayoutProperties = LengthsPositionerProperties(packing: packing, align: align);
  }

  void _forceCrossAxisLayoutProperties({
    required Packing packing,
    required Align align,
  }) {
    crossAxisLayoutProperties = LengthsPositionerProperties(packing: packing, align: align);
  }

  /// Implementation of the abstract method which lays out the invoker's children.
  ///
  /// It lay out children of the invoking [BoxLayouter],
  /// and return [List<ui.Rect>], a list of rectangles [List<ui.Rect>]
  /// where children will be placed relative to the invoker,
  /// in the order of the passed [children].
  ///
  /// See [BoxLayouter._post_NotLeaf_PositionChildren] for requirements and definitions.
  ///
  /// Implementation detail:
  ///   - The processing is calling the [LayedoutLengthsPositioner.layoutLengths], method.
  ///   - There are two instances of the [LayedoutLengthsPositioner] created, one
  ///     for the [mainLayoutAxis] (using the [mainAxisLayoutProperties]),
  ///     another and for axis perpendicular to [mainLayoutAxis] (using the [crossAxisLayoutProperties]).
  ///   - Both main and cross axis properties are members of this [RollingPositioningBoxLayouter].
  ///   - The offset on each notGreedyChild element is calculated using the [mainAxisLayoutProperties]
  ///     in the main axis direction, and the [crossAxisLayoutProperties] in the cross axis direction.
  @override
  List<ui.Rect> _post_NotLeaf_PositionChildren(List<LayoutableBox> children) {
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
    List<ui.Rect> positionedRectsInMe = _convertPositionedSegmentsToRects(
      mainLayoutAxis: mainLayoutAxis,
      mainAndCrossPositionedSegments: mainAndCrossPositionedSegments,
      children: children,
    );
    // print('layedOutRectsInMe = $layedOutRectsInMe');
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
  _MainAndCrossPositionedSegments _positionChildrenUsingOneDimAxisLayouter_As_PositionedLineSegments(
      List<LayoutableBox> children) {
    // From the sizes of the [children] create a LayedoutLengthsPositioner along each axis (main, cross).
    var crossLayoutAxis = axisPerpendicularTo(mainLayoutAxis);
    LayedoutLengthsPositioner mainAxisLayedoutLengthsPositioner = _layedoutLengthsPositionerAlongAxis(
      layoutAxis: mainLayoutAxis,
      axisLayoutProperties: mainAxisLayoutProperties,
      lengthsConstraintAlongLayoutAxis: constraints.maxLengthAlongAxis(mainLayoutAxis),
      children: children,
    );
    LayedoutLengthsPositioner crossAxisLayedoutLengthsPositioner = _layedoutLengthsPositionerAlongAxis(
      layoutAxis: crossLayoutAxis,
      axisLayoutProperties: crossAxisLayoutProperties,
      // todo-00-last-last-last : If we use, instead of 0.0,
      //                 the logical lengthsConstraintAlongLayoutAxis: constraints.maxLengthAlongAxis(axisPerpendicularTo(mainLayoutAxis)), AND
      //                 if legend starts with column, the legend column is on the left of the chart
      //                 if legend starts with row   , the legend row    is on the bottom of the chart
      //                 Probably need to address when the whole chart is layed out using the new layouter.
      //                 The 0.0 forces that in the cross-direction (horizontal or vertical),
      //                 we provide zero length constraint, so no length padding.
      lengthsConstraintAlongLayoutAxis:  0.0, // constraints.maxLengthAlongAxis(crossLayoutAxis), // 0.0,
      children: children,
    );

    // Layout the lengths along each axis to line segments (offset-ed lengths).
    // This is layouter specific - each layouter does 'layout lengths' according it's rules.
    // The [layoutLengths] method actually includes positioning the lengths, and also calculating the totalLayedOutLengthIncludesPadding,
    //   which is the total length of children.
    PositionedLineSegments mainAxisPositionedSegments = mainAxisLayedoutLengthsPositioner.layoutLengths();
    PositionedLineSegments crossAxisPositionedSegments = crossAxisLayedoutLengthsPositioner.layoutLengths();

    _MainAndCrossPositionedSegments mainAndCrossPositionedSegments = _MainAndCrossPositionedSegments(
      mainAxisPositionedSegments: mainAxisPositionedSegments,
      crossAxisPositionedSegments: crossAxisPositionedSegments,
    );
    return mainAndCrossPositionedSegments;
  }
}

// todo-01-document
class RowLayouter extends RollingPositioningBoxLayouter {
  RowLayouter({
    required List<BoxContainer> children,
    Align mainAxisAlign = Align.start,
    Packing mainAxisPacking = Packing.tight,
    Align crossAxisAlign = Align.center,
    Packing crossAxisPacking = Packing.matrjoska,
  }) : super(
          children: children,
          mainAxisAlign: mainAxisAlign,
          mainAxisPacking: mainAxisPacking,
          crossAxisAlign: crossAxisAlign,
          crossAxisPacking: crossAxisPacking,
        ) {
    // Fields declared in mixin portion of BoxContainer cannot be initialized in initializer,
    //   but in constructor here.
    // Important: As a result, mixin fields can still be final, bust must be late, as they are
    //   always initialized in concrete implementations.
    mainLayoutAxis = LayoutAxis.horizontal;
    mainAxisLayoutProperties = LengthsPositionerProperties(align: mainAxisAlign, packing: mainAxisPacking);
    crossAxisLayoutProperties = LengthsPositionerProperties(align: crossAxisAlign, packing: crossAxisPacking);
  }
}

// todo-01-document
class ColumnLayouter extends RollingPositioningBoxLayouter {
  ColumnLayouter({
    required List<BoxContainer> children,
    Align mainAxisAlign = Align.start,
    Packing mainAxisPacking = Packing.tight,
    Align crossAxisAlign = Align.start,
    Packing crossAxisPacking = Packing.matrjoska,
  }) : super(
          children: children,
          mainAxisAlign: mainAxisAlign,
          mainAxisPacking: mainAxisPacking,
          crossAxisAlign: crossAxisAlign,
          crossAxisPacking: crossAxisPacking,
        ) {
    mainLayoutAxis = LayoutAxis.vertical;
    mainAxisLayoutProperties = LengthsPositionerProperties(align: mainAxisAlign, packing: mainAxisPacking);
    crossAxisLayoutProperties = LengthsPositionerProperties(align: crossAxisAlign, packing: crossAxisPacking);
  }
}

/// Layouter which asks it's parent [RollingPositioningBoxLayouter] to allocate as much space
/// as possible for it's single child .
///
/// It is NonPositioning, so it cannot honour it's parent [Align] and [Packing], and it's
/// child is positioned [Align.start] and [Packing.tight].
///
/// Uses base class [newCoreLayout],
/// pre-descend sets full constraints on immediate children as normal
/// descend runs as normal, makes children make layoutSize available
/// post-descend runs as normal - does 'layout self'
/// what do we set THE GREEDY NODE layoutSize to???? todo-new ~I THINK WE SET IT TO THE SIZE OF IT'S CONSTRAINT. THATH WAY, EVEN IF IT'S CHILD DOES NOT TAKE THE FULL CONSTRAINT, THE ROW LAYOUT WILL ENSURE THE GREEDY WILL TAKE THE FULL LAYOUT_SIZE~  *!!!!!!
class GreedyLayouter extends NonPositioningBoxLayouter {
  final int greed;

  GreedyLayouter({
    this.greed = 1,
    required BoxContainer child,
  }) : super(children: [child]);

  /// Override a standard hook in [newCoreLayout] which sets the layout size.
  ///
  /// The set [layoutSize] of Greedy is not the default outer rectangle of children,
  /// instead, it is the full constraint side along the greedy axis,
  /// and children side along the cross-greedy axis
  @override
  void _post_NotLeaf_SetSize_FromPositionedChildren(List<ui.Rect> positionedChildrenRects) {
    assert(!isLeaf);
    // The GreedyLayouter layoutSize should be:
    //  - In the main axis direction (of it's parent), the constraint size of self,
    //    NOT the bounding rectangle of children.
    //    This is because children can be smaller, even if wrapped in GreedyLayouter,
    //    bu this GreedyLayouter should still expand in the main direction to it's allowed maximum.
    //  - In the cross-axis direction, take on the layout size of children outer rectangle, as
    //    ih the default implementation.
    ui.Rect positionedChildrenOuterRects =  util_flutter
        .boundingRectOfRects(positionedChildrenRects.map((ui.Rect childRect) => childRect).toList(growable: false));
    // childrenOuterRectangle is ONLY needed for asserts. Can be removed for performance.
    ui.Rect childrenOuterRectangle = util_flutter
        .boundingRectOfRects(children.map((BoxLayouter child) => child._boundingRectangle()).toList(growable: false));
    assert(childrenOuterRectangle.size == positionedChildrenOuterRects.size);

    ui.Size greedySize = constraints.maxSize; // use the portion of this size along main axis
    ui.Size childrenLayoutSize = positionedChildrenOuterRects.size; // use the portion of this size along cross axis

    if (parent is! RollingPositioningBoxLayouter) {
      throw StateError('Parent of this GreedyLayouter container "$this" must be '
          'a ${(RollingPositioningBoxLayouter).toString()} but it is $parent');
    }
    RollingPositioningBoxLayouter p = (parent as RollingPositioningBoxLayouter);
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
}

/// Layouter which lays out it's single child surrounded by [EdgePadding] within itself.
///
/// [PaddingLayouter] behaves as follows:
///   - Decreases own constraint by Padding and provides it do a child
///   - When child returns it's [layoutSize], this layouter sets it's size as that of the child, surrounded with
///     the [EdgePadding] [edgePadding].
///
/// This governs implementation:
///   - [PaddingLayouter] uses the default [newCoreLayout].
///   - [PaddingLayouter] changes the constraint before sending it to it's child, so
///     the [_preDescend_DistributeConstraintsToImmediateChildren] must be overridden.
///   - [PaddingLayouter] is positioning, so the [_post_NotLeaf_PositionChildren] is overridden,
///     while the [_post_NotLeaf_OffsetChildren] uses the default super implementation, which
///     applies the offsets returned by [_post_NotLeaf_PositionChildren] onto the child.
class PaddingLayouter extends PositioningBoxLayouter {

  @override
  void _preDescend_DistributeConstraintsToImmediateChildren(List<BoxContainer> children) {

    // todo-00-last-last : need method on constraint : constraint.deflateByBy( insets) - applied to max only. throw exception if inner constraint size non sero
    //                     get first child and applyParentConstraint the smaller constraint
  }

  @override
  List<ui.Rect> _post_NotLeaf_PositionChildren(List<LayoutableBox> children) {
       // todo-00-last-last :
    // return Rect which is as big as child layoutSize, but moved from zero by insets
    return [];
  }

  @override
  void _post_NotLeaf_SetSize_FromPositionedChildren(List<ui.Rect> positionedChildrenRects) {
    // todo-00-last-last
    // Take the passed, create outer rectangle size, and expandBy EdgePaddings
    // todo-00-last-last: We need extension on Size, PaddableSize,
  }


}
// Helper classes ------------------------------------------------------------------------------------------------------

/// todo-01-document
enum LayoutAxis { horizontal, vertical }

LayoutAxis axisPerpendicularTo(LayoutAxis layoutAxis) {
  switch (layoutAxis) {
    case LayoutAxis.horizontal:
      return LayoutAxis.vertical;
    case LayoutAxis.vertical:
      return LayoutAxis.horizontal;
  }
}

class NullLikeListSingleton extends custom_collection.CustomList<BoxContainer> {
  NullLikeListSingleton._privateNamedConstructor();

  static final _instance = NullLikeListSingleton._privateNamedConstructor();

  factory NullLikeListSingleton() {
    return _instance;
  }
}

class _MainAndCrossPositionedSegments {
  _MainAndCrossPositionedSegments({
    required this.mainAxisPositionedSegments,
    required this.crossAxisPositionedSegments,
  });

  PositionedLineSegments mainAxisPositionedSegments;
  PositionedLineSegments crossAxisPositionedSegments;
}

// Functions----- ------------------------------------------------------------------------------------------------------

/// Forces default non-positioning axis layout properties [LengthsPositionerProperties]
/// on the nested hierarchy nodes of type [RowLayouter] and [ColumnLayouter] nodes.
///
/// Motivation: The one-pass layout we use allows only the topmost [RowLayouter] or [ColumnLayouter]
///              to specify values that cause non-zero offset.
///
///              Only [Packing.tight] and [Align.start] do not cause offset and
///              are allowed on nested level [RowLayouter] or [ColumnLayouter].
///
///              But such behavior is contra intuitive for users to set, so
///              this method enforces that, even though it makes
///              a baseclass [BoxLayouter] to know about it's extensions
///              [RowLayouter] or [ColumnLayouter] (by calling this method in the baseclass [BoxLayouter]).
///              We make this a library level function to at least visually remove it from the  baseclass [BoxLayouter].
///
/// This method forces the deeper level values to the non-offseting.
void _static_ifRoot_Force_Deeper_Row_And_Column_LayoutProperties_To_NonPositioning({
  required bool foundFirstRowLayouterFromTop,
  required bool foundFirstColumnLayouterFromTop,
  required BoxLayouter boxLayouter,
}) {
  if (boxLayouter is RowLayouter && !foundFirstRowLayouterFromTop) {
    foundFirstRowLayouterFromTop = true;
  }

  if (boxLayouter is ColumnLayouter && !foundFirstColumnLayouterFromTop) {
    foundFirstColumnLayouterFromTop = true;
  }

  for (var child in boxLayouter.children) {
    // pre-child, if this node or nodes above did set 'foundFirst', rewrite the child values
    // so that only the top layouter can have non-start and non-tight/matrjoska
    if (child is RowLayouter && foundFirstRowLayouterFromTop) {
      child._forceMainAxisLayoutProperties(align: Align.start, packing: Packing.tight);
    }
    if (child is ColumnLayouter && foundFirstColumnLayouterFromTop) {
      child._forceMainAxisLayoutProperties(align: Align.start, packing: Packing.matrjoska);
    }

    // in-child continue to child's children with the potentially updated values 'foundFirst'
    _static_ifRoot_Force_Deeper_Row_And_Column_LayoutProperties_To_NonPositioning(
      foundFirstRowLayouterFromTop: foundFirstRowLayouterFromTop,
      foundFirstColumnLayouterFromTop: foundFirstColumnLayouterFromTop,
      boxLayouter: child,
    );
  }
}

// ---------------------------------------------------------------------------------------------------------------------
/* END of BoxContainer: KEEP
  // todo-02 : Replace ParentOffset with ParentTransform. ParentTransform can be ParentOffsetTransform,
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
