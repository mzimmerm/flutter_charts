import 'dart:math' as math show max;
import 'dart:ui' as ui show Size, Offset;

import 'package:flutter/material.dart';
import 'package:flutter_charts/src/util/util_dart.dart' as util_dart show LineSegment;

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

abstract class LayoutableBox {
 ui.Size get size;
 ui.Offset get offset;
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
class BoxLayouter {
  
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

  // todo-00-last Same members as in BoxContainer. Later, move or delegate them from BoxContainer here
  List<LayoutableBox> layoutableBoxes = [];
  LayoutAxis mainLayoutAxis = LayoutAxis.none;
  LayoutAxis crossLayoutAxis = LayoutAxis.none;
  bool get isLayout => mainLayoutAxis != LayoutAxis.none || crossLayoutAxis != LayoutAxis.none;
  
  BoxLayoutProperties mainAxisBoxLayoutProperties;
  BoxLayoutProperties crossAxisBoxLayoutProperties;

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
      layoutableBoxes.map((layoutableBox) => _lengthAlongLayoutAxis(layoutAxis, layoutableBox.size)).toList();
  
}
// todo-00-last : BoxLayouter, base class for ColumnLayouter and RowLayouter
//                BoxLayouter extends BoxContainer, uses LengthsLayouter to modify Container.children.layoutSize and Container.children.offset

