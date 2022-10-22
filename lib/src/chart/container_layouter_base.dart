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
///   - The child containers creation code: move from layout() to buildContainerOrSelf().
///   -  if we move to autolayout:
///      - The 'old layouter' code should not be used;
///   - else, keeping the manual layout (see LabelContainer)
///       - the 'old layouter' code should go to newCoreLayout.
///       - some layout values calculated from old layout that used to be passed as members to child containers creation:
///          - We need to, in the child class:
///            - make the members 'late' if final
///            - remove setting those members from child container constructors,
///            - replace with setters
///          - Then set those layout values calculated from old layout on member children in 'newCoreLayout' in the new setters
///
///   - layout() should not be called on new layout, except on 'fake' root.
///
abstract class BoxContainer extends Object with BoxContainerHierarchy, BoxLayouter implements LayoutableBox {
  /// Default empty generative constructor.
  // todo-00-last-last-last : add options as member and constructor parameter
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
    makeMeParentOfMyChildren();
  }

  void makeMeParentOfMyChildren() {
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
  ///    -  This default implementation, parentOrderedToSkip stop painting the node
  ///          under first parent that orders children to skip
  ///  2) In leafs: [paint] override always(?) needed.
  ///    - Override should do:
  ///      - `if (parentOrderedToSkip) return;` - this is required if the leaf's parent is the first up who ordered to skip
  ///      - perform any canvas drawing needed by calling [canvas.draw]
  ///      - if the container contains Flutter-level widgets that have the [paint] method, also call paint on them,
  ///        for example, [LabelContainer._textPainter.paint]
  ///      - no super call needed.
  ///
  void paint(ui.Canvas canvas) {
    if (parentOrderedToSkip) return;

    for (var child in children) {
      child.paint(canvas);
    }
  }
}

// todo-00-last : How and where should we use this?
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
enum LayoutAxis { defaultHorizontal, horizontal, vertical }

LayoutAxis axisPerpendicularTo(LayoutAxis layoutAxis) {
  switch (layoutAxis) {
    case LayoutAxis.defaultHorizontal:
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
  List<BoxContainer> children = ChildrenNotSetSingleton();
  bool get isRoot => parent == null;

  bool get isLeaf => children.isEmpty;

  @Deprecated('[addChildToHierarchyDeprecated] is deprecated, since BoxContainerHierarchy should be fully built using its children array')
  void addChildToHierarchyDeprecated(BoxContainer thisBoxContainer, BoxContainer childOfThis) {
    childOfThis.parent = thisBoxContainer;
    children.add(childOfThis);
    // throw StateError('This is deprecated.');
  }
}

class ChildrenNotSetSingleton extends custom_collection.CustomList<BoxContainer> {

  ChildrenNotSetSingleton._privateNamedConstructor();

  static final _instance = ChildrenNotSetSingleton._privateNamedConstructor();

  factory ChildrenNotSetSingleton() {
    return _instance;
  }
}

// todo-01-document as interface for [BoxLayouter] and [BoxContainer].
abstract class LayoutableBox {
  /// Size after the box has been layed out.
  ///
  // todo-00-last : Should layoutSize be on the _BoxLayouterLayoutSandbox and only a getter on implementors ????!!!!!
  //       There must be a layoutSize setter available on the sandbox (or here),  as the newCoreLayout must be able to set this [layoutSize]
  ///   on parent after all children were layoud out.
  ui.Size layoutSize = ui.Size.zero;

  void applyParentOffset(ui.Offset offset);

  // todo-00-last : consider merging layoutableBoxLayoutSandbox and layoutableBoxParentSandbox
  _BoxLayouterLayoutSandbox layoutableBoxLayoutSandbox = _BoxLayouterLayoutSandbox();
  _BoxLayouterParentSandbox layoutableBoxParentSandbox = _BoxLayouterParentSandbox();

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

  /// Manages the layout size during the layout process in [layout].
  /// Should be only mentioned in this class, not super
  @override
  ui.Size layoutSize = ui.Size.zero;

  /// todo-01-document Document the delegation to layoutableBoxParentSandbox
  /// Allow a parent containerNew to move this ContainerNew
  /// after [layout].
  ///
  /// Override if parent move needs to propagate to internals of
  /// this [ContainerNew].
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
  void applyParentOffset(ui.Offset offset) {

    if (parentOrderedToSkip) return;

    // todo-00-last : to check if applyParentOffset is invoked from parent : add caller argument, pass caller=this and check : assert(caller == BoxContainerHierarchy.parent);
    //                same on all methods delegated to layoutableBoxParentSandbox
    layoutableBoxParentSandbox.applyParentOffset(offset);

    for (var child in children) {
      child.applyParentOffset(offset);
    }
  }

  /// Member used during the [layout] processing.
  @override
  _BoxLayouterLayoutSandbox layoutableBoxLayoutSandbox = _BoxLayouterLayoutSandbox();

  @override
  _BoxLayouterParentSandbox layoutableBoxParentSandbox = _BoxLayouterParentSandbox();

  /// General rules for [newCoreLayout] on extensions
  ///  1) Generally, neither leafs nor non-leafs need to override [newCoreLayout],
  ///     as this method is integral part of autolayout (as is [applyParentOffset]).
  ///  2) Exception would be [BoxContainer]s that want to use manual or semi-manual
  ///     layout process.
  ///       - On Leaf: override [newCoreLayout] (no super call), do manual layout calculations,
  ///         likely store the result as member (see [LabelContainer._tiltedLabelEnvelope],
  ///         and set [layoutSize] at the end. This is already described in [BoxContainer.applyParentOffset]
  ///       - Potentially - this would be a hack PARENT of the leaf also may need to override[newCoreLayout], where it :
  ///         - Perform layout logic to set some size-related value on it's child. We do not have example,
  ///           as we moved this stuff from [LabelContainer] parent [LegendItemContainer] to [LabelContainer] .
  ///           See around [_layoutLogicToSetMemberMaxSizeForTextLayout]
  ///
  // todo-00-last : Why do I need greedy children last? So I can give them a Constraint which is a remainder of non-greedy children sizes!!
  @override
  void newCoreLayout() {
    print('In newCoreLayout: this = $this. this.children = $children.');
    print('In newCoreLayout: parent of $this = $parent.');

    if (isLeaf) {
      return;
    }

    // todo-00-last : this needs to be fixed. Maybe use BoxContainerNull : assert(isRoot == (parentBoxContainer == null));
    if (isRoot) {
      rootStep3_Recurse_CheckForGreedyChildren_And_PlaceGreedyChildLast();
      assert(layoutableBoxLayoutSandbox.constraints.size != const Size(-1.0, -1.0));
    }
    // A. node-pre-descend
    step301_PreDescend_DistributeMyConstraintToImmediateChildren();
    // B. node-descend
    for (var child in children) {
      // 1. child-pre-descend (empty)
      // 2. child-descend
      child.newCoreLayout();
      // 3. child-post-descend (empty
    }
    // C. node-post-descend
    // todo-00-important layout specific
    step302_PostDescend_IfLeafSetMySize_Otherwise_OffsetImmediateChildrenInMe_ThenSetMySize();
  }

  // 2. Non-override new methods on this class, starting with layout methods -------------------------------------------

  // 2.1 Layout methods
  void rootStep3_Recurse_CheckForGreedyChildren_And_PlaceGreedyChildLast() {
    // sets up childrenGreedyInMainLayoutAxis,  childrenGreedyInCrossLayoutAxis
    // if exactly 1 child greedy in MainLayoutAxis, put it last in childrenInLayoutOrder, otherwise childrenInLayoutOrder=children
    // this.constraints = passedConstraints
    int numGreedyAlongMainLayoutAxis = 0;
    BoxLayouter? greedyChild;
    for (var child in children) {
      child.rootStep3_Recurse_CheckForGreedyChildren_And_PlaceGreedyChildLast();
      // _lengthAlongLayoutAxis(LayoutAxis layoutAxis, ui.Size size)
      if (child.isGreedy) {
        numGreedyAlongMainLayoutAxis += 1;
        greedyChild = child;
      }
      // todo-00-important : not used, and not working
      layoutableBoxLayoutSandbox.addedSizeOfAllChildren = layoutableBoxLayoutSandbox.addedSizeOfAllChildren +
          ui.Offset(child.layoutSize.width, child.layoutSize.height);

      print(
          'Added size of all children = ${layoutableBoxLayoutSandbox.addedSizeOfAllChildren} for this=$this on child=$child');
    }
    if (numGreedyAlongMainLayoutAxis >= 2) {
      throw StateError('Max one child can ask for unlimited (greedy) size along main layout axis. Violated in $this');
    }
    layoutableBoxLayoutSandbox.childrenInLayoutOrderGreedyLast = List.from(children);
    if (greedyChild != null) {
      layoutableBoxLayoutSandbox.childrenInLayoutOrderGreedyLast
        ..remove(greedyChild)
        ..add(greedyChild);
    }
  }

  // Layout specific. Only children should be changed by setting constraints,
  //   created from this BoxLayouter constraints. Default sets same constraints.
  void step301_PreDescend_DistributeMyConstraintToImmediateChildren() {
    for (var child in layoutableBoxLayoutSandbox.childrenInLayoutOrderGreedyLast) {
      // todo-00-important - how does this differ for Column, Row, etc?
      child.layoutableBoxLayoutSandbox.constraints = layoutableBoxLayoutSandbox.constraints;
    }
  }

  // Layout specific. Offsets children hierarchically (layout children), which positions them in this [BoxLayouter].
  // Then, sets this object's size as the envelope of all layed out children.
  void step302_PostDescend_IfLeafSetMySize_Otherwise_OffsetImmediateChildrenInMe_ThenSetMySize() {
    if (isLeaf) {
      step302_IfLeaf_SetMySize_FromInternals_ToFit_WithinConstraints();
    } else {
      step302_IfNotLeaf_OffsetChildren_Then_SetMyLayoutSize_Then_Check_IfMySizeFit_WithinConstraints();
    }
  }

  // Layouter specific!
  // Exception or visual indication if "my size" is NOT "within my constraints"
  void step302_IfNotLeaf_OffsetChildren_Then_SetMyLayoutSize_Then_Check_IfMySizeFit_WithinConstraints() {
    if (hasGreedyChild) {
      List<LayoutableBox> notGreedyChildren = layoutableBoxLayoutSandbox.childrenInLayoutOrderGreedyLast.toList();
      notGreedyChildren.removeLast();
      _offsetChildrenAccordingToLayouter(notGreedyChildren);
      // Calculate the size of envelop of all non-greedy children, layed out using this layouter.
      Size notGreedyChildrenSizeAccordingToLayouter = _childrenLayoutSizeAccordingToLayouter(notGreedyChildren);
      // Re-calculate Size left for the Greedy child,
      // and set the greedy child's constraint and layoutSize to the re-calculated size left.
      BoxContainerConstraints constraints = firstGreedyChild.layoutableBoxLayoutSandbox.constraints;
      Size layoutSizeLeftForGreedyChild =
          constraints.sizeLeftAfter(notGreedyChildrenSizeAccordingToLayouter, mainLayoutAxis);
      firstGreedyChild.layoutSize = layoutSizeLeftForGreedyChild;
      firstGreedyChild.layoutableBoxLayoutSandbox.constraints =
          BoxContainerConstraints.exactBox(size: layoutSizeLeftForGreedyChild);
      // Having set a finite constraint on Greedy child, re-layout the Greedy child again.
      // (firstGreedyChild as BoxContainer).layoutableBoxLayoutSandbox.constraints
      firstGreedyChild.newCoreLayout();
      // When the greedy child is re-layed out, we can deal with this node as if it had no greedy children - offset
      _offsetChildrenAccordingToLayouter(children);
    } else {
      _offsetChildrenAccordingToLayouter(children);
      _setMyLayoutSize_As_OuterBoundOf_OffsettedChildren();
      _check_IfMySizeFit_WithinConstraints();
      // todo-00-last-important : Now when but when those lengths are calculated,
      //          we have to set the layoutSize on self, as envelope of all children offsets and sizes!

    }
  }

  _setMyLayoutSize_As_OuterBoundOf_OffsettedChildren() {
    ui.Rect childrenOuterRectangle = util_flutter
        .outerRectangle(children.map((BoxContainer child) => child.boundingRectangle()).toList(growable: false));
    layoutSize = childrenOuterRectangle.size;
  }
  _check_IfMySizeFit_WithinConstraints() {

  }

  // todo-00-important : make abstract and move to Layouters??
  void step302_IfLeaf_SetMySize_FromInternals_ToFit_WithinConstraints() {}

  // 2.2
  LayoutAxis mainLayoutAxis = LayoutAxis.defaultHorizontal; // todo-00 : consider default to horizontal (Row layout)
  bool get isLayout => mainLayoutAxis != LayoutAxis.defaultHorizontal;

  OneDimLayoutProperties mainAxisLayoutProperties = OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.left);
  OneDimLayoutProperties crossAxisLayoutProperties = OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.left);

  /// Greedy is defined as asking for layoutSize infinity.
  /// todo-00-last : The greedy methods should check if called BEFORE
  ///           [step302_PostDescend_IfLeafSetMySize_Otherwise_OffsetImmediateChildrenInMe_ThenSetMySize].
  ///           Maybe there should be a way to express greediness permanently.
  bool get isGreedy {
    // if (mainLayoutAxis == LayoutAxis.defaultHorizontal) return false;

    return _lengthAlong(mainLayoutAxis, layoutSize) == double.infinity;
  }

  bool get hasGreedyChild => children.where((child) => child.isGreedy).isNotEmpty;

  LayoutableBox get firstGreedyChild => children.firstWhere((child) => child.isGreedy);

  ui.Size _childrenLayoutSizeAccordingToLayouter(List<LayoutableBox> notGreedyChildren) {
    _MainAndCrossLayedOutSegments mainAndCrossLayedOutSegments = _findLayedOutSegmentsForChildren(notGreedyChildren);

    double mainLayedOutLength = mainAndCrossLayedOutSegments.mainAxisLayedOutSegments.totalLayedOutLength;
    double crossLayedOutLength = mainAndCrossLayedOutSegments.crossAxisLayedOutSegments.totalLayedOutLength;

    return _convertLengthsToSize(mainLayoutAxis, mainLayedOutLength, crossLayedOutLength);
  }

  /// Lays out, the passed [notGreedyChildren] by finding and setting the
  /// offset (according to [mainAxisLayoutProperties] and [crossAxisLayoutProperties]).
  ///
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
    // Create a LengthsLayouter along each axis (main, cross), convert it to LayoutSegments,
    // then package into a wrapper class.
    _MainAndCrossLayedOutSegments mainAndCrossLayedOutSegments = _findLayedOutSegmentsForChildren(notGreedyChildren);
    print(
        'mainAxisLayedOutSegments.lineSegments = ${mainAndCrossLayedOutSegments.mainAxisLayedOutSegments.lineSegments}');
    print(
        'crossAxisLayedOutSegments.lineSegments = ${mainAndCrossLayedOutSegments.crossAxisLayedOutSegments.lineSegments}');

    // Convert the line segments to Offsets (in each axis), which are position where notGreedyChildren
    // will be layed out.
    List<ui.Offset> layedOutOffsets = _convertLayedOutSegmentsToOffsets(
      mainLayoutAxis,
      mainAndCrossLayedOutSegments,
      notGreedyChildren,
    );
    // todo-00-last-important start here. The mainAndCrossLayedOutSegments seems OK (has 20), but layedOutOffsets are all 0
    print('layedOutOffsets = $layedOutOffsets');

    // Apply the offsets obtained by this specific [Layouter] onto the [LayoutableBox]es [notGreedyChildren]
    _offsetChildren(layedOutOffsets, notGreedyChildren);
  }

  _MainAndCrossLayedOutSegments _findLayedOutSegmentsForChildren(List<LayoutableBox> notGreedyChildren) {
    // Create a LengthsLayouter along each axis (main, cross).
    LengthsLayouter mainAxisLengthsLayouter =
        _lengthsLayouterAlong(mainLayoutAxis, mainAxisLayoutProperties, notGreedyChildren);
    LengthsLayouter crossAxisLengthsLayouter =
        _lengthsLayouterAlong(axisPerpendicularTo(mainLayoutAxis), crossAxisLayoutProperties, notGreedyChildren);

    // Layout the lengths along each axis to line segments (offset-ed lengths).
    // This is layouter specific - each layouter does 'layout lengths' according it's rules.
    // The 'layout lengths' step actually includes offsetting the lengths, and also calculating the totalLayedOutLength,
    //   which is the total length of children.
    _MainAndCrossLayedOutSegments mainAndCrossLayedOutSegments = _MainAndCrossLayedOutSegments(
      mainAxisLayedOutSegments: mainAxisLengthsLayouter.layoutLengths(),
      crossAxisLayedOutSegments: crossAxisLengthsLayouter.layoutLengths(),
    );
    return mainAndCrossLayedOutSegments;
  }

  /// Applies the offsets obtained by this specific [Layouter] onto the [LayoutableBox]es [children].
  void _offsetChildren(List<ui.Offset> layedOutOffsets, List<LayoutableBox> notGreedyChildren) {
    assert(layedOutOffsets.length == notGreedyChildren.length);
    for (int i = 0; i < layedOutOffsets.length; i++) {
      notGreedyChildren[i].applyParentOffset(layedOutOffsets[i]);
    }
  }

  /// todo-01-document
  List<ui.Offset> _convertLayedOutSegmentsToOffsets(
    LayoutAxis mainLayoutAxis,
    _MainAndCrossLayedOutSegments mainAndCrossLayedOutSegments,
    List<LayoutableBox> notGreedyChildren,
  ) {
    var mainAxisLayedOutSegments = mainAndCrossLayedOutSegments.mainAxisLayedOutSegments;
    var crossAxisLayedOutSegments = mainAndCrossLayedOutSegments.crossAxisLayedOutSegments;

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
      case LayoutAxis.defaultHorizontal:
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
      case LayoutAxis.defaultHorizontal:
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
      case LayoutAxis.defaultHorizontal:
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
      // todo-00-last-important : This gets the layoutableBox.layoutSize
      //     but when those lengths are calculated, we have to set the layoutSize on parent, as envelope of all children offsets and sizes!
      notGreedyChildren.map((layoutableBox) => _lengthAlong(layoutAxis, layoutableBox.layoutSize)).toList();

  // 3. Fields managed by Sandboxes and methods delegated to Sandboxes -------------------------------------------------

  /// Current absolute offset, set by parent (and it's parent etc, to root).
  ///
  /// That means, it is the offset from (0,0) of the canvas. There is only one
  /// canvas, managed by the top ContainerNew, passed to all children in the
  /// [paint(Canvas, Size)].
  ///
  ///
  ///
  /// It is a sum of all offsets passed in subsequent calls
  /// to [applyParentOffset] during object lifetime.
  ui.Offset get offset => layoutableBoxParentSandbox._offset;

  /// Bounding rectangle of this [BoxLayouter].
  ///
  /// It should only be called after [newCoreLayout] has been performed on this object.
  ui.Rect boundingRectangle() {
    return offset & layoutSize;
  }


  set parentOrderedToSkip(bool skip) {
    if (skip && !allowParentToSkipOnDistressedSize) {
      throw StateError('Parent did not allow to skip');
    }
    layoutableBoxParentSandbox.parentOrderedToSkip = skip;
  }

  bool get parentOrderedToSkip => layoutableBoxParentSandbox.parentOrderedToSkip;

  /// If size constraints imposed by parent are too tight,
  /// some internal calculations of sizes may lead to negative values,
  /// making painting of this containerNew not possible.
  ///
  /// Setting the [allowParentToSkipOnDistressedSize] `true` helps to solve such situation.
  /// It causes the containerNew not be painted
  /// (skipped during layout) when space is constrained too much
  /// (not enough space to reasonably paint the containerNew contents).
  /// Note that setting this to `true` may result
  /// in surprizing behavior, instead of exceptions.
  ///
  /// Note that concrete implementations must add
  /// appropriate support for collapse to work.
  ///
  /// Unlike [parentOrderedToSkip], which directs the parent to ignore this containerNew,
  /// [allowParentToSkipOnDistressedSize] is intended to be checked in code
  /// for some invalid conditions, and if they are reached, bypass painting
  /// the containerNew.
  bool allowParentToSkipOnDistressedSize = true;

  // ##### Abstract methods to implement

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
    mainAxisLayoutProperties = OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.center);
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

/// Intended as member on [LayoutableBox] and implementations [BoxLayouter] and [BoxContainer]
/// to contain fields manipulated without restrictions.
///
/// This object instance should be a member publicly available in [LayoutableBox] and implementations [BoxLayouter] and [BoxContainer],
/// for the purpose of making the rest of members of [BoxLayouter] and [BoxContainer] private, or getters.
class _BoxLayouterLayoutSandbox {
  List<BoxLayouter> childrenInLayoutOrderGreedyLast = [];
  ui.Size addedSizeOfAllChildren =
      const ui.Size(0.0, 0.0); // todo-00-last : this does not seem used in any meaningful way
  // todo-00-last : constraints are always set by parent (constraints go down).
  //  We should divide to getter/setter, and in setter, add 'invokingObject', here check if invokingObject = parent.
  BoxContainerConstraints constraints = BoxContainerConstraints.unused();
}

// todo-01-document
/// Only parent containers of the container that owns this object should be allowed to
/// get or set any field inside this object.
class _BoxLayouterParentSandbox {
  /// Current absolute offset, set by parent (and it's parent etc, to root).
  ///
  /// That means, it is the offset from (0,0) of the canvas. There is only one
  /// canvas, managed by the top ContainerNew, passed to all children in the
  /// [paint(Canvas, Size)].
  ///
  ///
  ///
  /// It is a sum of all offsets passed in subsequent calls
  /// to [applyParentOffset] during object lifetime.
  ui.Offset _offset = ui.Offset.zero;

  /// Allow a parent containerNew to move this ContainerNew
  /// after [layout].
  ///
  /// Override if parent move needs to propagate to internals of
  /// this [ContainerNew].
  void applyParentOffset(ui.Offset offset) {
    _offset += offset;
  }

  /// [parentOrderedToSkip] instructs the parent containerNew that this containerNew should not be
  /// painted or layed out - as if it collapsed to zero size.
  ///
  /// Note that concrete implementations must add
  /// appropriate support for collapse to work.
  bool parentOrderedToSkip = false;
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

  /// Tilt may apply to the whole containerNew.
  /// todo-2 unused? move to base class? similar to offset?
  void applyParentTransformMatrix(vector_math.Matrix2 transformMatrix) {
    if (transformMatrix == vector_math.Matrix2.identity()) return;
    _transformMatrix = _transformMatrix * transformMatrix;
  }
  */
