import 'dart:ui' as ui show Size, Offset, Canvas;
// import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;
import 'dart:math' as math show max, Rectangle;

import '../../util/util_dart.dart' as util_dart show LineSegment;
import '../../morphic/rendering/constraints.dart' show BoxContainerConstraints;

// todo-01: Container core rule: I do not expose position, offset, or layoutSize.

//               I stay put until someone calls transform on me, OR it's special case applyParentOffset.
//               Is that possible?

/// - [ ] ContainerBridgeToNew: add parent and children as described in ContainerNew
/// - [ ] create BoxLayouter (extends nothing, extend Layouter is for later), with old methods
/// - [ ] create Painter, extends nothing, with old methods
/// - [ ] ContainerBridgeToNew split to BoxLayouter and Painter, both with old methods
/// - [ ] Work to finish AxisDirectionBoxLayouter extends BoxLayouter, uses LengthsLayouter to modify Container.children.layoutSize and Container.children.offset

/// Work this into a bridge Container between Container and ContainerNew (Morph). Let Container extend from this
abstract class BoxContainerNew {

  /// Default generative constructor
  BoxContainerNew() : _parentSandbox = BoxContainerParentSandbox();

  // Fields managed by Container

  /// Manages the layout size during the layout process in [layout].
  /// Should be only mentioned in this class, not super
  ui.Size layoutSize = ui.Size.zero;

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

  // Fields managed by Sandbox
  
  final BoxContainerParentSandbox _parentSandbox;

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
  ui.Offset get offset => _parentSandbox.offset;

  /// Allow a parent containerNew to move this ContainerNew
  /// after [layout].
  ///
  /// Override if parent move needs to propagate to internals of
  /// this [ContainerNew].
  void applyParentOffset(ui.Offset offset) => _parentSandbox.offset += offset;
  
  set parentOrderedToSkip(bool skip) => _parentSandbox.parentOrderedToSkip = skip;
  bool get parentOrderedToSkip => _parentSandbox.parentOrderedToSkip;

  bool get isDistressed => _parentSandbox.isDistressed;
  set isDistressed(bool distressed) => _parentSandbox.isDistressed = distressed;
  
  // ##### Abstract methods to implement

  void layout(BoxContainerConstraints boxConstraints);
  
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

// todo-00-last : BoxContainerParentSandbox

// todo-00-document
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

  bool isDistressed = false;
  
}

// todo-01-done : LengthsLayouter -------------------------------------------------------------------------------------

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

/// todo-00-document
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
        _freePadding = totalLength! - _maxLength;
        break;
      case Packing.snap:
      case Packing.loose:
        totalLength ??= _sumLengths;
        assert(totalLength! >= _sumLengths);
        _freePadding = totalLength! - _sumLengths;
        break;
    }
  }

  final List<double> lengths;
  final Packing packing;
  final Align align;
  late double? totalLength;
  late final double _freePadding;

  LayedOutLineSegments layoutLengths() {
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
    switch (align) {
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
    switch (align) {
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
    switch (align) {
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
    
    // now Dart knows other is LayedOutLineSegments, but for clarity:
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

// todo-00 : AxisDirectionBoxLayouter, base class for Column and Row layouter


/// - members 

// todo-01 : Shape and extensions (Box, Pie), Container and extensions, Layout, Painter -------------------------------

/// Shape is the set of points in a Container.
/// 
/// Returned from [layout].
/// todo-01
class Shape {
  Object? get surface => null; // represents non positioned surface after getting size in layout
  Object? get positionedSurface => null;  // represents surface after positioning during layout
}

class BoxShape extends Shape {
  @override
  ui.Size get surface => ui.Size.zero;
  @override
  math.Rectangle get positionedSurface => const math.Rectangle(0.0, 0.0, 0.0, 0.0);
}

/// Represents non-positioned pie shape. Internal coordinates are polar, but can ask for containing rectangle.
/// Equivalent to Size in Box shapes (internally in cartesian coordinates)
class Pie {
  // todo-03 add distance and angle, and implement
  double angle = 0.0; // radians
  double radius = 0.0; // pixels ?
}

/// Represents a positioned pie shape. Positioning is in Cartesian coordinates represented by Offset.
/// Equivalent to Rectangle in Box shapes.
class PositionedPie extends Pie {
  ui.Offset offset = const ui.Offset(0.0, 0.0);
}

// todo-03 implement
class PieShape extends Shape {
  @override
  Pie get surface => Pie();
  @override
  PositionedPie get positionedSurface => PositionedPie();
}

// todo-01 : Constraints and extensions -------------------------------------------------------------------------------

class ContainerConstraints {
}
class PieContainerConstraints extends ContainerConstraints {
}

// BoxContainerConstraints - see constraints.dart