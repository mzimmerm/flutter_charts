import 'dart:math' as math show max;
import 'dart:ui' as ui show Size, Offset;

import 'package:flutter/material.dart';
import 'package:flutter_charts/src/chart/container_base.dart' show BoxContainer;
import 'package:flutter_charts/src/util/util_dart.dart' as util_dart show LineSegment;

import '../morphic/rendering/constraints.dart' show BoxContainerConstraints;

/// todo-00-document
enum LayoutAxis {
  none,
  horizontal,
  vertical
}

/// [Packing] describes mutually exclusive layouts for a list of lengths 
/// (imagined as ordered line segments) on a line.
/// 
/// The supported packing methods
/// - Matrjoska packing places each smaller segment fully into the next larger one (next means next by size). 
///   Order does not matter.
/// - Snap packing places each next segment's begin point just right of it's predecessor's end point.
/// - Loose packing is like snap packing, but, in addition, there can be a space between neighbour segments.
/// 
/// The only layout not described (and not allowed) is a partial overlap of any two lengths.
enum Packing {
  /// [Packing.matrjoska] should layout elements so that the smallest element is fully
  /// inside the next larger element, and so on. The largest element contains all smaller elements.
  matrjoska,
  /// [Packing.snap] should layout elements in a way they snap together into a group with no padding between elements.
  /// 
  /// If the available [LengthsLayouter._freePadding] is zero, 
  /// the result is the same for any [Align] value.
  /// 
  /// If the available [LengthsLayouter._freePadding] is non zero:
  /// 
  /// - For [Align.min] or [Align.max] : Also aligns the group to min or max boundary.
  ///   For [Align.min], there is no padding between min and first element of the group,
  ///   all the padding [LengthsLayouter._freePadding] is after the end of the group; 
  ///   similarly for [Align.max], for which the group end is aligned with the end,
  ///   and all the padding [LengthsLayouter._freePadding] is before the group.
  /// - For [Align.center] : The elements are packed into a group and the group centered.
  ///   That means, when [LengthsLayouter._freePadding] is available, half of the free length pads 
  ///   the group on the boundaries
  ///   
  snap,
  /// [Packing.loose] should layout elements so that they are separated with even amount of padding, 
  /// if the available padding defined by [LengthsLayouter._freePadding] is not zero. 
  /// If the available padding is zero, layout is the same as [Packing.snap] with no padding. 
  /// 
  /// If the available [LengthsLayouter._freePadding] is zero, 
  /// the result is the same for any [Align] value, 
  /// and also the same as the result of [Packing.snap] for any [Align] value: 
  /// All elements are packed together.
  ///
  /// If the available [LengthsLayouter._freePadding] is non zero:
  /// 
  /// - For [Align.min] or [Align.max] : Aligns the first element start to the min,
  ///   or the last element end to the max, respectively. 
  ///   For [Align.min], the available [LengthsLayouter._freePadding] is distributed evenly 
  ///   as padding between elements and at the end. First element start is at the boundary.
  ///   For [Align.max], the available [LengthsLayouter._freePadding] is distributed evenly 
  ///   as padding at the beginning, and between elements. Last element end is at the boundary.
  /// - For [Align.center] : Same proportions of [LengthsLayouter._freePadding] 
  ///   are distributed as padding at the beginning, between elements, and at the end.
  ///   
  loose,
}

/// todo-00-document
enum Align { min, center, max }

/// Properties of [BoxLayouter] describe packing and alignment of the layed out elements along
/// either a main axis or cross axis.
/// 
/// This class is also used to describe packing and alignment of the layed out elements 
/// for the [LengthsLayouter], where it serves to describe the one-dimensional packing and alignment.
class BoxLayoutProperties {
  final Packing packing;
  final Align align;
  double? totalLength;
  BoxLayoutProperties({
    required this.packing,
    required this.align,
    this.totalLength,
  });
}


/// todo-00-document
class LengthsLayouter {
  LengthsLayouter({
    required this.lengths,
    required this.boxLayoutProperties,
  }) {
    switch (boxLayoutProperties.packing) {
      case Packing.matrjoska:
        boxLayoutProperties.totalLength ??= _maxLength;
        assert(boxLayoutProperties.totalLength! >= _maxLength);
        _freePadding = boxLayoutProperties.totalLength! - _maxLength;
        break;
      case Packing.snap:
      case Packing.loose:
      boxLayoutProperties.totalLength ??= _sumLengths;
        assert(boxLayoutProperties.totalLength! >= _sumLengths);
        _freePadding = boxLayoutProperties.totalLength! - _sumLengths;
        break;
    }
  }

  final List<double> lengths;
  /// todo-00-last Refactor so that packing, align, totalLength is organized in [BoxLayoutProperties].
/*
  final Packing packing;
  final Align align;
  double? totalLength;
*/
  BoxLayoutProperties boxLayoutProperties;
  late final double _freePadding;

  LayedOutLineSegments layoutLengths() {
    LayedOutLineSegments layedOutLineSegments;
    switch (boxLayoutProperties.packing) {
      case Packing.matrjoska:
        layedOutLineSegments = LayedOutLineSegments(
            lineSegments: lengths.map((length) => _matrjoskaLayoutLineSegmentFor(length)).toList(growable: false));
        break;
      case Packing.snap:
        layedOutLineSegments = LayedOutLineSegments(
            lineSegments: _snapOrLooseLayoutAndMapLengthsToSegments(_snapLayoutLineSegmentFor));
        break;
      case Packing.loose:
        layedOutLineSegments = LayedOutLineSegments(
            lineSegments: _snapOrLooseLayoutAndMapLengthsToSegments(_looseLayoutLineSegmentFor));
        break;
    }
    return layedOutLineSegments;
  }

  double get _sumLengths => lengths.fold(0.0, (previousLength, length) => previousLength + length);

  double get _maxLength => lengths.fold(0.0, (previousValue, length) => math.max(previousValue, length));

  /// Intended for use in  [Packing.matrjoska], creates and returns a [util_dart.LineSegment] for the passed [length], 
  /// positioning the [util_dart.LineSegment] according to [align].
  /// 
  /// [Packing.matrjoska] ignores order of lengths, so there is no dependence on lenght predecessor.
  /// 
  /// Also, for [Packing.matrjoska], the [align] applies *both* for alignment of lines inside the Matrjoska,
  /// as well as the whole largest Matrjoska alignment inside the available [totalLength].
  util_dart.LineSegment _matrjoskaLayoutLineSegmentFor(double length) {
    double start, end;
    switch (boxLayoutProperties.align) {
      case Align.min:
        start = 0.0;
        end = length;
        break;
      case Align.center:
        double freePadding = _freePadding / 2;
        double matrjoskaInnerRoomLeft = (_maxLength - length) / 2;
        start = freePadding + matrjoskaInnerRoomLeft;
        end = freePadding + matrjoskaInnerRoomLeft + length;
        break;
      case Align.max:
        start = _freePadding + _maxLength - length;
        end = _freePadding + _maxLength;
        break;
    }

    return util_dart.LineSegment(start, end);
  }

  List<util_dart.LineSegment> _snapOrLooseLayoutAndMapLengthsToSegments(util_dart.LineSegment Function(util_dart.LineSegment?, double ) fromPreviousLengthLayoutThis ) {
    List<util_dart.LineSegment> lineSegments = [];
    util_dart.LineSegment? previousSegment;
    for (int i = 0; i < lengths.length; i++) {
      if (i == 0) {
        previousSegment = null;
      }
      previousSegment = fromPreviousLengthLayoutThis(previousSegment, lengths[i]);
      lineSegments.add(previousSegment);
    }
    return lineSegments;
  }

  util_dart.LineSegment _snapLayoutLineSegmentFor(util_dart.LineSegment? previousSegment, double length,) {
    return _snapOrLooseLayoutLineSegmentFor(_snapStartOffset, previousSegment, length);
  }

  util_dart.LineSegment _looseLayoutLineSegmentFor(util_dart.LineSegment? previousSegment, double length,) {
    return _snapOrLooseLayoutLineSegmentFor(_looseStartOffset, previousSegment, length);
  }

  util_dart.LineSegment _snapOrLooseLayoutLineSegmentFor(double Function(bool) getStartOffset, util_dart.LineSegment? previousSegment, double length,) {
    bool isFirstLength = false;
    if (previousSegment == null) {
      isFirstLength = true;
      previousSegment = util_dart.LineSegment(0.0, 0.0);
    }
    double startOffset = getStartOffset(isFirstLength);
    double start = startOffset + previousSegment.max;
    double end = startOffset + previousSegment.max + length;
    return util_dart.LineSegment(start, end);
  }

  double _snapStartOffset(bool isFirstLength) {
    double freePadding, startOffset;
    switch (boxLayoutProperties.align) {
      case Align.min:
        freePadding = 0.0;
        startOffset = freePadding;
        break;
      case Align.center:
        freePadding = _freePadding / 2; // for center, half freeLength to the left
        startOffset = isFirstLength ? freePadding : 0.0;
        break;
      case Align.max:
        freePadding = _freePadding; // for max, all freeLength to the left
        startOffset = isFirstLength ? freePadding : 0.0;
        break;
    }
    return startOffset;
  }

  double _looseStartOffset(bool isFirstLength) {
    int lengthsCount = lengths.length;
    double freePadding, startOffset;
    switch (boxLayoutProperties.align) {
      case Align.min:
        freePadding = lengthsCount != 0 ? _freePadding / lengthsCount : _freePadding;
        startOffset = isFirstLength ? 0.0 : freePadding;
        break;
      case Align.center:
        freePadding = lengthsCount != 0 ? _freePadding / (lengthsCount + 1) : _freePadding;
        startOffset = freePadding;
        break;
      case Align.max:
        freePadding = lengthsCount !=0 ? _freePadding / lengthsCount : _freePadding;
        startOffset = freePadding;
        break;
    }
    return startOffset;
  }

}

/// todo-00-document
class LayedOutLineSegments {
  LayedOutLineSegments({required this.lineSegments});

  final List<util_dart.LineSegment> lineSegments;

  @override
  bool operator ==(Object other) {
    bool typeSame = other is LayedOutLineSegments &&
        other.runtimeType == runtimeType;
    if (!typeSame) {
      return false;
    }

    // Dart knows other is LayedOutLineSegments, but for clarity:
    LayedOutLineSegments otherSegment = other;
    if (lineSegments.length != otherSegment.lineSegments.length) {
      return false;
    }
    for (int i = 0; i < lineSegments.length; i++) {
      if (lineSegments[i] != otherSegment.lineSegments[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    return lineSegments.fold(0, (previousValue, lineSegment) => previousValue + lineSegment.hashCode);
  }
}

mixin BoxContainerHierarchy {
  late final BoxContainer? parent;
  final List<BoxContainer> children = [];
  bool get isRoot => parent == null;
  bool get isLeaf => children.isEmpty;

  void addChild(BoxContainer boxContainer) {
    boxContainer.parent = boxContainer;
    children.add(boxContainer);
  }
}

abstract class LayoutableBox {
 ui.Size get layoutSize;
 // ui.Offset get layoutableBoxOffset;
 // set offset(ui.Offset offset);
 void applyParentOffset(ui.Offset offset);
}

/// todo-00-last-last  convert to extension of BoxContainer - or a mixin?.
/// Layouter of a list of [LayoutableBox]s.
/// 
/// The role of this class is to lay out boxes along the main axis and the cross axis,
/// given layout properties for alignment and packing.
/// 
/// Created from the [layoutableBoxes], a list of [LayoutableBox]s, and the definitions
/// of [mainLayoutAxis] and [crossLayoutAxis], along with the alignment and packing properties 
/// along each of those axis, [mainAxisBoxLayoutProperties] and [crossAxisBoxLayoutProperties]
/// 
/// The core function of this class is to layout (offset) the member boxes [layoutableBoxes] 
/// by the side effects of the method [layoutAndOffsetBoxes]. 
mixin BoxLayouter on BoxContainerHierarchy implements LayoutableBox {


  /// Manages the layout size during the layout process in [layout].
  /// Should be only mentioned in this class, not super
  ui.Size layoutSize = ui.Size.zero;

/* todo-00-last-last move to BoxContainer constructor, especially the asserts
  BoxLayouter({
    required this.layoutableBoxes,
    required this.mainLayoutAxis,
    required this.crossLayoutAxis,
    required this.mainAxisBoxLayoutProperties,
    required this.crossAxisBoxLayoutProperties,
  }) {
    assert(mainLayoutAxis != LayoutAxis.none);
    assert(crossLayoutAxis != LayoutAxis.none);
    assert(mainLayoutAxis != crossLayoutAxis);
  }
*/

  // todo-00-last Same members as in BoxContainer. Later, move or delegate them from BoxContainer here
  // List<LayoutableBox> layoutableBoxes = []; // todo-00-last-last-last : these are children!!
  List<LayoutableBox> get layoutableBoxes => children;
  LayoutAxis mainLayoutAxis = LayoutAxis.none;
  LayoutAxis crossLayoutAxis = LayoutAxis.none;
  bool get isLayout => mainLayoutAxis != LayoutAxis.none || crossLayoutAxis != LayoutAxis.none;
  
  BoxLayoutProperties mainAxisBoxLayoutProperties = BoxLayoutProperties(packing: Packing.snap, align: Align.min);
  BoxLayoutProperties crossAxisBoxLayoutProperties = BoxLayoutProperties(packing: Packing.snap, align: Align.min);

  BoxContainerLayoutSandbox layoutSandbox = BoxContainerLayoutSandbox(); // // todo-00-last-last-done : moved from  BoxContainer MAKE NOT NULLABLE 

  /// todo-00-last-last-done : moved here from BoxContainerBase, then replaced with _lengthAlongLayoutAxis
/*
  double layoutLengthAlongMainLayoutAxis() {
    if (mainLayoutAxis == LayoutAxis.horizontal) {
      return layoutSize.width;
    }
    if (mainLayoutAxis == LayoutAxis.vertical) {
      return layoutSize.height;
    }
    return 0.0;
  }
*/
  
  /// Lays out all elements in [layoutableBoxes], by setting offset on each [LayoutableBox] element.
  /// 
  /// The offset on each [LayoutableBox] element is calculated using the [mainAxisLayoutProperties]
  /// in the main axis direction, and the [crossAxisLayoutProperties] in the cross axis direction.
  /// 
  /// Implementation detail: The processing is calling the [LengthsLayouter.layoutLengths], method.
  /// There are two instances of the [LengthsLayouter] created, one
  /// for the [mainLayoutAxis] (using the [mainAxisLayoutProperties]),  
  /// another for the [crossLayoutAxis] (using the [crossAxisLayoutProperties]).
  // todo-00-last-last : This must be called somewhere!!
  void layoutAndOffsetBoxes() {
    // Create a LengthsLayouter along each axis (main, cross).
    LengthsLayouter mainAxisLengthsLayouter = _lengthsLayouterAlong(mainLayoutAxis, mainAxisBoxLayoutProperties);
    LengthsLayouter crossAxisLengthsLayouter = _lengthsLayouterAlong(crossLayoutAxis, crossAxisBoxLayoutProperties);
    
    // Layout the lengths along each axis to line segments (offset-ed lengths).   
    LayedOutLineSegments mainAxisLayedOutSegments = mainAxisLengthsLayouter.layoutLengths();
    LayedOutLineSegments crossAxisLayedOutSegments = crossAxisLengthsLayouter.layoutLengths();
    
    // Convert the line segments to Offsets (in each axis)
    List<ui.Offset> layedOutOffsets = _convertLayedOutSegmentsToOffsets(
      mainLayoutAxis,
      mainAxisLayedOutSegments,
      crossAxisLayedOutSegments,
      );
    
    // Apply the offsets obtained by layouting onto the layoutableBoxes
    assert(layedOutOffsets.length == layoutableBoxes.length);
    for (int i =  layoutableBoxes.length; i < layedOutOffsets.length; i++) {
      layoutableBoxes[i].applyParentOffset(layedOutOffsets[i]);
    }
  }
  
  /// todo-00-document
  List<ui.Offset> _convertLayedOutSegmentsToOffsets(
      LayoutAxis mainLayoutAxis,
      LayedOutLineSegments mainAxisLayedOutSegments,
      LayedOutLineSegments crossAxisLayedOutSegments,
      ) {

    if (mainAxisLayedOutSegments.lineSegments.length != crossAxisLayedOutSegments.lineSegments.length) {
      throw StateError('Segments differ in lengths: main=$mainAxisLayedOutSegments, cross=$crossAxisLayedOutSegments');
    }
    
    List<ui.Offset> layedOutOffsets = [];

    for (int i = 0; i < mainAxisLayedOutSegments.lineSegments.length; i++) {
      ui.Offset offset = _segmentsToOffset(
        mainLayoutAxis, mainAxisLayedOutSegments.lineSegments[i], crossAxisLayedOutSegments.lineSegments[i]);
      layedOutOffsets.add(offset);
    }
    return layedOutOffsets;
  }

  /// Converts two [util_dart.LineSegment] to [Offset] according to [mainLayoutAxis].
  ui.Offset _segmentsToOffset(
      LayoutAxis mainLayoutAxis, util_dart.LineSegment mainSegment, util_dart.LineSegment crossSegment) {
    ui.Offset offset;

    // Only the segments' beginnings are used for offset on BoxLayouter. 
    // The segments' ends are already taken into account in BoxLayouter.size.
    switch (mainLayoutAxis) {
      case LayoutAxis.horizontal:
        return ui.Offset(mainSegment.min, crossSegment.min);
        break;
      case LayoutAxis.vertical:
        return offset = ui.Offset(crossSegment.min, mainSegment.min);
      case LayoutAxis.none:
        throw StateError('Asking for a segment offset, but layoutAxis is none.');
    }
  }

  /// Creates a [LengthsLayouter] along the passed [layoutAxis], with the passed [axisLayoutProperties].
  /// 
  /// The passed objects must both correspond to either main axis or the cross axis.
  LengthsLayouter _lengthsLayouterAlong(LayoutAxis layoutAxis, BoxLayoutProperties axisLayoutProperties) {
    List<double> lengthsAlongLayoutAxis = _lengthsAlongLayoutAxis(layoutAxis);
    LengthsLayouter lengthsLayouterAlongLayoutAxis = LengthsLayouter(
      lengths: lengthsAlongLayoutAxis,
      boxLayoutProperties: axisLayoutProperties,
    );
    return lengthsLayouterAlongLayoutAxis;
  }
  
  /// Returns the passed [size]'s width or height along the passed [layoutAxis].
  double _lengthAlongLayoutAxis(LayoutAxis layoutAxis, ui.Size size) {
    switch(layoutAxis) {
      case LayoutAxis.horizontal:
        return size.width;
      case LayoutAxis.vertical:
        return size.height;
      case LayoutAxis.none:
        throw StateError('Asking for a length along the layout axis, but layoutAxis is none.');
    }
  }
  
  /// Creates and returns a list of lengths of the [layoutableBoxes]
  /// measured along the passed [layoutAxis].
  List<double> _lengthsAlongLayoutAxis(LayoutAxis layoutAxis) => 
      layoutableBoxes.map((layoutableBox) => _lengthAlongLayoutAxis(layoutAxis, layoutableBox.layoutSize)).toList();
  
////////////////////////////////////////////////////////////// todo-00-last-last moved here from BoxContainerBase

  // ------------ Fields managed by Sandbox and methods delegated to Sandbox.

  // todo-00-last : consider moving some fields to layoutSandbox
  BoxContainerParentSandbox? parentSandbox; // todo-00-last-last make NON NULL

  /// Member used during the [layout] processing.
// todo-00-last-last-done : moved to BoxLayouter  final BoxContainerLayoutSandbox layoutSandbox;

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
  void applyParentOffset(ui.Offset offset) {
    // todo-01-last : add caller arg, pass caller=this and check : assert(caller == _parent);
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
  // todo-00-last-last-done : LayoutAxis mainLayoutAxis = LayoutAxis.none;
  // todo-00-last-last-done : LayoutAxis crossLayoutAxis = LayoutAxis.none;
  // todo-00-last-last-done : bool get isLayout => mainLayoutAxis != LayoutAxis.none || crossLayoutAxis != LayoutAxis.none;


  // ##### Abstract methods to implement

  void layout(BoxContainerConstraints boxConstraints);

  // Core recursive layout method.
  // todo-00-last : Why do I need greedy children last? So I can give them a Constraint which is a remainder of non-greedy children sizes!!
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
      if (child._lengthAlongLayoutAxis(mainLayoutAxis, child.layoutSize) == double.infinity) {
      // todo-00-last-last-done : if (child.layoutLengthAlongMainLayoutAxis() == double.infinity) {
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
  // Layout specific. only children changed, then next method. Default sets same constraints
  void step301_PreDescend_DistributeMyConstraintToImmediateChildren() {
    for (var child in layoutSandbox.childrenInLayoutOrderGreedyLast) {
      // todo-00-last - how does this differ for Column, Row, etc?
      child.layoutSandbox.constraints = layoutSandbox.constraints;
    }
  }

  void step302_PostDescend_IfLeafSetMySize_Otherwise_OffsetImmediateChildrenInMe_ThenSetMySize() {
    if (isLeaf) {
      step301_IfLeafSetMySizeFromInternalsToFitWithinConstraints();
    } else {
      step301_IfNotLeafOffsetChildrenAndCheckIfMySizeFitWithinConstraints();
    }
  }

  // Layouter specific!
  // Exception or visual indication if "my size" is NOT "within my constraints"
  void step301_IfNotLeafOffsetChildrenAndCheckIfMySizeFitWithinConstraints() {
    BoxLayouter? previousChild;
    for (var child in layoutSandbox.childrenInLayoutOrderGreedyLast) {
      // todo-00 : add static method on Size to do Size + Size.
      // todo-00-last-last : need method for envelop of list of children except last greedy
      /* todo-00-last-last : implement this for RowLayouter and ColumnLayouter
          MAYBE THIS NEEDS TO BE A SEPARATE ABSTRACT METHOD 
      ui.Size previousChildOffset = previousChild != null ? previousChild.offset : const ui.Size(0.0, 0.0);
      child.applyParentOffset(previousChild.offset + child.layoutSize); 
      layoutSize = const ui.Size(0.0, 0.0); // size of children envelop
      IF THIS IS A LAST CHILD, AND IT IS GREEDY, RE-SET THE CHILD CONSTRAINT AS MY_CONSTRAINT minus ENVELOP OF PREVIOUS CHILDREN
      THEN CALCULATE THIS GREEDY CHILD LAYOUT AND SET SIZE.
      */
      previousChild = child;
    }
  }


  void step301_IfLeafSetMySizeFromInternalsToFitWithinConstraints() {} // todo-00-last : make abstract

// todo-01 : split:
//           - Container to BoxContainer and PieContainer
//           - Shape to BoxShape (wraps Size) and PieShape
//           - ContainerConstraint to BoxContainerConstraint and PieContainerConstraint 
// todo-01 : Change this base class Container.layout to 
//               Shape layout({required covariant ContainerConstraints constraints}); // Must set Shape (Size for now) on parentSandbox 
//           This base layout maybe eventually configures some constraints caching and debugging.
//           Extensions of Container: BoxContainer, PieContainer override layout as
//               BoxShape layout({required covariant BoxContainerConstraints constraints}); // Must set BoxShape (essentially, this is Size)  on parentSandbox 
//               PieShape layout({required covariant PieContainerConstraints constraints}); // Must set PieShape on parentSandbox

}
// todo-00-last : BoxLayouter, base class for ColumnLayouter and RowLayouter
//                BoxLayouter extends BoxContainer, uses LengthsLayouter to modify Container.children.layoutSize and Container.children.offset

// todo-00-done BoxContainerLayoutSandbox - a new class -----------------------------------------------------------------

// todo-01-last : try to make non-nullable and final
class BoxContainerLayoutSandbox {
  List<BoxLayouter> childrenInLayoutOrderGreedyLast = [];
  // List<BoxContainer> childrenGreedyAlongMainLayoutAxis = [];
  // List<BoxContainer> childrenGreedyAlongCrossLayoutAxis = [];
  ui.Size addedSizeOfAllChildren = const ui.Size(0.0, 0.0);
  BoxContainerConstraints? constraints;

}

// todo-00-document
/// Only parent containers of the container that owns this object should be allowed to 
/// get or set any field inside this object.
class BoxContainerParentSandbox {

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

// todo-00-done : added then removed : BoxContainerConstraints constraints = BoxContainerConstraints.exactBox(size: const ui.Size(0.0, 0.0));

}
