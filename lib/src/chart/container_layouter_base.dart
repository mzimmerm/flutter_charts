import 'dart:ui' as ui show Size, Offset, Rect, Canvas, Paint;
import 'dart:math' as math show Random;
import 'package:flutter/material.dart' as material show Colors;
import 'package:flutter/services.dart';

import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/chart/container_edge_padding.dart' show EdgePadding;
import 'package:flutter_charts/src/chart/layouter_one_dimensional.dart'
    show
    Align,
    Packing,
    LengthsPositionerProperties,
    LayedoutLengthsPositioner,
    PositionedLineSegments,
    DivideConstraintsToChildren;
import 'package:flutter_charts/src/chart/container_alignment.dart' show Alignment;
import 'package:flutter_charts/src/morphic/rendering/constraints.dart' show BoundingBoxesBase, BoxContainerConstraints;
import 'package:flutter_charts/src/util/extensions_flutter.dart' show SizeExtension, RectExtension;
import 'package:flutter_charts/src/util/util_dart.dart' as util_dart show LineSegment;
import 'package:flutter_charts/src/util/util_flutter.dart' as util_flutter show boundingRectOfRects;
import 'package:flutter_charts/src/util/collection.dart' as custom_collection show CustomList;
import 'package:flutter_charts/src/container/container_key.dart'
    show
    ContainerKey,
    Keyed,
    UniqueKeyedObjectsManager;

abstract class BoxContainerHierarchy extends Object with UniqueKeyedObjectsManager {

  /// Implements the sole abstract method of [UniqueKeyedObjectsManager]
  @override
  List<Keyed> get keyedMembers => children;

  /* KEEP
  /// Remove ability to create instance on extensions, encouraging use of [BoxContainerHierarchy]
  /// as mixin only. BUT IT IS NOT CLEAR HOW TO DO THIS AS  BoxContainer extends BoxContainerHierarchy,
  /// we would need to change it to mixin, more work.
  BoxContainerHierarchy._internal();
  */

  /// The parent of this [BoxContainer], late initialized in one of 2 places:
  ///   1. If [parent] is explicitly passed to constructor of [BoxContainer] extensions, in situations when caller knows
  ///      the parent and wants to explicitly set up the parent-child.
  ///   2. In the [BoxContainer] constructor, if [children] are non-null,
  ///      parent is set on all children as `child.parent = this`.
  // todo-01-last : maybe restore late final, was : late final BoxContainer? parent; // will be initialized when addChild(this) is called on this parent
  BoxContainer? parent; // will be initialized when addChild(this) is called on this parent

  // Important:
  //  1. Removed the late final on children. Some extensions (eg. LineChartContainer)
  //          need to start with empty array, initialized in BoxContainer.
  //          Some others, e.g. BoxLayouter need to pass it (which fails if already initialized
  //          in BoxContainer)
  //  2. can we make children a getter, or hide it somehow, so establishing hierarchy parent/children is in methods?
  // todo-02-last : work on incorporating this null-like singleton ChildrenNotSetSingleton in other classes,
  //                and add asserts as appropriate
  // todo-01-last : can we make children late final? Can we make immutable? Ideally all.
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
/// todo-01-document-finish documentation about the apply methods.
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

  // todo-01 : should this be private as changes are performed by the 'apply' method?
  ui.Offset get offset;

  /// Moves this [LayoutableBox] by [offset], ensuring the invocation is by [parent] in the [BoxContainerHierarchy].
  ///
  /// Lifecycle: Should be invoked by [parent] during [layout] after
  ///            sizes and positions of all this [LayoutableBox]'s siblings are calculated.
  ///
  /// Override if this [LayoutableBox]'s [parent] offset needs to be applied also to [children] of
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
  ///     which maintain some child [BoxContainer]s in addition to [BoxContainerHierarchy.children].
  ///     Those should call [super.applyParentOffset] first, to offset the [BoxContainerHierarchy.children],
  ///     then offset the additionally maintained children by the same offset as the [BoxContainerHierarchy.children].
  ///
  void applyParentOffset(LayoutableBox caller, ui.Offset offset);

  /// todo-011-document fully, also write : Important override notes and rules for [applyParentOrderedSkip] on extensions:
  /// Expresses that parent ordered this [BoxLayouter] instance to be skipped during
  /// the [layout] and [paint] processing.
  ///
  void applyParentOrderedSkip(LayoutableBox caller, bool orderedSkip);

  /// todo-011-document
  void applyParentConstraints(LayoutableBox caller, BoxContainerConstraints constraints);

  /// todo-011-document fully
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
  ///         The standard place for leafs to set their [layoutSize] is [post_Leaf_SetSize_FromInternals]
  ///         which should be overriden.
  ///         Alternatively, it is sufficient for leafs to override [layout] and only set [layoutSize] there.
  ///      2) Non-leafs do often need to override some methods invoked from [layout],
  ///         or the whole [layout]. Some details on Non-Leafs
  ///         - Non-positioning Non-leafs: Generally only need to override [post_NotLeaf_PositionChildren] to return .
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
  ///     - NO, because ??? todo-01 : layoutSize member: Make still available as late final on BoxLayouter,
  ///           set it after return in case it is needed later. Always set just after return from layout.
  void layout();
}

// Non-positioning BoxLayouter and BoxContainer ------------------------------------------------------------------------

/// Mixin provides role of a generic layouter for a one [LayoutableBox] or a list of [LayoutableBox]es.
///
/// The core functions of this class is to position their children
/// using [post_NotLeaf_PositionChildren] in self,
/// then apply the positions as offsets onto children in [_post_NotLeaf_OffsetChildren].
///
/// Layouter classes with this mixin can be divided into two categories,
/// if they use the default [layout] :
///
///   - *positioning* layouters position their children in self (potentially and likely to non-zero position).
///     This also implies that during layout, the position is converted into offsets , applied to it's children.
///     As a result, we consider extensions being *positioning* is equivalent to being *offsetting*.
///     Implementation-wise, *positioning* (and so *offsetting*)
///     extensions must implement both [post_NotLeaf_PositionChildren] and [_post_NotLeaf_OffsetChildren].
///     Often, the offset method can use the default, but the positioning method should be overriden.
///
///   - *non-positioning* (equivalent to *non-offsetting*) should implement both positioning
///     and offsetting methods as non-op.
///     If the positioning method is implemented does not hurt (but it's useless)
///     as long as the offssetting method is no-op.
///
/// Important Note: Mixin fields can still be final, but then they must be late, as they are
///   always initialized in concrete implementations constructors or their initializer list.

mixin BoxLayouter on BoxContainerHierarchy implements LayoutableBox, Keyed {

  // BoxLayouter section 1: Implements [Keyed] ----------------------------------------------------------------------------

  /// Unique [ContainerKey] [key] implements [Keyed].
  @override
  late final ContainerKey key;

  // BoxLayouter section 2: Implements [LayoutableBox] -------------------------------------------------

  /// Manages the layout size, the result of [layout].
  ///
  /// Set late in [layout], once the layout size is known after all children were layed out.
  /// Extensions of [BoxLayouter] should not generally override, even with their own layout.
  ///
  /// todo-01 : should layoutSize, and perhaps offset, be moved as separate getter/setter onto LayoutableBox? Certainly layoutSize should be!
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

    for (var child in children) {
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
  /// todo-011-document   /// Important override notes and rules for [applyParentOrderedSkip] on extensions:
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

  bool get hasGreedyChild => children.where((child) => child.isGreedy).isNotEmpty;

  BoxLayouter get firstGreedyChild => children.firstWhere((child) => child.isGreedy);

  /// Assert if caller is identical to container-hierarchy-parent in the [BoxContainerHierarchy].
  ///
  /// Works on behalf of 'apply' methods.
  /// On the root in [BoxContainerHierarchy], 'apply' can be invoked with any 'caller' instance.
  /// On any other [BoxContainer], 'apply' much be called from the  container-hierarchy-parent.
  void assertCallerIsParent(LayoutableBox caller) {
    // todo-00-last-last-last if (parent != null) {
    if (!isRoot) {
      if (!identical(caller, parent)) {
        throw StateError('on this $this, parent $parent should be == to caller $caller');
      }
    }
  }

  /// Implementation of abstract [LayoutableBox.layout].
  @override
  void layout() {
    // print('In layout: this = $this. this.children = $children.');
    // print('In layout: parent of $this = $parent.');

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
      // todo-01 : rethink, what this size is used for. Maybe create a singleton 'uninitialized constraint' - maybe there is one already?
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
    _preDescend_DistributeConstraintsToImmediateChildren(children);

    // B. node-descend
    for (var child in children) {
      // b1. child-pre-descend (empty)
      // b2. child-descend
      child.layout();
      // b3. child-post-descend (empty)
    }
    // C. node-post-descend.
    //    Here, children have layoutSizes, which are used to lay them out in me, then offset them in me
    _postDescend_IfLeaf_SetSize_IfNotLeaf_PositionThenOffsetChildren_ThenSetSize_Finally_AssertSizeInsideConstraints();
  }

  /// This [BoxLayouter]'s default implementation distributes this layouter's unchanged
  /// and undivided constraints onto it's immediate children before descending to children [layout].
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
  void _preDescend_DistributeConstraintsToImmediateChildren(List<LayoutableBox> children) {
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
  /// by finding all children positions in self,
  /// then using the positions to set children [offset]s and [layoutSize]s.
  ///
  /// Assumes that [constraints] have been set in [_preDescend_DistributeConstraintsToImmediateChildren].
  ///
  /// Final side effect result must always be setting the [layoutSize] on this node.
  ///
  /// Important override notes and rules for [_post_NotLeaf_PositionThenOffsetChildren_ThenSetSize] on extensions:
  ///   - On Non-positioning extensions using the default [layout],
  ///     best performance with non-positioning is when extensions override
  ///     this method and perform the role of  [_post_NotLeaf_SetSize_FromPositionedChildren],
  ///     setting the [layoutSize].
  ///     Then the default invoked [post_NotLeaf_PositionChildren], [_post_NotLeaf_OffsetChildren],
  ///     and [_post_NotLeaf_SetSize_FromPositionedChildren] would be bypassed and take no cycles.
  ///   - On positioning extensions of [BoxLayouter] using the default [layout],
  ///     the desired extension positioning effect is usually achieved by
  ///     overriding only the [post_NotLeaf_PositionChildren]. But extensions which [layoutSize]
  ///     is something else than [children]'s bounding rectangle ([Greedy], [Padder])
  ///     also need to override [_post_NotLeaf_SetSize_FromPositionedChildren].
  void _post_NotLeaf_PositionThenOffsetChildren_ThenSetSize() {
    // Common processing for greedy and non-greedy:
    // First, calculate children offsets within self.
    // Note: - When the greedy child is re-layed out, it has a final size (remainder after non greedy sizes added up),
    //         we can deal with the greedy child as if non greedy child.
    //       - no-op on baseclass [BoxLayouter].
    List<ui.Rect> positionedRectsInMe = post_NotLeaf_PositionChildren(children);

    // Apply the calculated positionedRectsInMe as offsets on children.
    _post_NotLeaf_OffsetChildren(positionedRectsInMe, children);
    // Finally, when all children are at the right offsets within me, invoke
    // [_post_NotLeaf_SetSize_FromPositionedChildren] to set the [layoutSize] on me.
    //
    // My [layoutSize] CAN be calculated using one of two equivalent methods:
    //   1. Query all my children for offsets and sizes, create each child rectangle,
    //      then create bounding rectangle from them.
    //   2. Use the previously created [positionedRectsInMe], which is each child rectangle,
    //      then create bounding rectangle of [positionedRectsInMe].
    // In [_post_NotLeaf_SetSize_FromPositionedChildren] we use method 2, but assert sameness between them
    _post_NotLeaf_SetSize_FromPositionedChildren(positionedRectsInMe);
  }

  /// [post_NotLeaf_PositionChildren] is a core method of the default [layout]
  /// which positions the invoker's children in self.
  ///
  /// [post_NotLeaf_PositionChildren] is abstract in [BoxLayouter] and no-op in [BoxContainer] (returning empty list,
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
  /// In the default [layout] implementation, this message [post_NotLeaf_PositionChildren]
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
  List<ui.Rect> post_NotLeaf_PositionChildren(List<LayoutableBox> children);

  /// An abstract method of the default [layout] which role is to
  /// offset the [children] by the pre-calculated offsets [positionedRectsInMe] .
  ///
  /// Important override notes and rules for [_post_NotLeaf_OffsetChildren] on extensions:
  ///
  ///   - Positioning extensions should invoke [BoxLayouter.applyParentOffset]
  ///     for all children in argument [children] and apply the [Rect.topLeft]
  ///     offset from the passed [positionedRectsInMe].
  ///   - Non-positioning extensions (notably BoxContainer) should make this a no-op.
  ///
  /// First argument should be the result of [post_NotLeaf_PositionChildren],
  /// which is a list of layed out rectangles [List<ui.Rect>] of [children].
  void _post_NotLeaf_OffsetChildren(List<ui.Rect> positionedRectsInMe, List<LayoutableBox> children);

  /// The responsibility of [_post_NotLeaf_SetSize_FromPositionedChildren]
  /// is to set the [layoutSize] of self.
  ///
  /// In the default [layout], when this method is invoked,
  /// all children have their [layoutSize]s and [offset]s set.
  ///
  /// The [layoutSize] in this default implementation is set
  /// to the size of "bounding rectangle of all positioned children".
  /// This "bounding rectangle of all positioned children" is calculated from the passed [positionedChildrenRects],
  /// which is the result of preceding invocation of [post_NotLeaf_PositionChildren].
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
  ///     - although they override [layout], the method [_post_NotLeaf_PositionThenOffsetChildren_ThenSetSize]
  ///     which invokes this is default. These classes rely on this default
  ///     "bounding rectangle of all positioned children" implementaion.
  ///
  void _post_NotLeaf_SetSize_FromPositionedChildren(List<ui.Rect> positionedChildrenRects) {
    assert(!isLeaf);
    ui.Rect positionedChildrenOuterRects = util_flutter
        .boundingRectOfRects(positionedChildrenRects.map((ui.Rect childRect) => childRect).toList(growable: false));
    // childrenOuterRectangle is ONLY needed for asserts. Can be removed for performance.
    ui.Rect childrenOuterRectangle = util_flutter
        .boundingRectOfRects(children.map((BoxLayouter child) => child._boundingRectangle()).toList(growable: false));
    assert(childrenOuterRectangle.size == positionedChildrenOuterRects.size);

    layoutSize = positionedChildrenOuterRects.size;
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
  /// It should only be called after [layout] has been performed on this layouter.
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
/// Important migration notes:
/// When migrating from old layout to new layout,
///   - The child containers creation code: move from [layout] to [buildContainerOrSelf].
///   - if we move the container fully to autolayout:
///      - The 'old layouter' code should not be used;
///   - else if keeping the manual layout (see [LabelContainer])
///       - the 'old layouter' code should go to [layout].
///       - some layout values calculated from old layout that used to be passed as members to child containers creation:
///          - We need to, in the child class:
///            - make the members 'late' if final
///            - remove setting those members from child container constructors,
///            - replace with setters
///          - Then set those layout values calculated from old layout on member children in [layout] in the new setters
///
///   - [layout] should not be called on new layout, except on 'fake' root.
/// todo-01-document : children are either passed, or a single child is build in [buildContainerOrSelf],
///                    and set as a single child. Exception: If [buildContainerOrSelf] builds self, no children are added; this happens at the leaf.
///
abstract class BoxContainer extends BoxContainerHierarchy with BoxLayouter implements LayoutableBox, Keyed, UniqueKeyedObjectsManager {
  /// Default generative constructor.
  BoxContainer({
    // todo-01-last : can key be required and non nullable?
    ContainerKey? key,
    // todo-01-last : can children be required and non nullable?
    List<BoxContainer>? children,
    // BoxContainer? parent,
  }) {
    //if (parent != null) {
    //  this.parent = parent;
    //}
    if (key != null) {
      this.key = key;
    }  else {
      // A hacky thing may fail uniqueness among siblings on rare occasions.
      // This is temporary until we require key non-nullable.
      this.key = ContainerKey(math.Random().nextInt(1000000).toString());
    }

    if (children != null) {
      //  && this.children != ChildrenNotSetSingleton()) {
      this.children = children;
    } else {
      // Important: Enforce either children passed, or set in here by calling buildContainerOrSelf
      // todo-01-last : removed this if (children == null) {
      //  &&  this.children == ChildrenNotSetSingleton()) {
      BoxContainer builtContainer = buildContainerOrSelf();
      if (builtContainer != this) {
        this.children = [builtContainer];
      } else {
        this.children = [];
      }
      // this.children = [builtContainer];
    }
    // As [BoxContainer.children], is the list backing the [UniqueKeyedObjectsManager.keyedMembers],
    // after changing [children], the [UniqueKeyedObjectsManager.ensureUnique] must be called.
    // See documentation for [UniqueKeyedObjectsManager].
    ensureKeyedMembersHaveUniqueKeys();

    // Make self a parent of all immediate children
    _makeSelfParentOfAllChildren();
    // NAMED GENERATIVE super() called implicitly here.
  }

  void _makeSelfParentOfAllChildren() {
    for (var child in children) {
      child.parent = this;
    }
  }

  void setChildrenAndMakeSelfParent(List<BoxContainer> children) {
    this.children = children;
    _makeSelfParentOfAllChildren();
  }

  /// Override of the abstract [post_NotLeaf_PositionChildren] on instances of this base [BoxContainer].
  ///
  /// [post_NotLeaf_PositionChildren] is abstract in [BoxLayouter] and no-op here in [BoxContainer].
  /// The no-op is achieved by returning, the existing children rectangles, without re-positioning children;
  /// the follow up methods use the returned value and apply this offset, without re-offsetting children.
  ///
  /// Returning an empty list here causes no offsets on children are applied,
  /// which is desired on this non-positioning base class [BoxContainer].
  ///
  /// See the invoking [_post_NotLeaf_PositionThenOffsetChildren_ThenSetSize] for more override posibilities.
  ///
  ///
  @override
  List<ui.Rect> post_NotLeaf_PositionChildren(List<LayoutableBox> children) {
    // This is a no-op because it does not change children positions from where they are at their current offsets.
    // However, implementation is needed BoxContainer extensions which are positioning
    // - in other words, all, NOT NonPositioningBoxLayouter extensions.
    return children.map((LayoutableBox child) => child.offset & child.layoutSize).toList(growable: false);
  }

  /// Implementation of the abstract default [_post_NotLeaf_OffsetChildren]
  /// invoked in the default [layout].
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
  // todo-01-document
  // By default return self. This should NOT be used eventually.
  // Currently, returning self has a special handling in the [BoxContainer] constructor:
  //   - If self is returned, no children are added to the [BoxContainer] being constructed,
  //     and it is assumed children will be added first using `this.children = someManuallyBuiltChildren`.
  //     This is used in manual layout
  //   - Otherwise, it is assumed [buildContainerOrSelf] is building a single child,
  //     and the returned BoxContainer is added as a single child.
  // The above assumption, along with [buildContainerOrSelf] returning a single [BoxContainer] (not a list),
  // means that [BoxContainer] built here has always a single child, most likely a [BoxLayouter] such as [Row] or [Column],
  // or no children (at leaf).
  BoxContainer buildContainerOrSelf() {
    return this;
  }

  /// Painting base method of all [BoxContainer] extensions,
  /// which should paint self on the passed [canvas].
  ///
  /// This default [BoxContainer] implementation implements several roles:
  ///   - Overflow check: Checks for layout overflows, on overflow, paints a yellow-black rectangle
  ///   - Skip check: Checks for [orderedSkip], if true, returns as a no-op
  ///   - Paint forward: Forwards [paint] to [children]
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

/// Mixin marks implementations as able to create and add [children] *late*,
/// during [layout] of their parent.
///
/// Note: By default, [children] should created *early* in the [BoxContainer] constructor.
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
/// and call it's [buildChildrenInParentLayout] during the 'root container' [layout].
/// The 'x axis container' [layout] can set this mixin's [sourceSiblingsLayoutsResults], which would
/// then be used in this mixin's code in [buildChildrenInParentLayout].
///
/// This approach requires for the 'source' sibling 'x axis container' to *know* which sibling(s) 'sinks'
/// depend on the 'source' [layout], and the other way around.  Also, the 'source' and the 'sink' must
/// agree on the object used as [sourceSiblingsLayoutsResults].
///
/// In such situation, a hierarchy-parent during the [layout] would first call
/// this mixin's siblings' [layout], establishing the remaining space
/// ([constraints]) left over for this [BuilderOfChildrenDuringParentLayout] container, then
/// create an 'appropriate', 'non-overlapping' children of itself.
///
/// Example: todo-011 maybe remove or improve.
///   - An example is the Y axis ([YContainer] instance), which creates only as many labels
///     ([YAxisLabelContainer]s instances) as they fit, given how many pixels
///     the Y axis has available. Such pixel availability is applied on  [YContainer]
///
///
/// Important note:  todo-011 maybe remove or improve.
///   - It is assumed that [constraints] are set on this [BoxContainer] before calling this,
///     likely in parent's [layout] that calls first [layout] on
///     one or more siblings, calculating the [constraints] remaining for this  [BoxContainer].
///   - Implementations MUST also call [layout] immediately after calling
///     the [buildChildrenInParentLayout].

mixin BuilderOfChildrenDuringParentLayout on BoxContainer {

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
  void buildChildrenInParentLayout();

  /// Intended implementation is to find sibling 'source' [BoxContainer]s which [layout] results 'drive'
  /// the build of this 'sink' [BoxContainer] (the build is performed by [buildChildrenInParentLayout]).
  ///
  /// Intended place of invocation is in this sink's [BoxContainer]'s [buildChildrenInParentLayout], which
  /// builds and adds it's children, based on the information in the object returned from this method.
  ///
  /// All information regarding
  ///   - what sibling [BoxContainer]s are 'sources' which [layout] 'drives' the build of this [BoxContainer]
  ///   - how to find such siblings
  ///   - what is the returned object that serves as a message between the 'source' [BoxContainer]s [layout] results
  ///     and this 'sink' [buildChildrenInParentLayout]
  ///  must be available to this [BoxContainer].
  ///
  /// The finding may be done using [ContainerKey] or simply hardcoded reaching to the siblings.
  ///
  /// Returns the object that serves as a message from the 'source' [BoxContainer]s to this 'sink' [BoxContainer],
  /// during the sink's [buildChildrenInParentLayout].
  Object findSourceContainersReturnLayoutResultsToBuildSelf() {
    throw UnimplementedError(
        '$this.findSourceContainersReturnLayoutResultsToBuildSelf: '
            'Implementations invoking this method must implement it.');
  }
}

/// Abstract layouter which is allowed to offset it's children with non zero offset.
///
/// The default implementation overrides [_post_NotLeaf_OffsetChildren] to position children.
abstract class PositioningBoxLayouter extends BoxContainer {
  /// The required unnamed constructor
  PositioningBoxLayouter({
    List<BoxContainer>? children,
  }) : super(children: children);

  /// Applies the offsets given with the passed [positionedRectsInMe]
  /// on the passed [LayoutableBox]es [children].
  ///
  /// The [positionedRectsInMe] are obtained by this [Layouter]'s
  /// extensions using [post_NotLeaf_PositionChildren].
  ///
  ///
  @override
  void _post_NotLeaf_OffsetChildren(List<ui.Rect> positionedRectsInMe, List<LayoutableBox> children) {
    assert(positionedRectsInMe.length == children.length);
    for (int i = 0; i < positionedRectsInMe.length; i++) {
      children[i].applyParentOffset(this, positionedRectsInMe[i].topLeft);
    }
  }
}

// Positioning classes, rolling positioning classes, Row and Column, Greedy vvv ----------------------------------------

/// Layouter which is NOT allowed to offset it's children, or only offset with zero offset.
abstract class NonPositioningBoxLayouter extends BoxContainer {
  /// The required unnamed constructor
  NonPositioningBoxLayouter({
    List<BoxContainer>? children,
  }) : super(children: children);

  /// Override for non-positioning:
  /// Does not apply any offsets on the it's children (passed in [layout] internals.
  @override
  void _post_NotLeaf_OffsetChildren(List<ui.Rect> positionedRectsInMe, List<LayoutableBox> children) {}

  /// Override for non-positioning:
  /// Does not need to calculate position of children in self, as it will not apply offsets anyway.
  @override
  List<ui.Rect> post_NotLeaf_PositionChildren(List<LayoutableBox> children) {
    // This is a no-op because it does not change children positions from where they are at their current offsets.
    // Cannot just return [], as result is used in offsetting (which is empty, so OK there),
    // and setting layoutSize using the returned value
    // (which would fail, unless replaced with looking at children offsets)
    return children.map((LayoutableBox child) => child.offset & child.layoutSize).toList(growable: false);
  }
}

/// Base class for [Row] and [Column] layouters, which allow to process [Greedy] children.
///
/// The role of this class is to lay out their children along the main axis and the cross axis,
/// in continuous flow without wrapping. [Row] and [Column] are the intended extensions.
///
/// This base layouter supports different alignment and packing of children ([Align] and [Packing]),
/// set by the [mainAxisAlign], [mainAxisPacking], [crossAxisAlign], [crossAxisPacking].
///
/// The members [mainAxisLayoutProperties] and [crossAxisLayoutProperties]
/// are private wrappers for alignment and packing properties.
///
/// Note that [Align] and [Packing] are needed both on the 'main' direction,
/// as well as the 'cross' direction: this corresponds to layout both widths and heights of the boxes.
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

  // todo-011 : these could be private so noone overrides their 'packing: Packing.tight, align: Align.start'
  LengthsPositionerProperties mainAxisLayoutProperties = LengthsPositionerProperties(packing: Packing.tight, align: Align.start);
  LengthsPositionerProperties crossAxisLayoutProperties = LengthsPositionerProperties(packing: Packing.tight, align: Align.start);

  /// Override of the core layout on [RollingPositioningBoxLayouter].
  @override
  void layout() {
    _layout_IfRoot_DefaultTreePreprocessing();

    // if (_hasGreedy) {
    // Process Non-Greedy children first, to find what size they use
    if (_hasNonGreedy) {
      // A. Non-Greedy pre-descend : Distribute intended constraints only to nonGreedyChildren, which we will layout
      //                         using the constraints. Everything for _nonGreedyChildren is same as default layout.
      _preDescend_DistributeConstraintsToImmediateChildren(_nonGreedyChildren);
      // B. Non-Greedy node-descend : must layout non-greedy to get their sizes. But this will mess up finality of constraints, layoutSizes etc.
      for (var child in _nonGreedyChildren) {
        // Non greedy should run full layout of children.
        child.layout();
      }
      // C. Non-greedy node-post-descend. Here, non-greedy children have layoutSize
      //      which we can get and use to lay them out to find constraints left for greedy
      //    But positioning children in self, we need to run pre-position of children in self
      //      using left/tight to get sizes without spacing.
      _postDescend_NonGreedy_FindConstraintRemainingAfterNonGreedy_DivideIt_And_ApplyOnGreedy();
    } // same as current on Row and Column

    // At this point, both Greedy and non-Greedy children have constraints. In addition, non-Greedy children
    //   are fully recursively layed out, but not positioned in self yet - and so not parent offsets are
    //   set on non_Greedy. This will be done later in  _postDescend_IfLeaf_SetSize(etc).
    //
    // So to fully layout self, there are 3 steps left:
    //   1. Need to recursively layout GREEDY children to get their size.
    //      Their greedy constraints were set in previous postDescend,
    //        the _postDescend_NonGreedy_FindConstraintRemainingAfterNonGreedy_DivideIt_And_ApplyOnGreedy.
    //      So we do NOT want to run a full [layout] on greedy children - we need to avoid setting
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
      child.layout();
    }
    // Step 2. and 3. is a base class method unchanged.
    _postDescend_IfLeaf_SetSize_IfNotLeaf_PositionThenOffsetChildren_ThenSetSize_Finally_AssertSizeInsideConstraints();
    // } else {
    //   // Working processing for no greedy children present. Maybe we can reuse some code with the above?
    //   _layout_DefaultRecurse();
    // }
  }

  List<Greedy> get _greedyChildren => children.whereType<Greedy>().toList();

  List<LayoutableBox> get _nonGreedyChildren {
    List<BoxContainer> nonGreedy = List.from(children);
    nonGreedy.removeWhere((var child) => child is Greedy);
    return nonGreedy;
  }

  bool get _hasGreedy => _greedyChildren.isNotEmpty;

  bool get _hasNonGreedy => _nonGreedyChildren.isNotEmpty;

  /// Post descend after NonGreedy children, finds and applies constraints on Greedy children.
  ///
  /// In some detail,
  ///   - finds the constraint on self that remains after NonGreedy are given the (non greedy) space they want
  ///   - divides the remaining constraints into smaller constraints for all Greedy children in the greedy ratio
  ///   - applies the smaller constraints on Greedy children.
  ///
  /// This is required before we can layout Greedy children.
  void _postDescend_NonGreedy_FindConstraintRemainingAfterNonGreedy_DivideIt_And_ApplyOnGreedy() {
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
      List<ui.Rect> positionedRectsInMe = post_NotLeaf_PositionChildren(_nonGreedyChildren);
      ui.Rect nonGreedyBoundingRect = boundingRectOfRects(positionedRectsInMe);
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
        divideStrategy: DivideConstraintsToChildren.intWeights,
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

  /// Converts the line segments (which correspond to children widths and heights that have been layed out)
  /// to [Rect]s, the rectangles where children of self [BoxLayouter] node should be positioned.
  ///
  /// Children should be offset later in [layout] by the obtained [Rect.topLeft] offsets;
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
        ui.Size(crossSegment.max - crossSegment.min, mainSegment.max - mainSegment.min);
    }
  }

  /* Keep
  /// Converts two [util_dart.LineSegment] to [Offset] according to the passed [LayoutAxis], [mainLayoutAxis].
  ui.Size _convertLengthsToSize(LayoutAxis mainLayoutAxis,
      double mainLength,
      double crossLength,) {
    switch (mainLayoutAxis) {
      case LayoutAxis.horizontal:
        return ui.Size(mainLength, crossLength);
      case LayoutAxis.vertical:
        return ui.Size(crossLength, mainLength);
    }
  }
  */

  /// Returns the passed [size]'s width or height along the passed [layoutAxis].
  double _lengthAlong(LayoutAxis layoutAxis,
      ui.Size size,) {
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
  List<double> _layoutSizesOfChildrenAlong(LayoutAxis layoutAxis,
      List<LayoutableBox> children,) =>
      // This gets the layoutableBox.layoutSize
  //     but when those lengths are calculated, we have to set the layoutSize on parent,
  //     as envelope of all children offsets and sizes!
  children.map((layoutableBox) => _lengthAlong(layoutAxis, layoutableBox.layoutSize)).toList();

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
    mainAxisLayoutProperties = LengthsPositionerProperties(packing: packing, align: align);
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
  /// See [BoxLayouter.post_NotLeaf_PositionChildren] for requirements and definitions.
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
  List<ui.Rect> post_NotLeaf_PositionChildren(List<LayoutableBox> children) {
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
    LayedoutLengthsPositioner mainAxisLayedoutLengthsPositioner = _layedoutLengthsPositionerAlongAxis(
      layoutAxis: mainLayoutAxis,
      axisLayoutProperties: mainAxisLayoutProperties,
      lengthsConstraintAlongLayoutAxis: constraints.maxLengthAlongAxis(mainLayoutAxis),
      children: children,
    );
    LayedoutLengthsPositioner crossAxisLayedoutLengthsPositioner = _layedoutLengthsPositionerAlongAxis(
      layoutAxis: crossLayoutAxis,
      axisLayoutProperties: crossAxisLayoutProperties,
      // todo-011 : Investigate : If we use, instead of 0.0,
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
class Row extends RollingPositioningBoxLayouter {
  Row({
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

// todo-01 : Implement by overriding the constraint definer - distribute constraints
/// Intended use : Layout LineContainers as follows
/// ```dart
///   RowWithUnevenChildrenConstraints(
///     Center(LineContainer),
///     //...
///     Center(LineContainer),)
/// ```
class RowWithUnevenChildrenConstraints extends Row {

  RowWithUnevenChildrenConstraints({
    required List<BoxContainer> children,
    required List<double> childConstraintsRatios, // todo-01 added, no implemented
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
  );
}

// todo-01-document
class Column extends RollingPositioningBoxLayouter {
  Column({
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
/// Uses base class [layout],
/// pre-descend sets full constraints on immediate children as normal
/// descend runs as normal, makes children make layoutSize available
/// post-descend runs as normal - does 'layout self'
/// what do we set THE GREEDY NODE layoutSize to???? todo-new ~I THINK WE SET IT TO THE SIZE OF IT'S CONSTRAINT. THATH WAY, EVEN IF IT'S CHILD DOES NOT TAKE THE FULL CONSTRAINT, THE ROW LAYOUT WILL ENSURE THE GREEDY WILL TAKE THE FULL LAYOUT_SIZE~  *!!!!!!
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
  void _post_NotLeaf_SetSize_FromPositionedChildren(List<ui.Rect> positionedChildrenRects) {
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
        .boundingRectOfRects(children.map((BoxLayouter child) => child._boundingRectangle()).toList(growable: false));
    assert(childrenOuterRectangle.size == positionedChildrenOuterRects.size);

    ui.Size greedySize = constraints.maxSize; // use the portion of this size along main axis
    ui.Size childrenLayoutSize = positionedChildrenOuterRects.size; // use the portion of this size along cross axis

    if (parent is! RollingPositioningBoxLayouter) {
      throw StateError('Parent of this Greedy container "$this" must be '
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
///     the [_preDescend_DistributeConstraintsToImmediateChildren] must be overridden.
///   - [Padder] is positioning, so the [post_NotLeaf_PositionChildren] is overridden,
///     while the [_post_NotLeaf_OffsetChildren] uses the default super implementation, which
///     applies the offsets returned by [post_NotLeaf_PositionChildren] onto the child.
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
  void _preDescend_DistributeConstraintsToImmediateChildren(List<LayoutableBox> children) {
    children[0].applyParentConstraints(this, constraints.deflateWithPadding(edgePadding));
  }


  /// Returns the future child position by offsetting child's layout size down and right
  /// by Offset created from Padding.
  @override
  List<ui.Rect> post_NotLeaf_PositionChildren(List<LayoutableBox> children) {
    ui.Offset childOffset = ui.Offset(edgePadding.start, edgePadding.top);
    return [childOffset & children[0].layoutSize];
  }

  /// Sets self [layoutSize], which is child layoutSize increased by EdgePadding in all directions.
  ///
  /// This self [layoutSize] is guaranteed to fit into self constraints.
  @override
  void _post_NotLeaf_SetSize_FromPositionedChildren(List<ui.Rect> positionedChildrenRects) {
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

/// A positioning layouter that sizes self from the child,
/// then aligns the single child within self.
///
/// The self sizing from child is defined by the multiples of child width and height,
/// the members [childWidthBy] and [childHeightBy].
///
/// The align process of the single child within self is defined by the member [alignment].
///
/// See [Alignment] for important notes and calculations on how child positioning
/// is calculated given by [childWidthBy], [childHeightBy] and [alignment].
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
  void _preDescend_DistributeConstraintsToImmediateChildren(List<LayoutableBox> children) {
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
  List<ui.Rect> post_NotLeaf_PositionChildren(List<LayoutableBox> children) {
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

  //_post_NotLeaf_OffsetChildren(positionedRectsInMe, children); using default implementation.

  /// Sets self [layoutSize] to the child layoutSize multiplied along axes
  /// by [childWidthBy], [childHeightBy], as mandated by this [Aligner].
  ///
  /// This multiplication is wrapped as [_selfLayoutSizeFromChild].
  @override
  void _post_NotLeaf_SetSize_FromPositionedChildren(List<ui.Rect> positionedChildrenRects) {
    layoutSize = _selfLayoutSizeFromChild(positionedChildrenRects[0].size);
  }

  /// Positions child in self, delegated to [_offsetChildInSelf].
  ///
  /// See [_offsetChildInSelf] for details
  ///
  /// Used in overridden [post_NotLeaf_PositionChildren] to position child in this [Aligner].
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
/// This method forces the deeper level values to the non-offseting.
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

  for (var child in boxLayouter.children) {
    // pre-child, if this node or nodes above did set 'foundFirst', rewrite the child values
    // so that only the top layouter can have non-start and non-tight/matrjoska
    // todo-02 : Only push the force on children of child which are NOT Greedy - reason is, Greedy does
    //           obtain smaller constraint which should allow children further down to be rows with any align and packing.
    //           but this is not simple. ALSO: consider moving this to the buildContainerOrSelf method
    if (child is Row && foundFirstRowFromTop) {
      child._forceMainAxisLayoutProperties(align: Align.start, packing: Packing.tight);
    }
    if (child is Column && foundFirstColumnFromTop) {
      child._forceMainAxisLayoutProperties(align: Align.start, packing: Packing.matrjoska);
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
