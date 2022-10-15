import 'dart:ui' as ui show Size, Offset, Canvas;
import 'package:flutter/material.dart';

import 'package:flutter_charts/src/chart/layouter_one_dimensional.dart' 
    show Lineup, Packing, OneDimLayoutProperties, LengthsLayouter, LayedOutLineSegments;
import 'package:flutter_charts/src/morphic/rendering/constraints.dart' show BoxContainerConstraints;
import 'package:flutter_charts/src/util/util_dart.dart' as util_dart show LineSegment;

/// [BoxContainerHierarchy] is repeated here and in [BoxLayouter] 
/// to make clear that both [BoxContainer] and [BoxLayouter]
/// have the same  [BoxContainerHierarchy] trait (capability, role).
abstract class BoxContainer extends Object with BoxContainerHierarchy, BoxLayouter implements LayoutableBox {
  
  /// Default generative constructor. Noop. todo-00-last : Should this do something
  BoxContainer() {
    // todo-00-last-last-last : children = []; removed this, removed late final and initialized in BoxContainerHierarchy.
    // todo-done-00 : initialized at declaration point : layoutableBoxParentSandbox = _BoxLayouterParentSandbox();
    // todo-done-00 : initialized at declaration point : layoutableBoxLayoutSandbox = _BoxLayouterLayoutSandbox();
  }

  // todo-00-last make abstract, each Container must implement. Layouter has this no-op.
  // Create children one after another, or do nothing if children were created in constructor.
  // Any child created here must be added to the list of children.
  //   - if (we do not want any children created here (may exist from constructor)) return
  //   - create childN
  //   - addChild(childN)
  //   - etc
  BoxContainer buildContainerOrSelf(BoxContainer parentBoxContainer) {
    return this;
  }

  void paint(ui.Canvas canvas) {
    // todo-done-00 : This was abstract, I implemented it like this
    for(var child in children) {
      child.paint(canvas);
    }
  }

}

// todo-00-last-last How and where should we use this?
class BoxContainerNullParentOfRoot extends BoxContainer {
  
  final String _nullMessage = 'BoxContainerNullParentOfRoot: Method intentionally not implemented.';
  
  @override
  bool get isRoot => throw UnimplementedError(_nullMessage);

  @override
  BoxContainer get parent => throw UnimplementedError(_nullMessage);

  @override
  // todo-00-last-last-last-last : who is the parent? We have another 'children' on BoxContainerHierarchy without the 'get'
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
enum LayoutAxis {
  defaultHorizontal,
  horizontal,
  vertical
}

LayoutAxis axisPerpendicularTo(LayoutAxis layoutAxis) {
  switch(layoutAxis) {
    case LayoutAxis.defaultHorizontal:
    case LayoutAxis.horizontal:
      return LayoutAxis.vertical;
    case LayoutAxis.vertical:
      return LayoutAxis.horizontal;
  }
}


mixin BoxContainerHierarchy {
  late final BoxContainer? parent;  // will be initialized when addChild(this) is called on this parent
  // todo-done-00 : todo-00-last-important : late final List<BoxContainer> children; // will be initialized in concrete impls such as ColumnLayouter
  //          Removed the late final. Some extensions (eg. LineChartContainer)
  //          need to start with empty array, initialized in BoxContainer.
  //          Some others, e.g. BoxLayouter need to pass it (which fails if already initialized
  //          in BoxContainer)
  // todo-00-important : can we make children a getter, or hide it somehow, so establishing hierarchy parent/children is in methods?
  List<BoxContainer> children = []; // will be initialized in concrete impls such as ColumnLayouter
  bool get isRoot => parent == null;
  bool get isLeaf => children.isEmpty;

  void addChild(BoxContainer boxContainer) {
    boxContainer.parent = boxContainer;
    children.add(boxContainer);
  }
}

// todo-01-document as interface for [BoxLayouter] and [BoxContainer].
abstract class LayoutableBox {

  // todo-00-last-last-last : Can layoutSize be only a getter?
  // todo-00-last-last-last : Should layoutSize be on the _BoxLayouterLayoutSandbox and only a getter on implementors ????!!!!!
  ui.Size layoutSize = ui.Size.zero;
  void applyParentOffset(ui.Offset offset);
  _BoxLayouterLayoutSandbox layoutableBoxLayoutSandbox = _BoxLayouterLayoutSandbox();
  // todo-00-last : consider merging layoutableBoxLayoutSandbox and layoutableBoxParentSandbox
  _BoxLayouterParentSandbox layoutableBoxParentSandbox = _BoxLayouterParentSandbox(); // todo-00-last make NON NULL
  void newCoreLayout(BoxContainer parentBoxContainer);
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
/// by the side effects of the method [offsetChildrenAccordingToLayouter]. 
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
  @override
  void applyParentOffset(ui.Offset offset) {
    // todo-00-last-last : to check if applyParentOffset is invoked from parent : add caller argument, pass caller=this and check : assert(caller == BoxContainerHierarchy.parent);
    //                same on all methods delegated to layoutableBoxParentSandbox
    layoutableBoxParentSandbox.applyParentOffset(offset);
  }
  /// Member used during the [layout] processing.
  @override
  _BoxLayouterLayoutSandbox layoutableBoxLayoutSandbox = _BoxLayouterLayoutSandbox();

  @override
  _BoxLayouterParentSandbox layoutableBoxParentSandbox = _BoxLayouterParentSandbox();

  // todo-00-last : Why do I need greedy children last? So I can give them a Constraint which is a remainder of non-greedy children sizes!!
  @override
  void newCoreLayout(BoxContainer parentBoxContainer) {
    // todo-00-last-last : this needs to be fixed. Maybe use BoxContainerNull : assert(isRoot == (parentBoxContainer == null));
    if (isRoot) {
      rootStep1_setRootConstraints(parentBoxContainer);
      rootStep3_Recurse_CheckForGreedyChildren_And_PlaceGreedyChildLast(parentBoxContainer);
      // todo-00-last : make sure it is set before call : layoutableBoxLayoutSandbox.constraints = boxContainerConstraints;
    }
    // A. node-pre-descend
    step301_PreDescend_DistributeMyConstraintToImmediateChildren(parentBoxContainer);
    // B. node-descend
    for (var child in children) {
      // 1. child-pre-descend (empty)
      // 2. child-descend
      child.newCoreLayout(parentBoxContainer); // todo-00-last-last-last-last : what is the parent? Why not 'this'???
      // 3. child-post-descend (empty
    }
    // C. node-post-descend
    step302_PostDescend_IfLeafSetMySize_Otherwise_OffsetImmediateChildrenInMe_ThenSetMySize(parentBoxContainer); // todo-00-last layout specific
  }

  // 2. Non-override new methods on this class, starting with layout methods -------------------------------------------

  // 2.1 Layout methods
  void rootStep3_Recurse_CheckForGreedyChildren_And_PlaceGreedyChildLast(BoxContainer parentBoxContainer) {
    // sets up childrenGreedyInMainLayoutAxis,  childrenGreedyInCrossLayoutAxis
    // if exactly 1 child greedy in MainLayoutAxis, put it last in childrenInLayoutOrder, otherwise childrenInLayoutOrder=children
    // this.constraints = passedConstraints
    int numGreedyAlongMainLayoutAxis = 0;
    BoxLayouter? greedyChild;
    for (var child in children) {
      child.rootStep3_Recurse_CheckForGreedyChildren_And_PlaceGreedyChildLast(parentBoxContainer);
      // _lengthAlongLayoutAxis(LayoutAxis layoutAxis, ui.Size size)
      if (child.isGreedy) {
        numGreedyAlongMainLayoutAxis += 1;
        greedyChild = child;
      }
      layoutableBoxLayoutSandbox.addedSizeOfAllChildren += ui.Offset(child.layoutSize.width, child.layoutSize.height);
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

  void rootStep1_setRootConstraints(BoxContainer parentBoxContainer) {
    // todo-done-important : SHOULD THIS BE ONLY ON THIS = ROOT??
    layoutableBoxLayoutSandbox.constraints = parentBoxContainer.layoutableBoxLayoutSandbox.constraints;
  }

  // Layout specific. Only children should be changed by setting constraints,
  //   created from this BoxLayouter constraints. Default sets same constraints.
  void step301_PreDescend_DistributeMyConstraintToImmediateChildren(BoxContainer parentBoxContainer) {
    for (var child in layoutableBoxLayoutSandbox.childrenInLayoutOrderGreedyLast) {
      // todo-00-last - how does this differ for Column, Row, etc?
      child.layoutableBoxLayoutSandbox.constraints = layoutableBoxLayoutSandbox.constraints;
    }
  }

  // Layout specific. Offsets children hierarchically (layout children), which positions them in this [BoxLayouter].
  // Then, sets this object's size as the envelope of all layed out children.
  void step302_PostDescend_IfLeafSetMySize_Otherwise_OffsetImmediateChildrenInMe_ThenSetMySize(BoxContainer parentBoxContainer) {
    if (isLeaf) {
      step301_IfLeafSetMySizeFromInternalsToFitWithinConstraints();
    } else {
      step301_IfNotLeafOffsetChildrenThenSetMySizeAndCheckIfMySizeFitWithinConstraints(parentBoxContainer);
    }
  }

  // Layouter specific!
  // Exception or visual indication if "my size" is NOT "within my constraints"
  void step301_IfNotLeafOffsetChildrenThenSetMySizeAndCheckIfMySizeFitWithinConstraints(BoxContainer parentBoxContainer) {
    if (hasGreedyChild) {
      List<LayoutableBox> notGreedyChildren = layoutableBoxLayoutSandbox.childrenInLayoutOrderGreedyLast.toList();
      notGreedyChildren.removeLast();
      offsetChildrenAccordingToLayouter(notGreedyChildren);
      // Calculate the size of envelop of all non-greedy children, layed out using this layouter.
      Size notGreedyChildrenSizeAccordingToLayouter = childrenLayoutSizeAccordingToLayouter(notGreedyChildren);
      // Re-calculate Size left for the Greedy child,
      // and set the greedy child's constraint and layoutSize to the re-calculated size left.
      BoxContainerConstraints constraints = firstGreedyChild.layoutableBoxLayoutSandbox.constraints;
      Size layoutSizeLeftForGreedyChild = constraints.sizeLeftAfter(notGreedyChildrenSizeAccordingToLayouter, mainLayoutAxis);
      firstGreedyChild.layoutSize = layoutSizeLeftForGreedyChild;
      firstGreedyChild.layoutableBoxLayoutSandbox.constraints = BoxContainerConstraints.exactBox(size: layoutSizeLeftForGreedyChild);
      // Having set a finite constraint on Greedy child, re-layout the Greedy child again.
      firstGreedyChild.newCoreLayout(firstGreedyChild as BoxContainer);
      // When the greedy child is re-layed out, we can deal with this node as if it had no greedy children - offset
      offsetChildrenAccordingToLayouter(children);
    } else {
      offsetChildrenAccordingToLayouter(children);
    }
  }

  void step301_IfLeafSetMySizeFromInternalsToFitWithinConstraints() {} // todo-00-last : make abstract

  // 2.2
  // List<LayoutableBox> get layoutableBoxes => children; // Each child is a LayoutableBox
  LayoutAxis mainLayoutAxis = LayoutAxis.defaultHorizontal; // todo-00 : consider default to horizontal (Row layout)
  bool get isLayout => mainLayoutAxis != LayoutAxis.defaultHorizontal;

  OneDimLayoutProperties mainAxisLayoutProperties = OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.left);
  OneDimLayoutProperties crossAxisLayoutProperties = OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.left);

  /// Greedy is defined as asking for layoutSize infinity.
  /// todo-00 : The greedy methods should check if called BEFORE
  ///           [step302_PostDescend_IfLeafSetMySize_Otherwise_OffsetImmediateChildrenInMe_ThenSetMySize].
  ///           Maybe there should be a way to express greediness permanently.
  bool get isGreedy {
    // if (mainLayoutAxis == LayoutAxis.defaultHorizontal) return false;

    return _lengthAlong(mainLayoutAxis, layoutSize) == double.infinity;
  }

  bool get hasGreedyChild => children.where((child) => child.isGreedy).isNotEmpty;

  LayoutableBox get firstGreedyChild => children.firstWhere((child) => child.isGreedy);

  ui.Size childrenLayoutSizeAccordingToLayouter(List<LayoutableBox> notGreedyChildren) {

    _MainAndCrossLayedOutSegments mainAndCrossLayedOutSegments = _findLayedOutSegmentsForChildren(notGreedyChildren);

    double mainLayedOutLength = mainAndCrossLayedOutSegments.mainAxisLayedOutSegments.totalLayedOutLength;
    double crossLayedOutLength = mainAndCrossLayedOutSegments.crossAxisLayedOutSegments.totalLayedOutLength;

    return _convertLengthsToSize(mainLayoutAxis, mainLayedOutLength, crossLayedOutLength);
  }

  /// Lays out all elements in [children], a list of [LayoutableBox]es, 
  /// by setting offset on each [LayoutableBox] element.
  /// 
  /// The offset on each [LayoutableBox] element is calculated using the [mainAxisLayoutProperties]
  /// in the main axis direction, and the [crossAxisLayoutProperties] in the cross axis direction.
  /// 
  /// Implementation detail: The processing is calling the [LengthsLayouter.layoutLengths], method.
  /// There are two instances of the [LengthsLayouter] created, one
  /// for the [mainLayoutAxis] (using the [mainAxisLayoutProperties]),  
  /// another and for axis perpendicular to [mainLayoutAxis] (using the [crossAxisLayoutProperties]).
  void offsetChildrenAccordingToLayouter(List<LayoutableBox> notGreedyChildren) {
    // Create a LengthsLayouter along each axis (main, cross), convert it to LayoutSegments,
    // then package into a wrapper class.
    _MainAndCrossLayedOutSegments mainAndCrossLayedOutSegments = _findLayedOutSegmentsForChildren(notGreedyChildren);

    // Convert the line segments to Offsets (in each axis), which are position where notGreedyChildren
    // will be layed out.
    List<ui.Offset> layedOutOffsets = _convertLayedOutSegmentsToOffsets(
      mainLayoutAxis,
      mainAndCrossLayedOutSegments,
      notGreedyChildren,
    );

    // Apply the offsets obtained by this specific [Layouter] onto the [LayoutableBox]es [children]
    _offsetChildren(layedOutOffsets, notGreedyChildren);
  }

  _MainAndCrossLayedOutSegments _findLayedOutSegmentsForChildren(List<LayoutableBox> notGreedyChildren) {
    // Create a LengthsLayouter along each axis (main, cross).
    LengthsLayouter mainAxisLengthsLayouter = _lengthsLayouterAlong(mainLayoutAxis, mainAxisLayoutProperties, notGreedyChildren);
    LengthsLayouter crossAxisLengthsLayouter = _lengthsLayouterAlong(axisPerpendicularTo(mainLayoutAxis), crossAxisLayoutProperties, notGreedyChildren);

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
    for (int i =  notGreedyChildren.length; i < layedOutOffsets.length; i++) {
      notGreedyChildren[i].applyParentOffset(layedOutOffsets[i]);
    }
  }

  /// todo-01-document
  List<ui.Offset> _convertLayedOutSegmentsToOffsets(
      LayoutAxis mainLayoutAxis,
      _MainAndCrossLayedOutSegments mainAndCrossLayedOutSegments,
      List<LayoutableBox> notGreedyChildren
      ) {
    var mainAxisLayedOutSegments = mainAndCrossLayedOutSegments.mainAxisLayedOutSegments;
    var crossAxisLayedOutSegments = mainAndCrossLayedOutSegments.crossAxisLayedOutSegments;

    if (mainAxisLayedOutSegments.lineSegments.length !=
        crossAxisLayedOutSegments.lineSegments.length) {
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

  /// Converts two [util_dart.LineSegment] to [Offset] according to [mainLayoutAxis].
  ui.Size _convertLengthsToSize(
      LayoutAxis mainLayoutAxis, double mainLength, double crossLength) {

    switch (mainLayoutAxis) {
      case LayoutAxis.defaultHorizontal:
      case LayoutAxis.horizontal:
        return ui.Size(mainLength, crossLength);
      case LayoutAxis.vertical:
        return ui.Size(crossLength, mainLength);
    }
  }

  /// Returns the passed [size]'s width or height along the passed [layoutAxis].
  double _lengthAlong(LayoutAxis layoutAxis, ui.Size size) {
    switch(layoutAxis) {
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
  LengthsLayouter _lengthsLayouterAlong(LayoutAxis layoutAxis, OneDimLayoutProperties axisLayoutProperties,
      List<LayoutableBox> notGreedyChildren,) {
    List<double> lengthsAlongLayoutAxis = _lengthsOfChildrenAlong(layoutAxis, notGreedyChildren);
    LengthsLayouter lengthsLayouterAlongLayoutAxis = LengthsLayouter(
      lengths: lengthsAlongLayoutAxis,
      oneDimLayoutProperties: axisLayoutProperties,
    );
    return lengthsLayouterAlongLayoutAxis;
  }

  /// Creates and returns a list of lengths of the [LayoutableBox]es [notGreedyChildren]
  /// measured along the passed [layoutAxis].
  List<double> _lengthsOfChildrenAlong(LayoutAxis layoutAxis, List<LayoutableBox> notGreedyChildren) =>
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
    // todo-done-00 : This was abstract, I implemented it like this . Where is it declared?
    // todo-00-last-last-last-last-last : Throw exception if this is instanceof new layout LEGEND containers
    newCoreLayout(parentBoxContainer);
  }

}

class RowLayouter extends BoxContainer {
  RowLayouter({
    required List<BoxContainer> children,
  }) {
    // Fields declared in mixin portion of BoxContainer cannot be initialized in initializer,
    //   but in constructor here. 
    // As a result, mixin fields can still be final, bust must be late, as they are 
    //   always initialized in concrete implementations.
    this.children = children;
    mainLayoutAxis = LayoutAxis.horizontal;
    mainAxisLayoutProperties = OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.center);
    crossAxisLayoutProperties = OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.center);
  }
  
  /* todo-00-last-last : this was empty implementation. I removed it to use default super
  @override
  void paint(ui.Canvas canvas) {}
  */

  /* todo-00-last-last : this was empty implementation. I removed it to use default super.
     BUT SHOULD ROW LAYOUT HAVE SPECIFIC IMPLEMENTATION? LIKELY!!!
  @override
  void layout(BoxContainerConstraints boxConstraints, BoxContainer parentBoxContainer) {}
  */
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
  ui.Size addedSizeOfAllChildren = const ui.Size(0.0, 0.0); // todo-00-last : this does not seem used in any meaningful way
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



