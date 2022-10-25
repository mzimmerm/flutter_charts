import 'dart:ui' as ui show Size, Offset, Rect, Canvas;
import 'package:flutter/material.dart';
import 'package:flutter_charts/flutter_charts.dart';
// import 'package:flutter_charts/src/chart/container.dart';

import 'package:flutter_charts/src/chart/layouter_one_dimensional.dart'
    show Lineup, Packing, OneDimLayoutProperties, LengthsLayouter, LayedOutLineSegments;
import 'package:flutter_charts/src/morphic/rendering/constraints.dart' show BoxContainerConstraints;
import 'package:flutter_charts/src/util/util_dart.dart' as util_dart show LineSegment;
import 'package:flutter_charts/src/util/util_flutter.dart' as util_flutter show outerRectangle;

import '../util/collection.dart' as custom_collection show CustomList;

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

  // todo-01-last : after new layout is used everywhere : make abstract, each Container must implement. Layouter has this no-op.
  // Create children one after another, or do nothing if children were created in constructor.
  // Any child created here must be added to the list of children.
  //   - if (we do not want any children created here (may exist from constructor)) return
  //   - create childN
  //   - addChild(childN)
  //   - etc
  BoxContainer buildContainerOrSelf() {
    return this;
  }

  /// General rules for [paint] on extensions
  ///  1) In non-leafs: [paint] override not needed. Details:
  ///    -  This default implementation, orderedSkip stop painting the node
  ///          under first parent that orders children to skip
  ///  2) In leafs: [paint] override always(?) needed.
  ///    - Override should do:
  ///      - `if (orderedSkip) return;` - this is required if the leaf's parent is the first up who ordered to skip
  ///      - perform any canvas drawing needed by calling [canvas.draw]
  ///      - if the container contains Flutter-level widgets that have the [paint] method, also call paint on them,
  ///        for example, [LabelContainer._textPainter.paint]
  ///      - no super call needed.
  ///
  void paint(ui.Canvas canvas) {
    if (orderedSkip) return;

    for (var child in children) {
      child.paint(canvas);
    }
  }
}

// todo-01-last : How and where should we use this? This should be similar to the other Singleton use
class BoxContainerNullParentOfRoot extends BoxContainer {
  final String _nullMessage = 'BoxContainerNullParentOfRoot: Method intentionally not implemented.';

  @override
  bool get isRoot => throw UnimplementedError(_nullMessage);

  @override
  BoxContainer get parent => throw UnimplementedError(_nullMessage);

  @override
  List<BoxContainer> get children => throw UnimplementedError(_nullMessage);

  @override
  set children(List<BoxContainer> children) => throw UnimplementedError(_nullMessage);

  @override
  void paint(Canvas canvas) {
    throw UnimplementedError(_nullMessage);
  }

  @override
  void layout(BoxContainerConstraints boxConstraints, BoxContainer parentBoxContainer) {
    throw UnimplementedError(_nullMessage);
  }
}

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

  @Deprecated('[addChildToHierarchyDeprecated] is deprecated, since BoxContainerHierarchy should be fully built using its children array')
  void addChildToHierarchyDeprecated(BoxContainer thisBoxContainer, BoxContainer childOfThis) {
    childOfThis.parent = thisBoxContainer;
    children.add(childOfThis);
    // throw StateError('This is deprecated.');
  }
}

class NullLikeListSingleton extends custom_collection.CustomList<BoxContainer> {

  NullLikeListSingleton._privateNamedConstructor();

  static final _instance = NullLikeListSingleton._privateNamedConstructor();

  factory NullLikeListSingleton() {
    return _instance;
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
  /// Important note: It is not set by parent, but it is accessed (get) by parent.
  ///                So maybe setter could be here, getter also here but check if called in parent context
  //       There must be a layoutSize setter available on the sandbox (or here),  as
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
/// The core function of this class is to layout (offset) the member [children]
/// by the side effects of the method [_offsetChildrenAccordingToLayouter].
mixin BoxLayouter on BoxContainerHierarchy implements LayoutableBox {
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
  /// Set private member [_constraints] with assert that caller is parent
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
  /// this [BoxContainer].
  ///
  /// General rules for [applyParentOffset] on extensions
  ///  1) Generally, neither leafs nor non-leafs need to override [applyParentOffset],
  ///     as this method is integral part of autolayout (as is [newCoreLayout]).
  ///  2) Exception would be [BoxContainers] that want to use manual or semi-manual
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
  /// making painting of this [BoxContainer] not possible.
  ///
  /// Setting the [allowParentToSkipOnDistressedSize] `true` helps to solve such situation.
  /// It causes the [BoxContainer] not be painted
  /// (skipped during layout) when space is constrained too much
  /// (not enough space to reasonably paint the [BoxContainer] contents).
  /// Note that setting this to `true` may result
  /// in surprizing behavior, instead of exceptions.
  ///
  /// Note that concrete implementations must add
  /// appropriate support for collapse to work.
  ///
  /// Unlike [orderedSkip], which directs the parent to ignore this [BoxContainer],
  /// [allowParentToSkipOnDistressedSize] is intended to be checked in code
  /// for some invalid conditions, and if they are reached, bypass painting
  /// the [BoxContainer].
  bool allowParentToSkipOnDistressedSize = true; // always true atm

  // todo-01-document
  List<BoxLayouter> _childrenInLayoutOrderGreedyLast = NullLikeListSingleton();
  ui.Size _addedSizesOfAllChildren = const ui.Size(0.0, 0.0);

  LayoutAxis mainLayoutAxis = LayoutAxis.horizontal;
  // isLayout should be implemented differently on layouter and container. But it's not really needed
  // bool get isLayout => mainLayoutAxis != LayoutAxis.defaultHorizontal;

  OneDimLayoutProperties mainAxisLayoutProperties = OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.start);
  OneDimLayoutProperties crossAxisLayoutProperties = OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.start);

  /// Return true if container would like to expand as much as possible, within it's constraints.
  ///
  /// Greedy would take layoutSize infinity, but do not check that here, as layoutSize is late and not yet set
  ///   when this is called in [newCoreLayout].
  bool get isGreedy => false;

  bool get hasGreedyChild => children.where((child) => child.isGreedy).isNotEmpty;

  BoxLayouter get firstGreedyChild => children.firstWhere((child) => child.isGreedy);

  // ------------------------------------------------------------------------------------------------------------------------
  void _assertCallerIsParent(BoxLayouter caller) {
    if (parent != null) {
      if (!identical(caller, parent)) {
        throw StateError('on this $this, parent $parent should be == to caller $caller');
      }
    }
  }

  /// Old layout forwards to [newCoreLayout].
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
  /// Notes:
  ///   1: Everywhere in docs, by 'layouter specific processing', we mean there is code which auto-layouts all known layouters
  ///      [RowLayouter], [ColumnLayouter] etc, using their set values of [Packing] and [Lineup].
  ///  
  ///   2: General rules for [newCoreLayout] on extensions
  ///      1) Generally, neither leafs nor non-leafs need to override [newCoreLayout],
  ///         as this method is integral part of autolayout (as is [applyParentOffset]).
  ///      2) Exception would be [BoxContainer]s that want to use manual or semi-manual
  ///         layout process.
  ///           - On Leaf: override [newCoreLayout] (no super call), do manual layout calculations,
  ///             likely store the result as member (see [LabelContainer._tiltedLabelEnvelope],
  ///             and set [layoutSize] at the end. This is already described in [BoxContainer.applyParentOffset]
  ///           - Potentially - this would be a hack PARENT of the leaf also may need to override[newCoreLayout], where it :
  ///             - Perform layout logic to set some size-related value on it's child. We do not have example,
  ///               as we moved this stuff from [LabelContainer] parent [LegendItemContainer] to [LabelContainer] .
  ///               See around [_layoutLogicToSetMemberMaxSizeForTextLayout]
  ///  
  @override
  void newCoreLayout() {
    // print('In newCoreLayout: this = $this. this.children = $children.');
    // print('In newCoreLayout: parent of $this = $parent.');

    if (isRoot) {
      _ifRoot_Recurse_CheckForGreedyChildren_And_PlaceGreedyChildLast();
      assert(constraints.size != const Size(-1.0, -1.0));
    }

    // A. node-pre-descend. Constraint on root must be set
    _preDescend_DistributeMyConstraintToImmediateChildren_And_SetTotalLengthOnMyAxisLayoutProperties();
    // B. node-descend
    for (var child in children) {
      // 1. child-pre-descend (empty)
      // 2. child-descend
      child.newCoreLayout();
      // 3. child-post-descend (empty
    }
    // C. node-post-descend
    _postDescend_IfLeaf_SetMySize_NotLeaf_OffsetImmediateChildrenInMe_ThenSetMySize_Finally_CheckIfMySizeWithinConstraints();
  }

  // 2. Non-override new methods on this class, starting with layout methods -------------------------------------------

  // 2.1 Layout methods

  /// Iterates and looks for greedy children.
  ///
  /// On each [BoxLayouter] node, creates a list of greedy children, places it
  /// on member [_childrenInLayoutOrderGreedyLast].
  ///
  /// When called, the [layoutSize]s of the [BoxLayouter] nodes is not known, so must not be accessed.
  ///
  /// Layouter needs greedy children last so that, during layout,
  /// it can give them a Constraint which is a remainder of non-greedy children sizes!
  void _ifRoot_Recurse_CheckForGreedyChildren_And_PlaceGreedyChildLast() {
    // sets up childrenGreedyInMainLayoutAxis,  childrenGreedyInCrossLayoutAxis
    // if exactly 1 child greedy in MainLayoutAxis, put it last in childrenInLayoutOrder, otherwise childrenInLayoutOrder=children
    // this.constraints = passedConstraints
    int numGreedyAlongMainLayoutAxis = 0;
    BoxLayouter? greedyChild;
    for (var child in children) {
      child._ifRoot_Recurse_CheckForGreedyChildren_And_PlaceGreedyChildLast();
      if (child.isGreedy) {
        numGreedyAlongMainLayoutAxis += 1;
        greedyChild = child;
      }
      // todo-01-last : KEEP : not used, and not working - because layoutSize is late final, but also other code reasons
      //                not sure this will be needed at all in greedy processing
      // _addedSizesOfAllChildren = _addedSizesOfAllChildren +
      //    ui.Offset(child.layoutSize.width, child.layoutSize.height);
    }
    if (numGreedyAlongMainLayoutAxis >= 2) {
      throw StateError('Max one child can ask for unlimited (greedy) size along main layout axis. Violated in $this');
    }
    _childrenInLayoutOrderGreedyLast = List.from(children);
    if (greedyChild != null) {
      _childrenInLayoutOrderGreedyLast
        ..remove(greedyChild)
        ..add(greedyChild);
    }
  }

  /// Default implementation distributes this layouter's unchanged and undivided constraints onto it's children.
  ///
  ///  Only immediate children should be set constraints.
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
  void _preDescend_DistributeMyConstraintToImmediateChildren_And_SetTotalLengthOnMyAxisLayoutProperties() {
    mainAxisLayoutProperties.totalLength = constraints.maxLengthAlongAxis(mainLayoutAxis);
    // todo-00-last : not yet : wait for expand=false as default : crossAxisLayoutProperties.totalLength = constraints.maxLengthAlongAxis(axisPerpendicularTo(mainLayoutAxis));

    for (var child in _childrenInLayoutOrderGreedyLast) {
      child.applyParentConstraints(this, constraints);
    }
    // Now we know the

  }

  /// The wrapper of the 'layouter specific processing' in post descend, given each container constraints.
  ///
  /// At the point of this is called, all [constraints] are distributed in
  /// pre-descend [_preDescend_DistributeMyConstraintToImmediateChildren_And_SetTotalLengthOnMyAxisLayoutProperties].
  ///
  /// On leaf:
  ///   - The [layoutSize] is set from internals.
  /// On non-leaf:
  ///   - Children are offset depending on layouter and children [layoutSizes].
  ///   - The current container [layoutSizes] is calculated as [_boundingRectangle] of all chidlren.
  /// Common:
  ///   - The current container [layoutSizes] is asserted to be within [constraint]
  ///
  void _postDescend_IfLeaf_SetMySize_NotLeaf_OffsetImmediateChildrenInMe_ThenSetMySize_Finally_CheckIfMySizeWithinConstraints() {
    if (isLeaf) {
      ifLeaf_SetSizeFromInternals();
    } else {
      _offsetChildren_Then_SetSizeFromChildren();
    }
    _check_IfMySizeFit_WithinConstraints();
  }

  /// Performs the CORE of the 'layouter specific processing',
  /// by finding [offset] according to layout, and setting [layoutSize] of non-leaf nodes.
  ///
  /// Assumes that [constraints] have been set in [_preDescend_DistributeMyConstraintToImmediateChildren_And_SetTotalLengthOnMyAxisLayoutProperties].
  ///
  /// Final side effect result must always be to set [layoutSize] on this node.
  void _offsetChildren_Then_SetSizeFromChildren() {
    if (hasGreedyChild) {
      List<BoxLayouter> notGreedyChildren = _childrenInLayoutOrderGreedyLast.toList();
      notGreedyChildren.removeLast();
      _offsetChildrenAccordingToLayouter(notGreedyChildren);
      // Calculate the size of envelop of all non-greedy children, layed out using this layouter.
      Size notGreedyChildrenSizeAccordingToLayouter = _notLeaf_calcChildrenLayoutSizeAccordingToLayouter(notGreedyChildren);
      // Re-calculate Size left for the Greedy child,
      // and set the greedy child's constraint and layoutSize to the re-calculated size left.
      BoxContainerConstraints constraints = firstGreedyChild.constraints;
      Size layoutSizeLeftForGreedyChild =
          constraints.maxSizeLeftAfterTakenFromAxisDirection(notGreedyChildrenSizeAccordingToLayouter, mainLayoutAxis);
      firstGreedyChild.layoutSize = layoutSizeLeftForGreedyChild;
      firstGreedyChild.applyParentConstraints(
        this,
        BoxContainerConstraints.insideBox(size: layoutSizeLeftForGreedyChild),
      );
      // Having set a finite constraint on Greedy child, re-layout the Greedy child again.
      // (firstGreedyChild as BoxContainer).layoutableBoxParentSandbox.constraints
      firstGreedyChild.newCoreLayout();
    } else {
    }
    // Common processing for greedy and non-greedy:
    // First, calculate children offsets within self.
    // Note: When the greedy child is re-layed out, it has a final size (remainder after non greedy sizes added up),
    //       we can deal with the greedy child as if non greedy child.
    _offsetChildrenAccordingToLayouter(children);
    // Now when we placed all children at the right offsets within self,
    // set the layoutSize on self, as envelope of all children offsets and sizes.
    _setSize_As_OuterBoundOf_OffsettedChildren();
  }

  /// Leaf [BoxLayouter] extensions should override and set [layoutSize].
  void ifLeaf_SetSizeFromInternals() {
    throw UnimplementedError('Method must be overriden by leaf BoxLayouters');
  }

  /// Checks if [layoutSize] box is within the [constraints] box.
  ///
  /// Throws error otherwise.
  void _check_IfMySizeFit_WithinConstraints() {
    if (!constraints.containsFully(layoutSize)) {
      throw StateError('Layout size of this layouter $this is $layoutSize,'
          ' which does not fit inside it\'s constraints $constraints');
    }
  }

  void _setSize_As_OuterBoundOf_OffsettedChildren() {
    assert(!isLeaf);
    ui.Rect childrenOuterRectangle = util_flutter
        .outerRectangle(children.map((BoxContainer child) => child._boundingRectangle()).toList(growable: false));
    // todo-00-last-note-only : here, childrenOuterRectangle can be way to the right, out of screen (L=300, R=374)
    //                          we need to check against constraints on root which should be available size for app.
    //                          _check_IfMySizeFit_WithinConstraints does not help, as size is OK!
    layoutSize = childrenOuterRectangle.size;
  }

  // 2.2

  // todo-01-document used in hasGreedyChild
  ui.Size _notLeaf_calcChildrenLayoutSizeAccordingToLayouter(List<LayoutableBox> notGreedyChildren) {
    assert(!isLeaf);
    _MainAndCrossLayedOutSegments mainAndCrossLayedOutSegments = _layoutChildrenUsingOneDimAxisLayouter_As_LayedOutLineSegments(notGreedyChildren);

    double mainLayedOutLength = mainAndCrossLayedOutSegments.mainAxisLayedOutSegments.totalLayedOutLength;
    double crossLayedOutLength = mainAndCrossLayedOutSegments.crossAxisLayedOutSegments.totalLayedOutLength;

    return _convertLengthsToSize(mainLayoutAxis, mainLayedOutLength, crossLayedOutLength);
  }

  /// Lays out, the passed [notGreedyChildren] by finding and setting the
  /// offset (according to [mainAxisLayoutProperties] and [crossAxisLayoutProperties]).
  ///
  /// todo-01-document : used in greedy branch (twice) and non-greedy branch (once)
  ///
  /// The passed [notGreedyChildren] is a list of [LayoutableBox]es.
  ///
  /// The offset on each notGreedyChild element is calculated using the [mainAxisLayoutProperties]
  /// in the main axis direction, and the [crossAxisLayoutProperties] in the cross axis direction.
  /// Both main and cross axis properties are defined by the [BoxLayouter] implementation
  ///
  /// Implementation detail: The processing is calling the [LengthsLayouter.layoutLengths], method.
  /// There are two instances of the [LengthsLayouter] created, one
  /// for the [mainLayoutAxis] (using the [mainAxisLayoutProperties]),
  /// another and for axis perpendicular to [mainLayoutAxis] (using the [crossAxisLayoutProperties]).
  void _offsetChildrenAccordingToLayouter(List<LayoutableBox> notGreedyChildren) {
    assert(!isLeaf);
    // Create a LengthsLayouter along each axis (main, cross), convert it to LayoutSegments,
    // then package into a wrapper class.
    _MainAndCrossLayedOutSegments mainAndCrossLayedOutSegments =
        _layoutChildrenUsingOneDimAxisLayouter_As_LayedOutLineSegments(notGreedyChildren);
    // print(
    //     'mainAxisLayedOutSegments.lineSegments = ${mainAndCrossLayedOutSegments.mainAxisLayedOutSegments.lineSegments}');
    // print(
    //     'crossAxisLayedOutSegments.lineSegments = ${mainAndCrossLayedOutSegments.crossAxisLayedOutSegments.lineSegments}');

    // Convert the line segments to Offsets (in each axis), which are position where notGreedyChildren
    // will be layed out.
    List<ui.Offset> layedOutOffsets = _convertLayedOutSegmentsToOffsets(
      mainLayoutAxis,
      mainAndCrossLayedOutSegments,
      notGreedyChildren,
    );
    // print('layedOutOffsets = $layedOutOffsets');

    // Apply the offsets obtained by this specific [Layouter] onto the [LayoutableBox]es [notGreedyChildren]
    _offsetChildren(layedOutOffsets, notGreedyChildren);
  }

  /// Applies the offsets obtained by this specific [Layouter] onto the [LayoutableBox]es [children].
  void _offsetChildren(List<ui.Offset> layedOutOffsets, List<LayoutableBox> notGreedyChildren) {
    assert(layedOutOffsets.length == notGreedyChildren.length);
    for (int i = 0; i < layedOutOffsets.length; i++) {
      notGreedyChildren[i].applyParentOffset(this, layedOutOffsets[i]);
    }
  }

  _MainAndCrossLayedOutSegments _layoutChildrenUsingOneDimAxisLayouter_As_LayedOutLineSegments(List<LayoutableBox> notGreedyChildren) {
    // Create a LengthsLayouter along each axis (main, cross).
    LengthsLayouter mainAxisLengthsLayouter =
        _lengthsLayouterAlong(mainLayoutAxis, mainAxisLayoutProperties, notGreedyChildren);
    LengthsLayouter crossAxisLengthsLayouter =
        _lengthsLayouterAlong(axisPerpendicularTo(mainLayoutAxis), crossAxisLayoutProperties, notGreedyChildren);

    // Layout the lengths along each axis to line segments (offset-ed lengths).
    // This is layouter specific - each layouter does 'layout lengths' according it's rules.
    // The [layoutLengths] method actually includes offsetting the lengths, and also calculating the totalLayedOutLength,
    //   which is the total length of children.
    LayedOutLineSegments mainAxisLayedOutSegments = mainAxisLengthsLayouter.layoutLengths();
    LayedOutLineSegments crossAxisLayedOutSegments = crossAxisLengthsLayouter.layoutLengths();

    _MainAndCrossLayedOutSegments mainAndCrossLayedOutSegments = _MainAndCrossLayedOutSegments(
      mainAxisLayedOutSegments: mainAxisLayedOutSegments,
      crossAxisLayedOutSegments: crossAxisLayedOutSegments,
    );
    return mainAndCrossLayedOutSegments;
  }

  List<ui.Offset> _convertLayedOutSegmentsToOffsets(
    LayoutAxis mainLayoutAxis,
    _MainAndCrossLayedOutSegments mainAndCrossLayedOutSegments,
    List<LayoutableBox> notGreedyChildren,
  ) {
    LayedOutLineSegments mainAxisLayedOutSegments = mainAndCrossLayedOutSegments.mainAxisLayedOutSegments;
    LayedOutLineSegments crossAxisLayedOutSegments = mainAndCrossLayedOutSegments.crossAxisLayedOutSegments;

    // todo-00-last-last-last testing this vvvvvv
    // This can be used if expandToConstraintMax = false (default)
    // mainAxisLayedOutSegments, move them to start with 0
    List<LineSegment> movedLineSegments = [];
    LineSegment firstLineSegment = mainAxisLayedOutSegments.lineSegments.first;
    for (LineSegment lineSegment in mainAxisLayedOutSegments.lineSegments) {
      movedLineSegments.add(LineSegment(
        lineSegment.min - firstLineSegment.min,
        lineSegment.max - firstLineSegment.min,
      ));
    }
    mainAxisLayedOutSegments.lineSegments = movedLineSegments;
    mainAxisLayedOutSegments.totalLayedOutLength -= firstLineSegment.min;
    // todo-00-last-last-last testing this ^^^^^^

    if (mainAxisLayedOutSegments.lineSegments.length != crossAxisLayedOutSegments.lineSegments.length) {
      throw StateError('Segments differ in lengths: main=$mainAxisLayedOutSegments, cross=$crossAxisLayedOutSegments');
    }

    List<ui.Offset> layedOutOffsets = [];

    for (int i = 0; i < mainAxisLayedOutSegments.lineSegments.length; i++) {
      ui.Offset offset = _convertSegmentsToOffset(
          mainLayoutAxis, mainAxisLayedOutSegments.lineSegments[i], crossAxisLayedOutSegments.lineSegments[i]);
      layedOutOffsets.add(offset);
    }
    return layedOutOffsets;
  }

  /// Converts two [util_dart.LineSegment] to [Offset] according to [mainLayoutAxis].
  ui.Offset _convertSegmentsToOffset(
      LayoutAxis mainLayoutAxis, util_dart.LineSegment mainSegment, util_dart.LineSegment crossSegment) {
    // Only the segments' beginnings are used for offset on BoxLayouter.
    // The segments' ends are already taken into account in BoxLayouter.size.
    switch (mainLayoutAxis) {
      case LayoutAxis.horizontal:
        return ui.Offset(mainSegment.min, crossSegment.min);
      case LayoutAxis.vertical:
        return ui.Offset(crossSegment.min, mainSegment.min);
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

  /// Creates a [LengthsLayouter] along the passed [layoutAxis], with the passed [axisLayoutProperties].
  ///
  /// The passed objects must both correspond to either main axis or the cross axis.
  LengthsLayouter _lengthsLayouterAlong(
    LayoutAxis layoutAxis,
    OneDimLayoutProperties axisLayoutProperties,
    List<LayoutableBox> notGreedyChildren,
  ) {
    List<double> lengthsAlongLayoutAxis = _lengthsOfChildrenAlong(layoutAxis, notGreedyChildren);
    LengthsLayouter lengthsLayouterAlongLayoutAxis = LengthsLayouter(
      lengths: lengthsAlongLayoutAxis,
      oneDimLayoutProperties: axisLayoutProperties,
    );
    return lengthsLayouterAlongLayoutAxis;
  }

  /// Creates and returns a list of lengths of the [LayoutableBox]es [notGreedyChildren]
  /// measured along the passed [layoutAxis].
  List<double> _lengthsOfChildrenAlong(
    LayoutAxis layoutAxis,
    List<LayoutableBox> notGreedyChildren,
  ) =>
      // This gets the layoutableBox.layoutSize
      //     but when those lengths are calculated, we have to set the layoutSize on parent,
      //     as envelope of all children offsets and sizes!
      notGreedyChildren.map((layoutableBox) => _lengthAlong(layoutAxis, layoutableBox.layoutSize)).toList();

  /// Bounding rectangle of this [BoxLayouter].
  ///
  /// It should only be called after [newCoreLayout] has been performed on this layouter.
  ui.Rect _boundingRectangle() {
    return offset & layoutSize;
  }

}

class RowLayouter extends BoxContainer {
  RowLayouter({
    required List<BoxContainer> children,
  }) : super (children: children) {
    // Fields declared in mixin portion of BoxContainer cannot be initialized in initializer,
    //   but in constructor here.
    // Important: As a result, mixin fields can still be final, bust must be late, as they are
    //   always initialized in concrete implementations.
    mainLayoutAxis = LayoutAxis.horizontal;
    mainAxisLayoutProperties = OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.end);
    crossAxisLayoutProperties = OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.center);
  }
}

// todo-01-document
class ColumnLayouter extends BoxContainer {
  ColumnLayouter({
    required List<BoxContainer> children,
  }) {
    throw UnimplementedError('needs to be implemented');
  }
}

// Helper classes ------------------------------------------------------------------------------------------------------

class _MainAndCrossLayedOutSegments {
  _MainAndCrossLayedOutSegments({
    required this.mainAxisLayedOutSegments,
    required this.crossAxisLayedOutSegments,
  });

  LayedOutLineSegments mainAxisLayedOutSegments;
  LayedOutLineSegments crossAxisLayedOutSegments;
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
