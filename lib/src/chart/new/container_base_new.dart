import 'dart:ui' as ui show Size, Offset, Canvas;
// import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;
import 'dart:math' as math show max;

import '../../util/util_dart.dart' as util_dart show LineSegment;
import '../../morphic/rendering/constraints.dart' show LayoutExpansion;


/// todo-01-doc
/// Layout is a base class
/// does NOT store size or shape, only returns Shape from layout
/// abstract method Shape layout(covariant Constraints) specializations call 
/// this and implement this, probably calling super.
/// This maybe eventually configures some constraints caching and debugging.
abstract class Layout {
  Shape layout({required covariant ContainerConstraints constraints});
}

mixin Painter {
  void paint(ui.Canvas canvas);
}

abstract class ContainerNew extends Layout with Painter {
  ContainerNew? parent;
  List<ContainerNew>? children;
}


/// Work this into a bridge Container between Container and ContainerNew (Morph)
abstract class ContainerBridgeToNew {
  /// Manages the layout size during the layout process in [layout].
  /// Should be only mentioned in this class, not super
  ui.Size layoutSize = ui.Size.zero;
  
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

  /// [skipByParent] instructs the parent containerNew that this containerNew should not be
  /// painted or layed out - as if it collapsed to zero size.
  ///
  /// Note that concrete implementations must add
  /// appropriate support for collapse to work.
  bool skipByParent = false;

  /// If size constraints imposed by parent are too tight,
  /// some internal calculations of sizes may lead to negative values,
  /// making painting of this containerNew not possible.
  ///
  /// Setting the [enableSkipOnDistressedSize] `true` helps to solve such situation.
  /// It causes the containerNew not be painted
  /// (skipped during layout) when space is constrained too much
  /// (not enough space to reasonably paint the containerNew contents).
  /// Note that setting this to `true` may result
  /// in surprizing behavior, instead of exceptions.
  ///
  /// Note that concrete implementations must add
  /// appropriate support for collapse to work.
  ///
  /// Unlike [skipByParent], which directs the parent to ignore this containerNew,
  /// [enableSkipOnDistressedSize] is intended to be checked in code
  /// for some invalid conditions, and if they are reached, bypass painting
  /// the containerNew.
  bool enableSkipOnDistressedSize = true; // todo-10 set to true for distress test

  bool isDistressed = false;
  
  ContainerBridgeToNew();

  // ##### Abstract methods to implement

  // todo-01-morph : This should pass Constraints - see [RenderObject]
  void layout(LayoutExpansion parentLayoutExpansion);

  void paint(ui.Canvas canvas);

  /* END of ContainerBridgeToNew: KEEP
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
}

/// Expresses mutually exclusive layouts for a list of lengths (imagined as ordered line segments) on a line.
/// 
/// The supported packing methods
/// - Matrjoska packing places each smaller segment fully into the next larger  one (next means next by size). 
///   Order does not matter.
/// - Snap packing places each next segment's begin point just right of it's predecessor's end point.
/// - Loose packing is like snap packing, but, in addition, there can be a space between neighbour segments.
/// 
/// The only layout not described (and not allowed) is a partial overlap of any two lengths.
enum Packing { matrjoska, snap, loose }
enum Align { min, center, max }

class LengthsLayouter {
  LengthsLayouter({
    required this.lengths,
    required this.packing,
    required this.align,
    this.totalLength,
  }) {
    switch (packing) {
      case Packing.matrjoska:
        totalLength ??= _maxLength;
        assert(totalLength! >= _maxLength);
        _freeLength = totalLength! - _maxLength;
        break;
      case Packing.snap:
      case Packing.loose:
        totalLength ??= _sumLengths;
        assert(totalLength! >= _sumLengths);
        break;
    }
  }

  final List<double> lengths;
  final Packing packing;
  final Align align;
  late double? totalLength;
  late final double _freeLength;

  LayedOutLineSegments layout() {
    LayedOutLineSegments layedOutLineSegments;
    switch (packing) {
      case Packing.matrjoska:
        layedOutLineSegments = LayedOutLineSegments(
            lineSegments: lengths.map((length) => _matrjoskaLayoutLineSegmentFor(length)).toList(growable: false));
        break;
      case Packing.snap:
        layedOutLineSegments = LayedOutLineSegments(
            lineSegments: _snapOrLooseLayoutAndMapLengthsToSegments(_snapLayoutLineSegmentFor));
        break;
      case Packing.loose:
      // todo-00-last
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
    // todo-00-last : let the case always set start/end, and repeat code rather than be smart.
    double start, end;
    switch (align) {
      case Align.min:
        start = 0.0;
        end = length;
        break;
      case Align.center:
        double freeLengthLeft = _freeLength / 2;
        double matrjoskaInnerRoomLeft = (_maxLength - length) / 2;
        start = freeLengthLeft + matrjoskaInnerRoomLeft;
        end = freeLengthLeft + matrjoskaInnerRoomLeft + length;
        break;
      case Align.max:
        start = _freeLength + _maxLength - length;
        end = _freeLength + _maxLength;
        break;
    }

    return util_dart.LineSegment(start, end);
  }

  List<util_dart.LineSegment> _snapOrLooseLayoutAndMapLengthsToSegments(util_dart.LineSegment Function(util_dart.LineSegment?, double ) fromPreviousLengthLayoutThis ) {
    List<util_dart.LineSegment> lineSegments = [];
    for (int i = 0; i < lengths.length; i++) {
      util_dart.LineSegment? previousSegment;
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

  util_dart.LineSegment _snapOrLooseLayoutLineSegmentFor(double Function(int, bool) getStartOffset, util_dart.LineSegment? previousSegment, double length,) {
    bool isFirstLength = false;
    if (previousSegment == null) {
      isFirstLength = true;
      previousSegment = util_dart.LineSegment(0.0, 0.0);
    }
    int lengthsCount = lengths.length;

    double startOffset = getStartOffset( lengthsCount, isFirstLength);
    double start = startOffset + previousSegment.max;
    double end = startOffset + previousSegment.max + length;
    return util_dart.LineSegment(start, end);
  }
  
  double _snapStartOffset(int lengthsCount, bool isFirstLength) {
    double freeLengthLeft, startOffset;
    switch (align) {
      case Align.min:
        freeLengthLeft = 0.0;
        startOffset = freeLengthLeft;
        break;
      case Align.center:
        freeLengthLeft = _freeLength / 2; // for center, half freeLength to the left
        startOffset = isFirstLength ? freeLengthLeft : 0.0;
        break;
      case Align.max:
        freeLengthLeft = _freeLength; // for max, all freeLength to the left
        startOffset = isFirstLength ? freeLengthLeft : 0.0;
        break;
    }
    return startOffset;
  }

  double _looseStartOffset(int lengthsCount, bool isFirstLength) {
    double freeLengthLeft, startOffset;
    switch (align) {
      case Align.min:
        freeLengthLeft = _freeLength / lengthsCount;
        startOffset = isFirstLength ? freeLengthLeft : 0.0;
        break;
      case Align.center:
        freeLengthLeft = _freeLength / (lengthsCount + 1);
        startOffset = freeLengthLeft;
        break;
      case Align.max:
        freeLengthLeft = _freeLength / lengthsCount;
        startOffset = freeLengthLeft;
        break;
    }
    return startOffset;
  }
  
  /*
  /// Alignment applies to alignment of all segments snapped. There is is no inner alignment as is matrjoska. 
  util_dart.LineSegment _snapLayoutLineSegmentFor(util_dart.LineSegment? previousSegment, double length) {
    bool isFirstLength = false;
    if (previousSegment == null) {
      isFirstLength = true;
      previousSegment = util_dart.LineSegment(0.0, 0.0);
    }
    int lengthsCount = lengths.length;
    
    double startOffset = _snapStartOffset(lengthsCount, isFirstLength);
    double start = startOffset + previousSegment.max;
    double end = startOffset + previousSegment.max + length;

    return util_dart.LineSegment(start, end);
  }

  /// Alignment applies to alignment of all segments loose. There is is no inner alignment as is matrjoska. 
  util_dart.LineSegment _looseLayoutLineSegmentFor(util_dart.LineSegment? previousSegment, double length) {
    bool isFirstLength = false;
    if (previousSegment == null) {
      isFirstLength = true;
      previousSegment = util_dart.LineSegment(0.0, 0.0);
    }
    int lengthsCount = lengths.length;

    double startOffset = _looseStartOffset( lengthsCount, isFirstLength);
    double start = startOffset + previousSegment.max;
    double end = startOffset + previousSegment.max + length;
    return util_dart.LineSegment(start, end);
  }
  
   */
}

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
    
    // now Dart knows other is LayedOutLineSegments, but for clarity:
    LayedOutLineSegments otherSegment = other;
    if (lineSegments.length != other.lineSegments.length) {
      return false;
    }
    for (int i = 0; i < lineSegments.length; i++) {
      if (lineSegments[i] != other.lineSegments[i]) {
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

/////////////////////////////////////////////// 
// Future: 
//   - Shape and extensions
//   - Layout
//   - Painter
//   - ContainerNew and extensions

/// Shape is the set of points in a Container.
/// 
/// Returned from [layout].
class Shape {
  Object? get surface => null; // todo-00 make abstract
}

class BoxShape extends Shape {
  @override
  ui.Size get surface => ui.Size.zero;
}

//  todo-03 add distance and angle
class Pie {
}

class PieShape
{
Pie? get surface => null; // todo-03 implement
}

class ContainerConstraints {
  // todo-00-implement. Migrate LayoutExpansion to this
}
class BoxContainerConstraints extends ContainerConstraints {
  // todo-00-implement. Migrate LayoutExpansion to this
}
class PieContainerConstraints extends ContainerConstraints {
  // todo-00-implement. Migrate LayoutExpansion to this
}
abstract class BoxContainer extends ContainerNew {

@override  
BoxShape layout({required covariant BoxContainerConstraints constraints}) {
  // todo-00 implement by calling children.layout - implement flow layout by default
  return BoxShape();
}

}
