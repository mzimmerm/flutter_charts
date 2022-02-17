import 'dart:ui' as ui show Size, Offset, Canvas;
import 'dart:math' as math show max;
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

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
  BoxContainer() {
    parentSandbox = BoxLayouterParentSandbox();
    layoutSandbox = BoxLayouterLayoutSandbox();
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
  BoxLayoutProperties boxLayoutProperties;
  late final double _freePadding;
  double totalLayedOutLength = 0.0; // can change multiple times, set after each child length in lengths

  LayedOutLineSegments layoutLengths() {
    LayedOutLineSegments layedOutLineSegments;
    switch (boxLayoutProperties.packing) {
      case Packing.matrjoska:
        layedOutLineSegments = LayedOutLineSegments(
          lineSegments: lengths.map((length) => _matrjoskaLayoutLineSegmentFor(length)).toList(growable: false),
          totalLayedOutLength: totalLayedOutLength,
        );
        break;
      case Packing.snap:
        layedOutLineSegments = LayedOutLineSegments(
          lineSegments: _snapOrLooseLayoutAndMapLengthsToSegments(_snapLayoutLineSegmentFor),
          totalLayedOutLength: totalLayedOutLength,
        );
        break;
      case Packing.loose:
        layedOutLineSegments = LayedOutLineSegments(
          lineSegments: _snapOrLooseLayoutAndMapLengthsToSegments(_looseLayoutLineSegmentFor),
          totalLayedOutLength: totalLayedOutLength,
        );
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
    double start, end, freePadding;
    switch (boxLayoutProperties.align) {
      case Align.min:
        freePadding = _freePadding;
        start = 0.0;
        end = length;
        break;
      case Align.center:
        freePadding = _freePadding / 2;
        double matrjoskaInnerRoomLeft = (_maxLength - length) / 2;
        start = freePadding + matrjoskaInnerRoomLeft;
        end = freePadding + matrjoskaInnerRoomLeft + length;
        break;
      case Align.max:
        freePadding = _freePadding;
        start = freePadding + _maxLength - length;
        end = freePadding + _maxLength;
        break;
    }
    totalLayedOutLength = _maxLength + _freePadding;

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

  util_dart.LineSegment _snapOrLooseLayoutLineSegmentFor(
      Tuple2<double, double> Function(bool) getStartOffset,
      util_dart.LineSegment? previousSegment,
      double length,
      ) {
    bool isFirstLength = false;
    if (previousSegment == null) {
      isFirstLength = true;
      previousSegment = util_dart.LineSegment(0.0, 0.0);
    }
    Tuple2<double, double> startOffsetAndRightPad = getStartOffset(isFirstLength);
    double startOffset = startOffsetAndRightPad.item1;
    double rightPad = startOffsetAndRightPad.item2;
    double start = startOffset + previousSegment.max;
    double end = startOffset + previousSegment.max + length;
    totalLayedOutLength = end + rightPad;
    return util_dart.LineSegment(start, end);
  }

  /// 
  /// [length] needed to set [totalLayedOutLength] every time this is called for each child. Value of last child sticks.
  Tuple2<double, double> _snapStartOffset(bool isFirstLength) {
    double freePadding, startOffset, freePaddingRight;
    switch (boxLayoutProperties.align) {
      case Align.min:
        freePadding = 0.0;
        freePaddingRight = _freePadding;
        startOffset = freePadding;
        break;
      case Align.center:
        freePadding = _freePadding / 2; // for center, half freeLength to the left
        freePaddingRight = freePadding;
        startOffset = isFirstLength ? freePadding : 0.0;
        break;
      case Align.max:
        freePadding = _freePadding; // for max, all freeLength to the left
        freePaddingRight = 0.0;
        startOffset = isFirstLength ? freePadding : 0.0;
        break;
    }
    return Tuple2(startOffset, freePaddingRight);
  }

  /// 
  /// [length] needed to set [totalLayedOutLength] every time this is called for each child. Value of last child sticks.
  Tuple2<double, double> _looseStartOffset(bool isFirstLength) {
    int lengthsCount = lengths.length;
    double freePadding, startOffset, freePaddingRight;
    switch (boxLayoutProperties.align) {
      case Align.min:
        freePadding = lengthsCount != 0 ? _freePadding / lengthsCount : _freePadding;
        freePaddingRight = freePadding;
        startOffset = isFirstLength ? 0.0 : freePadding;
        break;
      case Align.center:
        freePadding = lengthsCount != 0 ? _freePadding / (lengthsCount + 1) : _freePadding;
        freePaddingRight = freePadding;
        startOffset = freePadding;
        break;
      case Align.max:
        freePadding = lengthsCount !=0 ? _freePadding / lengthsCount : _freePadding;
        freePaddingRight = 0.0;
        startOffset = freePadding;
        break;
    }
    return Tuple2(startOffset, freePaddingRight);
  }

}

/// todo-00-document
class LayedOutLineSegments {
  LayedOutLineSegments({required this.lineSegments, required this.totalLayedOutLength});

  final List<util_dart.LineSegment> lineSegments;
  final double totalLayedOutLength;

  /// Calculates length of all layed out [lineSegments].
  /// 
  /// Because the [lineSegments] are created 
  /// in [LayedOutLineSegments.layoutLengths] and start at offset 0.0 first to last,
  /// the total length is between 0.0 and the end of the last [util_dart.LineSegment] element in [lineSegments].
  /// As the [lineSegments] are all in 0.0 based coordinates, the last element end is the length of all [lineSegments].
  /// 
  double get totalLength => lineSegments.isNotEmpty ? lineSegments.last.max : 0.0;

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

// todo-00-last : Get rid of this or improve.
abstract class LayoutableBox {
  ui.Size layoutSize = Size.zero;
  void applyParentOffset(ui.Offset offset);
  BoxLayouterLayoutSandbox layoutSandbox = BoxLayouterLayoutSandbox();
  void newCoreLayout();
}

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
/// by the side effects of the method [offsetChildrenAccordingToLayouter]. 
mixin BoxLayouter on BoxContainerHierarchy implements LayoutableBox {

  /// Manages the layout size during the layout process in [layout].
  /// Should be only mentioned in this class, not super
  @override
  ui.Size layoutSize = ui.Size.zero;

/* todo-00-last-last move to BoxContainer extensions constructor, especially the asserts
  BoxLayouter({
    required this.layoutableBoxes,
    required this.mainLayoutAxis,
    required this.mainAxisBoxLayoutProperties,
    required this.crossAxisBoxLayoutProperties,
  }) {
    assert(mainLayoutAxis != LayoutAxis.none);
  }
*/

  // List<LayoutableBox> layoutableBoxes = []; // todo-00-last-last : these are children!!
  List<LayoutableBox> get layoutableBoxes => children;
  LayoutAxis mainLayoutAxis = LayoutAxis.none; // todo-00 : consider default to horizontal (Row layout)
  bool get isLayout => mainLayoutAxis != LayoutAxis.none;

  BoxLayoutProperties mainAxisBoxLayoutProperties = BoxLayoutProperties(packing: Packing.snap, align: Align.min);
  BoxLayoutProperties crossAxisBoxLayoutProperties = BoxLayoutProperties(packing: Packing.snap, align: Align.min);

  /// Member used during the [layout] processing.
  @override
  BoxLayouterLayoutSandbox layoutSandbox = BoxLayouterLayoutSandbox(); // todo-00-last : MAKE NOT NULLABLE 

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

  /// Lays out all elements in [layoutableBoxes], by setting offset on each [LayoutableBox] element.
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

    // Convert the line segments to Offsets (in each axis)
    List<ui.Offset> layedOutOffsets = _convertLayedOutSegmentsToOffsets(
      mainLayoutAxis,
      mainAndCrossLayedOutSegments,
      notGreedyChildren,
    );

    // Apply the offsets obtained by layouting onto the layoutableBoxes
    _offsetChildren(layedOutOffsets, notGreedyChildren);
  }

  _MainAndCrossLayedOutSegments _findLayedOutSegmentsForChildren(List<LayoutableBox> notGreedyChildren) {
    // Create a LengthsLayouter along each axis (main, cross).
    LengthsLayouter mainAxisLengthsLayouter = _lengthsLayouterAlong(mainLayoutAxis, mainAxisBoxLayoutProperties, notGreedyChildren);
    LengthsLayouter crossAxisLengthsLayouter = _lengthsLayouterAlong(axisPerpendicularTo(mainLayoutAxis), crossAxisBoxLayoutProperties, notGreedyChildren);

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

  void _offsetChildren(List<ui.Offset> layedOutOffsets, List<LayoutableBox> notGreedyChildren) {
    // Apply the offsets obtained by layouting onto the layoutableBoxes
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
  LengthsLayouter _lengthsLayouterAlong(LayoutAxis layoutAxis, BoxLayoutProperties axisLayoutProperties,
      List<LayoutableBox> notGreedyChildren,) {
    List<double> lengthsAlongLayoutAxis = _lengthsOfChildrenAlong(layoutAxis, notGreedyChildren);
    LengthsLayouter lengthsLayouterAlongLayoutAxis = LengthsLayouter(
      lengths: lengthsAlongLayoutAxis,
      boxLayoutProperties: axisLayoutProperties,
    );
    return lengthsLayouterAlongLayoutAxis;
  }

  /// Creates and returns a list of lengths of the [layoutableBoxes]
  /// measured along the passed [layoutAxis].
  List<double> _lengthsOfChildrenAlong(LayoutAxis layoutAxis, List<LayoutableBox> notGreedyChildren) =>
      notGreedyChildren.map((layoutableBox) => _lengthAlong(layoutAxis, layoutableBox.layoutSize)).toList();

  // ------------ Fields managed by Sandbox and methods delegated to Sandbox.

  // todo-00-last : consider merging layoutSandbox and parentSandbox
  BoxLayouterParentSandbox? parentSandbox; // todo-00-last make NON NULL

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

class _MainAndCrossLayedOutSegments {
  _MainAndCrossLayedOutSegments({
    required this.mainAxisLayedOutSegments,
    required this.crossAxisLayedOutSegments,
  });
  LayedOutLineSegments mainAxisLayedOutSegments;
  LayedOutLineSegments crossAxisLayedOutSegments;

}

// todo-00-last : BoxLayouter, base class for ColumnLayouter and RowLayouter
//                BoxLayouter extends BoxContainer, uses LengthsLayouter to modify Container.children.layoutSize and Container.children.offset

// todo-00-done BoxContainerLayoutSandbox - a new class -----------------------------------------------------------------

// todo-01-last : try to make non-nullable and final
class BoxLayouterLayoutSandbox {
  List<BoxLayouter> childrenInLayoutOrderGreedyLast = [];
  ui.Size addedSizeOfAllChildren = const ui.Size(0.0, 0.0);
  BoxContainerConstraints? constraints;

}

// todo-00-document
/// Only parent containers of the container that owns this object should be allowed to 
/// get or set any field inside this object.
class BoxLayouterParentSandbox {

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



