import 'dart:ui' as ui show Size, Offset, Canvas;
import 'package:flutter/material.dart';

import 'package:flutter_charts/src/chart/layouter_one_dimensional.dart' 
    show Lineup, Packing, OneDimLayoutProperties, LengthsLayouter, LayedOutLineSegments;
import 'package:flutter_charts/src/morphic/rendering/constraints.dart' show BoxContainerConstraints;
import 'package:flutter_charts/src/util/util_dart.dart' as util_dart show LineSegment;



/// Base class which manages, lays out, moves, and paints
/// graphical elements on the chart, for example individual
/// labels, but also a collection of labels.
///
/// This base class manages
///
/// Roles:
/// - Container: through the [layout] method.
/// - Translator (in X and Y direction): through the [applyParentOffset]
///   method.
/// - Painter: through the [paint] method.
///
/// Note on Lifecycle of [BoxContainer] : objects should be such that
///   after construction, methods should be called in the order declared here.
///
abstract class ContainerOld {
  /// Manages the layout size during the layout process in [layout].
  /// Should be only mentioned in this class, not super
  ui.Size layoutSize = ui.Size.zero;

  /// Current absolute offset, set by parent (and it's parent etc, to root).
  ///
  /// That means, it is the offset from (0,0) of the canvas. There is only one
  /// canvas, managed by the top Container, passed to all children in the
  /// [paint(Canvas, Size)].
  ///
  ///
  ///
  /// It is a sum of all offsets passed in subsequent calls
  /// to [applyParentOffset] during object lifetime.
  ui.Offset offset = ui.Offset.zero;

  /// Allow a parent container to move this Container
  /// after [layout].
  ///
  /// Override if parent move needs to propagate to internals of
  /// this [BoxContainer].
  void applyParentOffset(ui.Offset offset) {
    this.offset += offset;
  }

  /// [skipByParent] instructs the parent container that this container should not be
  /// painted or layed out - as if it collapsed to zero size.
  ///
  /// Note that concrete implementations must add
  /// appropriate support for collapse to work.
  bool skipByParent = false;

  /// If size constraints imposed by parent are too tight,
  /// some internal calculations of sizes may lead to negative values,
  /// making painting of this container not possible.
  ///
  /// Setting the [enableSkipOnDistressedSize] `true` helps to solve such situation.
  /// It causes the container not be painted
  /// (skipped during layout) when space is constrained too much
  /// (not enough space to reasonably paint the container contents).
  /// Note that setting this to `true` may result
  /// in surprizing behavior, instead of exceptions.
  ///
  /// Note that concrete implementations must add
  /// appropriate support for collapse to work.
  ///
  /// Unlike [skipByParent], which directs the parent to ignore this container,
  /// [enableSkipOnDistressedSize] is intended to be checked in code
  /// for some invalid conditions, and if they are reached, bypass painting
  /// the container.
  bool enableSkipOnDistressedSize = true; // todo-10 set to true for distress test

  bool isDistressed = false;

  ContainerOld();

  // ##### Abstract methods to implement

  // todo-01-morph : This should pass Constraints - see [RenderObject]
  void layout(BoxContainerConstraints boxConstraints);

  void paint(ui.Canvas canvas);
}

/// [BoxContainerHierarchy] is repeated here and in [BoxLayouter] 
/// to make clear that both [BoxContainer] and [BoxLayouter]
/// have the same  [BoxContainerHierarchy] trait (capability, role).
abstract class BoxContainer extends Object with BoxContainerHierarchy, BoxLayouter implements LayoutableBox {
  
  /// Default generative constructor. Prepares [parentSandbox].
  BoxContainer()  {
    children = [];
    parentSandbox = _BoxLayouterParentSandbox();
    layoutSandbox = _BoxLayouterLayoutSandbox();
  }
 
  void paint(ui.Canvas canvas);

}

/// todo-00-document
enum LayoutAxis {
  none,
  horizontal,
  vertical
}

LayoutAxis axisPerpendicularTo(LayoutAxis layoutAxis) {
  switch(layoutAxis) {
    case LayoutAxis.horizontal:
      return LayoutAxis.vertical;
    case LayoutAxis.vertical:
      return LayoutAxis.horizontal;
    case LayoutAxis.none:
      throw StateError('Cannot ask for axis perpendicular to none.');
  }
}


mixin BoxContainerHierarchy {
  late final BoxContainer? parent;  // will be initialized when addChild(this) is called on this parent
  late final List<BoxContainer> children; // will be initialized in concrete impls such as ColumnLayouter
  bool get isRoot => parent == null;
  bool get isLeaf => children.isEmpty;

  void addChild(BoxContainer boxContainer) {
    boxContainer.parent = boxContainer;
    children.add(boxContainer);
  }
}

// todo-00-last : Get rid of this or improve.
abstract class LayoutableBox {
  ui.Size layoutSize = Size.zero;
  void applyParentOffset(ui.Offset offset);
  _BoxLayouterLayoutSandbox layoutSandbox = _BoxLayouterLayoutSandbox();
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
/// by the side effects of the method [offsetChildrenAccordingToLayouter]. 
mixin BoxLayouter on BoxContainerHierarchy implements LayoutableBox {

  /// Manages the layout size during the layout process in [layout].
  /// Should be only mentioned in this class, not super
  @override
  ui.Size layoutSize = ui.Size.zero;
  
  // List<LayoutableBox> get layoutableBoxes => children; // Each child is a LayoutableBox
  LayoutAxis mainLayoutAxis = LayoutAxis.none; // todo-00 : consider default to horizontal (Row layout)
  bool get isLayout => mainLayoutAxis != LayoutAxis.none;

  OneDimLayoutProperties mainAxisLayoutProperties = OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.left);
  OneDimLayoutProperties crossAxisLayoutProperties = OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.left);

  /// Member used during the [layout] processing.
  @override
  _BoxLayouterLayoutSandbox layoutSandbox = _BoxLayouterLayoutSandbox(); // todo-00-last : MAKE NOT NULLABLE 

  /// Greedy is defined as asking for layoutSize infinity.
  /// todo-00 : The greedy methods should check if called BEFORE
  ///           [step302_PostDescend_IfLeafSetMySize_Otherwise_OffsetImmediateChildrenInMe_ThenSetMySize].
  ///           Maybe there should be a way to express greediness permanently.
  bool get isGreedy => _lengthAlong(mainLayoutAxis, layoutSize) == double.infinity;

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

  /// todo-00-document
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
      case LayoutAxis.horizontal:
        return ui.Offset(mainSegment.min, crossSegment.min);
      case LayoutAxis.vertical:
        return ui.Offset(crossSegment.min, mainSegment.min);
      case LayoutAxis.none:
        throw StateError('Asking for a segments to Offset conversion, but layoutAxis is none.');
    }
  }

  /// Converts two [util_dart.LineSegment] to [Offset] according to [mainLayoutAxis].
  ui.Size _convertLengthsToSize(
      LayoutAxis mainLayoutAxis, double mainLength, double crossLength) {

    switch (mainLayoutAxis) {
      case LayoutAxis.horizontal:
        return ui.Size(mainLength, crossLength);
      case LayoutAxis.vertical:
        return ui.Size(crossLength, mainLength);
      case LayoutAxis.none:
        throw StateError('Asking for lenghts to Size, but layoutAxis is none.');
    }
  }

  /// Returns the passed [size]'s width or height along the passed [layoutAxis].
  double _lengthAlong(LayoutAxis layoutAxis, ui.Size size) {
    switch(layoutAxis) {
      case LayoutAxis.horizontal:
        return size.width;
      case LayoutAxis.vertical:
        return size.height;
      case LayoutAxis.none:
        throw StateError('Asking for a length along the layout axis, but layoutAxis is none.');
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

  // ------------ Fields managed by Sandbox and methods delegated to Sandbox.

  // todo-00-last : consider merging layoutSandbox and parentSandbox
  _BoxLayouterParentSandbox? parentSandbox; // todo-00-last make NON NULL

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
  ui.Offset get offset => parentSandbox!.offset;

  /// Allow a parent containerNew to move this ContainerNew
  /// after [layout].
  ///
  /// Override if parent move needs to propagate to internals of
  /// this [ContainerNew].
  @override
  void applyParentOffset(ui.Offset offset) {
    // todo-01-last : add caller arg, pass caller=this and check : assert(caller == parent);
    //                same on all methods delegated to parentSandbox
    parentSandbox!.applyParentOffset(offset);
  }

  set parentOrderedToSkip(bool skip) {
    if (skip && !allowParentToSkipOnDistressedSize) {
      throw StateError('Parent did not allow to skip');
    }
    parentSandbox!.parentOrderedToSkip = skip;
  }
  bool get parentOrderedToSkip => parentSandbox!.parentOrderedToSkip;


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

  void layout(BoxContainerConstraints boxConstraints);

  // Core recursive layout method.
  // todo-00-last : Why do I need greedy children last? So I can give them a Constraint which is a remainder of non-greedy children sizes!!
  @override
  void newCoreLayout() {
    if (isRoot) {
      rootStep1_setRootConstraint();
      rootStep2_Recurse_setupContainerHierarchy();
      rootStep3_Recurse_CheckForGreedyChildren_And_PlaceGreedyChildLast();
      // todo-00-last : make sure it is set before call : layoutSandbox.constraints = boxContainerConstraints;
    }
    // node-pre-descend
    step301_PreDescend_DistributeMyConstraintToImmediateChildren();
    // node-descend  
    for (var child in children) {
      // child-pre-descend
      // child-descend
      child.newCoreLayout();
      // child-post-descend
    }
    // node-post-descend
    step302_PostDescend_IfLeafSetMySize_Otherwise_OffsetImmediateChildrenInMe_ThenSetMySize(); // todo-00-last layout specific
  }

  /// Create and add children of this container.
  void rootStep2_Recurse_setupContainerHierarchy() {
    for (var child in children) {
      child.createChildrenOrUseChildrenFromConstructor();
      child.rootStep2_Recurse_setupContainerHierarchy();
    }
  }

  // todo-00-last make abstract, each Container must implement. Layouter has this no-op.
  // Create children one after another, or do nothing if children were created in constructor.
  // Any child created here must be added to the list of children.
  //   - if (we do not want any children created here (may exist from constructor)) return
  //   - create childN
  //   - addChild(childN)
  //   - etc
  void createChildrenOrUseChildrenFromConstructor() {}

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
      layoutSandbox.addedSizeOfAllChildren += ui.Offset(child.layoutSize.width, child.layoutSize.height);
    }
    if (numGreedyAlongMainLayoutAxis >= 2) {
      throw StateError('Max one child can ask for unlimited (greedy) size along main layout axis. Violated in $this');
    }
    layoutSandbox.childrenInLayoutOrderGreedyLast = List.from(children);
    if (greedyChild != null) {
      layoutSandbox.childrenInLayoutOrderGreedyLast
        ..remove(greedyChild)
        ..add(greedyChild);
    }
  }

  void rootStep1_setRootConstraint() {
    // todo-00-last implement where needed
  }
  
  // Layout specific. Only children should be changed by setting constraints,
  //   created from this BoxLayouter constraints. Default sets same constraints.
  void step301_PreDescend_DistributeMyConstraintToImmediateChildren() {
    for (var child in layoutSandbox.childrenInLayoutOrderGreedyLast) {
      // todo-00-last - how does this differ for Column, Row, etc?
      child.layoutSandbox.constraints = layoutSandbox.constraints;
    }
  }

  // Layout specific. Offsets children hierarchically (layout children), which positions them in this [BoxLayouter].
  // Then, sets this object's size as the envelope of all layed out children.
  void step302_PostDescend_IfLeafSetMySize_Otherwise_OffsetImmediateChildrenInMe_ThenSetMySize() {
    if (isLeaf) {
      step301_IfLeafSetMySizeFromInternalsToFitWithinConstraints();
    } else {
      step301_IfNotLeafOffsetChildrenThenSetMySizeAndCheckIfMySizeFitWithinConstraints();
    }
  }

  // Layouter specific!
  // Exception or visual indication if "my size" is NOT "within my constraints"
  void step301_IfNotLeafOffsetChildrenThenSetMySizeAndCheckIfMySizeFitWithinConstraints() {
    if (hasGreedyChild) {
      List<LayoutableBox> notGreedyChildren = layoutSandbox.childrenInLayoutOrderGreedyLast.toList();
      notGreedyChildren.removeLast();
      offsetChildrenAccordingToLayouter(notGreedyChildren);
      // Calculate the size of envelop of all non-greedy children, layed out using this layouter.
      Size notGreedyChildrenSizeAccordingToLayouter = childrenLayoutSizeAccordingToLayouter(notGreedyChildren);
      // Re-calculate Size left for the Greedy child, 
      // and set the greedy child's constraint and layoutSize to the re-calculated size left.
      BoxContainerConstraints? constraints = firstGreedyChild.layoutSandbox.constraints;
      Size layoutSizeLeftForGreedyChild = constraints!.sizeLeftAfter(notGreedyChildrenSizeAccordingToLayouter, mainLayoutAxis);
      firstGreedyChild.layoutSize = layoutSizeLeftForGreedyChild;
      firstGreedyChild.layoutSandbox.constraints = BoxContainerConstraints.exactBox(size: layoutSizeLeftForGreedyChild);
      // Having set a finite constraint on Greedy child, re-layout the Greedy child again.
      firstGreedyChild.newCoreLayout();
      // When the greedy child is re-layed out, we can deal with this node as if it had no greedy children - offset
      offsetChildrenAccordingToLayouter(children);
    } else {
      offsetChildrenAccordingToLayouter(children);
    }
  }

  void step301_IfLeafSetMySizeFromInternalsToFitWithinConstraints() {} // todo-00-last : make abstract
}

class RowLayouter extends BoxContainer {
  RowLayouter({
    required List<BoxContainer> children,
  }) {
    // Fields declared from parent mixin portion cannot be initialized in initializer,
    //   but in constructor here. 
    // As a result, mixin fields can still be final, bust must be late, as they are 
    //   always initialized in concrete implementations.
    this.children = children;
    mainLayoutAxis = LayoutAxis.horizontal;
    mainAxisLayoutProperties = OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.center);
    crossAxisLayoutProperties = OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.center);
  }
  
  // todo-00-last-last make abstract or implement
  @override
  void paint(ui.Canvas canvas) {}

  // todo-00-last-last make abstract or implement
  @override
  void layout(BoxContainerConstraints boxConstraints) {}

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

// todo-01-last : try to make non-nullable and final
class _BoxLayouterLayoutSandbox {
  List<BoxLayouter> childrenInLayoutOrderGreedyLast = [];
  ui.Size addedSizeOfAllChildren = const ui.Size(0.0, 0.0);
  BoxContainerConstraints? constraints;

}

// todo-00-document
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
  ui.Offset offset = ui.Offset.zero;

  /// Allow a parent containerNew to move this ContainerNew
  /// after [layout].
  ///
  /// Override if parent move needs to propagate to internals of
  /// this [ContainerNew].
  void applyParentOffset(ui.Offset offset) {
    this.offset += offset;
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



