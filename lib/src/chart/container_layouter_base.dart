import 'dart:ui' as ui show Size, Offset, Rect, Canvas;
import 'package:flutter_charts/flutter_charts.dart';
// import 'package:flutter_charts/src/chart/container.dart';

import 'package:flutter_charts/src/chart/layouter_one_dimensional.dart'
    show
        Align,
        Packing,
        OneDimLayoutProperties,
        LayedoutLengthsPositioner,
        LayedOutLineSegments,
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

  @Deprecated(
      '[addChildToHierarchyDeprecated] is deprecated, since BoxContainerHierarchy should be fully built using its children array')
  void addChildToHierarchyDeprecated(BoxContainer thisBoxContainer, BoxContainer childOfThis) {
    childOfThis.parent = thisBoxContainer;
    children.add(childOfThis);
    // throw StateError('This is deprecated.');
  }
}

// todo-01-document as interface for [BoxLayouter] and [BoxContainer].
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

  void applyParentOffset(BoxLayouter caller, ui.Offset offset);

  void applyParentOrderedSkip(BoxLayouter caller, bool orderedSkip);

  void applyParentConstraints(BoxLayouter caller, BoxContainerConstraints constraints);

  void newCoreLayout();
}

/// Layouter of a list of [LayoutableBox]es.
///
/// The role of this class is to lay out boxes along the main axis and the cross axis,
/// given layout properties for alignment and packing.
///
/// Created from the [children], a list of [LayoutableBox]es, and the definitions
/// of [mainLayoutAxis] and [crossLayoutAxis], along with the alignment and packing properties
/// along each of those axis, [mainAxisLayoutProperties] and [crossAxisLayoutProperties]
///
/// The core functions of this class is to layout the member [children] [_post_NotLeaf_PositionChildren] and
/// their offset-applying [_post_NotLeaf_OffsetChildren].
mixin BoxLayouter on BoxContainerHierarchy implements LayoutableBox {
  // Important Note: Mixin fields can still be final, bust must be late, as they are
  //   always initialized in concrete implementations constructors or their initializer list.

  // 1. Overrides implementing all methods from implemented interface [LayoutableBox] ---------------------------------

  /// Manages the layout size, the result of [newCoreLayout].
  ///
  /// Set late in [newCoreLayout], once the layout size is known after all children were layoed out.
  /// Extensions of [BoxLayouter] should not generally override, even with their own layout.
  @override
  late final ui.Size layoutSize;

  // orderedSkip ---
  bool _orderedSkip = false; // want to be late final but would have to always init.

  /// [orderedSkip] is set by parent; instructs this container that it should not be
  /// painted or layed out - as if it collapsed to zero size.
  ///
  /// When set to true, implementations must add appropriate support for collapse.
  bool get orderedSkip => _orderedSkip;

  /// Set private member [_orderedSkip] with assert that caller is parent
  ///
  /// todo-01-last Important override notes and rules for extensions:
  @override
  void applyParentOrderedSkip(BoxLayouter caller, bool orderedSkip) {
    _assertCallerIsParent(caller);
    _orderedSkip = orderedSkip;
  }

  // constraints ---
  /// Constraints set by parent.
  late final BoxContainerConstraints _constraints;

  BoxContainerConstraints get constraints => _constraints;

  @override

  /// Set private member [_constraints] with assert that the caller is parent
  void applyParentConstraints(BoxLayouter caller, BoxContainerConstraints constraints) {
    _assertCallerIsParent(caller);
    _constraints = constraints;
  }

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
  ///         - Non-offsetting Non-leafs: Generally only need to override [_post_NotLeaf_PositionChildren] to return .
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
      assert(constraints.size !=
          const ui.Size(-1.0,
              -1.0)); // todo-01 : rethink, what this size is used for. Maybe create a singleton 'uninitialized constraint' - maybe ther is one already?
      // On nested levels [RowLayouter]s OR [ColumnLayouter]s
      // force non-offsetting layout properties.
      // This is a hack that unfortunately make this baseclass [BoxLayouter]
      // to depend on it's extensions [ColumnLayouter] and [RowLayouter]
      _static_ifRoot_Force_Deeper_Row_And_Column_LayoutProperties_To_Non_Offsetting(
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
      post_Leaf_SetSizeFromInternals();
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
    List<ui.Rect> layedOutRectsInMe = _post_NotLeaf_PositionChildren(children);

    // Apply the calculated layedOutRectsInMe as offsets on children.
    _post_NotLeaf_OffsetChildren(layedOutRectsInMe, children);
    // Finally, whe all children are at the right offsets within me,
    // set the layoutSize on me - the size of envelope rectangle of all children rectangles in me.
    _post_NotLeaf_SetSize_FromPositionedChildren();
  }

  /// [_post_NotLeaf_PositionChildren] is a core method of the default [newCoreLayout]
  /// which lays out the invoker's children.
  ///
  /// [_post_NotLeaf_PositionChildren] is abstract in [BoxLayouter] and no-op in [BoxContainer] (returning empty list,
  /// which causes no offsetting of children.
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
  ///   - Offsetting extensions should invoke [BoxLayouter.applyParentOffset]
  ///     for all children in argument [children] and apply the [Rect.topLeft]
  ///     offset from the passed [layedOutRectsInMe].
  ///   - Non-offsetting extensions (notably BoxContainer) should make this a no-op.
  ///
  /// First argument should be the result of [_post_NotLeaf_PositionChildren],
  /// which is a list of layed out rectangles [List<ui.Rect>] of [children].
  void _post_NotLeaf_OffsetChildren(List<ui.Rect> layedOutRectsInMe, List<LayoutableBox> children);

  /// Leaf [BoxLayouter] extensions should override and set [layoutSize].
  ///
  /// Throws exception if sent to non-leaf, or sent to a leaf
  /// which did not override this method.
  void post_Leaf_SetSizeFromInternals() {
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
      throw StateError('Layout size of this layouter $this is $layoutSize,'
          ' which does not fit inside it\'s constraints $constraints');
    }
  }

  /// The only responsibility is to set the [layoutSize] of this layouter.
  ///
  /// It is called during the default [newCoreLayout] when all children
  /// have been layed out AND positioned in self.
  ///
  /// At invocation time, all children have their [offset] and [layoutSize] set.
  ///
  /// Default implementation uses the children [offset]s and [layoutSize]s to create all children bounding rectangle
  /// using [util_flutter.boundingRectOfRects]; it's size portion becomes the [layoutSize] of this layouter.
  ///
  void _post_NotLeaf_SetSize_FromPositionedChildren() {
    assert(!isLeaf);
    ui.Rect childrenOuterRectangle = util_flutter
        .boundingRectOfRects(children.map((BoxLayouter child) => child._boundingRectangle()).toList(growable: false));
    // todo-00-note-only : here, childrenOuterRectangle can be way to the right, out of screen (L=300, R=374)
    //                          we need to check against constraints on root which should be available size for app.
    //                          _check_IfMySizeFit_WithinConstraints does not help, as size is OK!
    layoutSize = childrenOuterRectangle.size;
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
/// Effectively a [NonOffsetting] class (this is inherited from [BoxLayouter] which is also [NonOffsetting].
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
    _makeMeParentOfMyChildren();
  }

  void _makeMeParentOfMyChildren() {
    for (var child in children) {
      child.parent = this;
    }
  }

  /// Override of the abstract [_post_NotLeaf_PositionChildren] on instances of this base [BoxContainer].
  ///
  /// [_post_NotLeaf_PositionChildren] is abstract in [BoxLayouter] and no-op here in [BoxContainer] - by Returning empty list,
  /// results in no offsetting of children,
  ///
  /// Returning an empty list here causes no offsets on children are applied,
  /// which is desired on this non-offsetting base class [BoxContainer].
  ///
  /// Note: No offsets application is also achieved if [_post_NotLeaf_OffsetChildren]
  ///       does nothing. However, making [_post_NotLeaf_PositionChildren] to return empty list is a faster path,
  ///       as no layout is invoked, and empty list of children is passed to
  ///       it, which causes no offset (because of the empty list).
  ///
  @override
  List<ui.Rect> _post_NotLeaf_PositionChildren(List<LayoutableBox> children) {
    return [];
  }

  /// Override of the abstract [_post_NotLeaf_OffsetChildren] of the default [newCoreLayout].
  ///
  /// This class, as a non-offsetting container should make this a no-op,
  /// resulting in no offsets applies on children during layout.
  @override
  void _post_NotLeaf_OffsetChildren(List<ui.Rect> layedOutRectsInMe, List<LayoutableBox> children) {
    // No-op in this non-offsetting base class
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
  /// On Leaf nodes, it should generally paint whatever primitives (lines, circles, squares)
  /// the leaf container consists of.
  ///
  /// On Non-Leaf nodes, it should generally forward the [paint] to its' children.
  ///
  ///
  /// Important override notes and rules for [paint] on extensions:
  ///  1) In non-leafs: [paint] override not needed. Details:
  ///    -  This default implementation, orderedSkip stop painting the node
  ///          under first parent that orders children to skip
  ///  2) In leafs: [paint] override always(?) needed.
  ///    - Override should do:
  ///      - `if (orderedSkip) return;` - this is required if the leaf's parent is the first up who ordered to skip
  ///      - Perform any canvas drawing needed by calling [canvas.draw]
  ///      - If the container contains Flutter-level widgets that have the [paint] method, also call paint on them,
  ///        for example, [LabelContainer._textPainter.paint]
  ///      - No super call needed.
  ///
  void paint(ui.Canvas canvas) {
    if (orderedSkip) return;

    for (var child in children) {
      child.paint(canvas);
    }
  }
}

/// Layouter which is allowed to offset it's children with non zero offset.
abstract class OffsettingBoxLayouter extends BoxContainer {
  /// The required unnamed constructor
  OffsettingBoxLayouter({
    List<BoxContainer>? children,
  }) : super(children: children);

  /// Applies the offsets [layedOutRectsInMe] obtained by this specific [Layouter]
  /// on the [LayoutableBox]es [children].
  @override
  void _post_NotLeaf_OffsetChildren(List<ui.Rect> layedOutRectsInMe, List<LayoutableBox> children) {
    assert(layedOutRectsInMe.length == children.length);
    for (int i = 0; i < layedOutRectsInMe.length; i++) {
      children[i].applyParentOffset(this, layedOutRectsInMe[i].topLeft);
    }
  }
}

// ^ base non-offsetting classes BoxLayouter and BoxContainer
// ---------------------------------------------------------------------------------------------------------------------
// v offsetting classes, rolling offsetting, RowLayouter and ColumnLayouter, Greedy

/// Layouter which is NOT allowed to offset it's children, or only offset with zero offset.
abstract class NonOffsettingBoxLayouter extends BoxContainer {
  /// The required unnamed constructor
  NonOffsettingBoxLayouter({
    List<BoxContainer>? children,
  }) : super(children: children);

  /// Override for non-offsetting:
  /// Does not apply any offsets on the it's children (passed in [newCoreLayout] internals.
  @override
  void _post_NotLeaf_OffsetChildren(List<ui.Rect> layedOutRectsInMe, List<LayoutableBox> children) {}

  /// Override for non-offsetting:
  /// Does not need to calculate position of children in self, as it will not apply offsets anyway.
  @override
  List<ui.Rect> _post_NotLeaf_PositionChildren(List<LayoutableBox> children) {
    return [];
  }
}

/// Base class for [RowLayouter] and [ColumnLayouter].
///
/// In addition to it's superclass, this base class supports
/// extensions which lay out their children in continuous flow along either horizontal or vertical axis.
/// ([RowLayouter] and [BoxLayouter] intended.)
///
/// This support is provided by parameters that allow to define properties of the 'along one axis' layout:
/// [Align] and [Packing] for each direction.
///
/// Note that [Align] and [Packing] are needed both on the 'main' direction,
/// as well as the 'cross' direction: this corresponds to layout out both widths and heights of the boxes.
///
/// Similar to Flex.
abstract class RollingOffsettingBoxLayouter extends OffsettingBoxLayouter {
  RollingOffsettingBoxLayouter({
    required List<BoxContainer> children,
    required Align mainAxisLineup,
    required Packing mainAxisPacking,
    required Align crossAxisLineup,
    required Packing crossAxisPacking,
  }) : super(children: children) {
    mainLayoutAxis = LayoutAxis.vertical;
    mainAxisLayoutProperties = OneDimLayoutProperties(align: mainAxisLineup, packing: mainAxisPacking);
    crossAxisLayoutProperties = OneDimLayoutProperties(align: crossAxisLineup, packing: crossAxisPacking);
  }

  LayoutAxis mainLayoutAxis = LayoutAxis.horizontal;

  // isLayout should be implemented differently on layouter and container. But it's not really needed
  // bool get isLayout => mainLayoutAxis != LayoutAxis.defaultHorizontal;

  // todo-01-last : these should be private so noone overrides their 'packing: Packing.tight, align: Align.start'
  OneDimLayoutProperties mainAxisLayoutProperties = OneDimLayoutProperties(packing: Packing.tight, align: Align.start);
  OneDimLayoutProperties crossAxisLayoutProperties = OneDimLayoutProperties(packing: Packing.tight, align: Align.start);

  /// Override of the core layout on [RollingOffsettingBoxLayouter].
  @override
  void newCoreLayout() {
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
        child.newCoreLayout();
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

  List<Greedy> get _greedyChildren => children.whereType<Greedy>().toList();

  List<BoxContainer> get _nonGreedyChildren {
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
      OneDimLayoutProperties storedLayout = mainAxisLayoutProperties;
      _forceMainAxisLayoutProperties(align: Align.start, packing: Packing.tight);

      // Get the NonGreedy [layoutSize](s), call this layouter layout method,
      // which returns [layedOutRectsInMe] rectangles relative to self where children should be positioned.
      // We create [nonGreedyBoundingRect] that envelope the NonGreedy children, tightly layed out
      // in the Column/Row direction. This is effectively a pre-positioning of children is self
      List<ui.Rect> layedOutRectsInMe = _post_NotLeaf_PositionChildren(_nonGreedyChildren);
      ui.Rect nonGreedyBoundingRect = boundingRectOfRects(layedOutRectsInMe);
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
        Greedy greedyChild = _greedyChildren[i];
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
  List<ui.Rect> _convertLayedOutSegmentsToRects({
    required LayoutAxis mainLayoutAxis,
    required _MainAndCrossLayedOutSegments mainAndCrossLayedOutSegments,
    required List<LayoutableBox> children,
  }) {
    LayedOutLineSegments mainAxisLayedOutSegments = mainAndCrossLayedOutSegments.mainAxisLayedOutSegments;
    LayedOutLineSegments crossAxisLayedOutSegments = mainAndCrossLayedOutSegments.crossAxisLayedOutSegments;

    if (mainAxisLayedOutSegments.lineSegments.length != crossAxisLayedOutSegments.lineSegments.length) {
      throw StateError('Segments differ in lengths: main=$mainAxisLayedOutSegments, cross=$crossAxisLayedOutSegments');
    }

    List<ui.Rect> layedOutRects = [];

    for (int i = 0; i < mainAxisLayedOutSegments.lineSegments.length; i++) {
      ui.Rect rect = _convertMainAndCrossSegmentsToRect(
        mainLayoutAxis: mainLayoutAxis,
        mainSegment: mainAxisLayedOutSegments.lineSegments[i],
        crossSegment: crossAxisLayedOutSegments.lineSegments[i],
      );
      layedOutRects.add(rect);
    }
    return layedOutRects;
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
            ui.Size(mainSegment.max - mainSegment.min, crossSegment.max - crossSegment.min);
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
    required OneDimLayoutProperties axisLayoutProperties,
    required double lengthsConstraintAlongLayoutAxis,
    required List<LayoutableBox> children,
  }) {
    List<double> lengthsAlongAxis = _layoutSizesOfChildrenAlong(layoutAxis, children);
    LayedoutLengthsPositioner lengthsPositionerAlongAxis = LayedoutLengthsPositioner(
      lengths: lengthsAlongAxis,
      oneDimLayoutProperties: axisLayoutProperties,
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

  /// Support which allows to enforce non-offsetting of nested extensions.
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
    mainAxisLayoutProperties = OneDimLayoutProperties(packing: packing, align: align);
  }

  void _forceCrossAxisLayoutProperties({
    required Packing packing,
    required Align align,
  }) {
    crossAxisLayoutProperties = OneDimLayoutProperties(packing: packing, align: align);
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
  ///   - Both main and cross axis properties are members of this [RollingOffsettingBoxLayouter].
  ///   - The offset on each notGreedyChild element is calculated using the [mainAxisLayoutProperties]
  ///     in the main axis direction, and the [crossAxisLayoutProperties] in the cross axis direction.
  @override
  List<ui.Rect> _post_NotLeaf_PositionChildren(List<LayoutableBox> children) {
    if (isLeaf) {
      return [];
    }
    // Create a LayedoutLengthsPositioner along each axis (main, cross), convert it to LayoutSegments,
    // then package into a wrapper class.
    _MainAndCrossLayedOutSegments mainAndCrossLayedOutSegments =
        _positionChildrenUsingOneDimAxisLayouter_As_LayedOutLineSegments(children);
    // print(
    //     'mainAxisLayedOutSegments.lineSegments = ${mainAndCrossLayedOutSegments.mainAxisLayedOutSegments.lineSegments}');
    // print(
    //     'crossAxisLayedOutSegments.lineSegments = ${mainAndCrossLayedOutSegments.crossAxisLayedOutSegments.lineSegments}');

    // Convert the line segments to [Offset]s (in each axis). Children will be moved (offset) by the obtained [Offset]s.
    List<ui.Rect> layedOutRectsInMe = _convertLayedOutSegmentsToRects(
      mainLayoutAxis: mainLayoutAxis,
      mainAndCrossLayedOutSegments: mainAndCrossLayedOutSegments,
      children: children,
    );
    // print('layedOutRectsInMe = $layedOutRectsInMe');
    return layedOutRectsInMe;
  }

  /// Given the [children], which may be smaller than full children list,
  /// uses this [RollingOffsettingBoxLayouter] [mainAxisLayoutProperties] and [crossAxisLayoutProperties]
  /// to find children positions in self.
  ///
  /// This method finds and returns the children positions in a 'primitive one-dimensional format',
  /// using [LayedOutLineSegments] along main and cross axis, as [_MainAndCrossLayedOutSegments].
  ///
  /// Further methods convert the returned 'primitive one-dimensional format'
  /// [_MainAndCrossLayedOutSegments], into rectangles representing children positions in self.
  ///
  _MainAndCrossLayedOutSegments _positionChildrenUsingOneDimAxisLayouter_As_LayedOutLineSegments(
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
      // todo-00-later : If we use, instead of 0.0,
      //                 the logical lengthsConstraintAlongLayoutAxis: constraints.maxLengthAlongAxis(axisPerpendicularTo(mainLayoutAxis)), AND
      //                 if legend starts with column, the legend column is on the left of the chart
      //                 if legend starts with row   , the legend row    is on the bottom of the chart
      //                 Probably need to address when the whole chart is layed out using the new layouter.
      lengthsConstraintAlongLayoutAxis: 0.0,
      children: children,
    );

    // Layout the lengths along each axis to line segments (offset-ed lengths).
    // This is layouter specific - each layouter does 'layout lengths' according it's rules.
    // The [layoutLengths] method actually includes offsetting the lengths, and also calculating the totalLayedOutLengthIncludesPadding,
    //   which is the total length of children.
    LayedOutLineSegments mainAxisLayedOutSegments = mainAxisLayedoutLengthsPositioner.layoutLengths();
    LayedOutLineSegments crossAxisLayedOutSegments = crossAxisLayedoutLengthsPositioner.layoutLengths();

    _MainAndCrossLayedOutSegments mainAndCrossLayedOutSegments = _MainAndCrossLayedOutSegments(
      mainAxisLayedOutSegments: mainAxisLayedOutSegments,
      crossAxisLayedOutSegments: crossAxisLayedOutSegments,
    );
    return mainAndCrossLayedOutSegments;
  }
}

// todo-01-document
class RowLayouter extends RollingOffsettingBoxLayouter {
  RowLayouter({
    required List<BoxContainer> children,
    Align mainAxisLineup = Align.start,
    Packing mainAxisPacking = Packing.tight,
    Align crossAxisLineup = Align.center,
    Packing crossAxisPacking = Packing.matrjoska,
  }) : super(
          children: children,
          mainAxisLineup: mainAxisLineup,
          mainAxisPacking: mainAxisPacking,
          crossAxisLineup: crossAxisLineup,
          crossAxisPacking: crossAxisPacking,
        ) {
    // Fields declared in mixin portion of BoxContainer cannot be initialized in initializer,
    //   but in constructor here.
    // Important: As a result, mixin fields can still be final, bust must be late, as they are
    //   always initialized in concrete implementations.
    mainLayoutAxis = LayoutAxis.horizontal;
    mainAxisLayoutProperties = OneDimLayoutProperties(align: mainAxisLineup, packing: mainAxisPacking);
    crossAxisLayoutProperties = OneDimLayoutProperties(align: crossAxisLineup, packing: crossAxisPacking);
  }
}

// todo-01-document
class ColumnLayouter extends RollingOffsettingBoxLayouter {
  ColumnLayouter({
    required List<BoxContainer> children,
    Align mainAxisLineup = Align.start,
    Packing mainAxisPacking = Packing.tight,
    Align crossAxisLineup = Align.start,
    Packing crossAxisPacking = Packing.matrjoska,
  }) : super(
          children: children,
          mainAxisLineup: mainAxisLineup,
          mainAxisPacking: mainAxisPacking,
          crossAxisLineup: crossAxisLineup,
          crossAxisPacking: crossAxisPacking,
        ) {
    mainLayoutAxis = LayoutAxis.vertical;
    mainAxisLayoutProperties = OneDimLayoutProperties(align: mainAxisLineup, packing: mainAxisPacking);
    crossAxisLayoutProperties = OneDimLayoutProperties(align: crossAxisLineup, packing: crossAxisPacking);
  }
}

/// Layouter which asks it's parent [RollingOffsettingBoxLayouter] to allocate as much space
/// as possible for it's single child .
///
/// It is NonOffsetting, so it cannot honour it's parent [Align] and [Packing], and it's
/// child is positioned [Align.start] and [Packing.tight].
///
/// Uses base class [newCoreLayout],
/// pre-descend sets full constraints on immediate children as normal
/// descend runs as normal, makes children make layoutSize available
/// post-descend runs as normal - does 'layout self'
/// what do we set THE GREEDY NODE layoutSize to???? todo-new ~I THINK WE SET IT TO THE SIZE OF IT'S CONSTRAINT. THATH WAY, EVEN IF IT'S CHILD DOES NOT TAKE THE FULL CONSTRAINT, THE ROW LAYOUT WILL ENSURE THE GREEDY WILL TAKE THE FULL LAYOUT_SIZE~  *!!!!!!
class Greedy extends NonOffsettingBoxLayouter {
  final int greed;

  Greedy({
    this.greed = 1,
    List<BoxContainer>? children,
  }) : super(children: children);

  /// Override a standard hook in [newCoreLayout] which sets the layout size.
  ///
  @override
  void _post_NotLeaf_SetSize_FromPositionedChildren() {
    assert(!isLeaf);
    // The Greedy layoutSize should be:
    //  - In the main axis direction (of it's parent), the constraint size of self
    //    This is because children can be smaller, even if wrapped in Greedy, but
    //    Greedy should still expand in the main direction to it's allowed maximum
    //  - In the cross-axis direction, take on the layout size of children, as
    //    ih the defaul implementation
    ui.Rect childrenOuterRectangle = util_flutter
        .boundingRectOfRects(children.map((BoxLayouter child) => child._boundingRectangle()).toList(growable: false));
    ui.Size greedySize = constraints.maxSize; // use the portion of this size along main axis
    ui.Size childrenLayoutSize = childrenOuterRectangle.size; // use the portion of this size along cross axis

    if (parent is! RollingOffsettingBoxLayouter) {
      throw StateError('Parent of this Greedy container "$this" must be '
          'a ${(RollingOffsettingBoxLayouter).toString()} but it is $parent');
    }
    RollingOffsettingBoxLayouter p = (parent as RollingOffsettingBoxLayouter);
    ui.Size size = _greedySizeAlongGreedyAxis(p.mainLayoutAxis, greedySize, childrenLayoutSize);

    // Set the layout size as the full constraint side along greedy axis, and children side along cross-greedy axis
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

class _MainAndCrossLayedOutSegments {
  _MainAndCrossLayedOutSegments({
    required this.mainAxisLayedOutSegments,
    required this.crossAxisLayedOutSegments,
  });

  LayedOutLineSegments mainAxisLayedOutSegments;
  LayedOutLineSegments crossAxisLayedOutSegments;
}

// Functions----- ------------------------------------------------------------------------------------------------------

/// Forces default non-offsetting axis layout properties [OneDimLayoutProperties]
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
void _static_ifRoot_Force_Deeper_Row_And_Column_LayoutProperties_To_Non_Offsetting({
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
    _static_ifRoot_Force_Deeper_Row_And_Column_LayoutProperties_To_Non_Offsetting(
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
