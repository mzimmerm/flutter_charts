import 'dart:math' as math show max;
import 'package:flutter_charts/src/chart/container_layouter_base.dart' show BoxLayouter;
import 'package:tuple/tuple.dart';
import 'dart:ui' as ui;

import 'package:flutter_charts/src/util/util_dart.dart' as util_dart show LineSegment;

/// [Packing] describes mutually exclusive layouts for a list of lengths
/// (imagined as ordered line segments) on a line.
///
/// The supported packing methods
/// - Matrjoska packing places each smaller segment fully into the next larger one (next means next by size).
///   Order does not matter.
/// - Tight packing places each next segment's begin point just right of it's predecessor's end point.
/// - Loose packing is like tight packing, but, in addition, there can be a space between neighbour segments.
///
/// The only layout not described (and not allowed) is a partial overlap of any two lengths.
enum Packing {
  /// [Packing.matrjoska] should layout elements so that the smallest element is fully
  /// inside the next larger element, and so on. The largest element contains all smaller elements.
  ///
  /// This packing is used on cross-axis for Column and Row layouters (Column is packed as matrjoska
  /// along horizontal axis, Row is packed as matrjoska along vertical axis)
  matrjoska,

  /// [Packing.tight] should layout elements in a way they tight together into a group with no padding between elements.
  ///
  /// If the available [LayedoutLengthsPositioner._freePadding] is zero,
  /// the result is the same for any [Align] value.
  ///
  /// If the available [LayedoutLengthsPositioner._freePadding] is non zero:
  ///
  /// - For [Align.start] or [Align.end] : Also aligns the group to min or max boundary.
  ///   For [Align.start], there is no padding between min and first element of the group,
  ///   all the padding [LayedoutLengthsPositioner._freePadding] is after the end of the group;
  ///   similarly for [Align.end], for which the group end is aligned with the end,
  ///   and all the padding [LayedoutLengthsPositioner._freePadding] is before the group.
  /// - For [Align.center] : The elements are packed into a group and the group centered.
  ///   That means, when [LayedoutLengthsPositioner._freePadding] is available, half of the free length pads
  ///   the group on the boundaries
  ///
  tight,

  /// [Packing.loose] should layout elements so that they are separated with even amount of padding,
  /// if the available padding defined by [LayedoutLengthsPositioner._freePadding] is not zero.
  /// If the available padding is zero, layout is the same as [Packing.tight] with no padding.
  ///
  /// If the available [LayedoutLengthsPositioner._freePadding] is zero,
  /// the result is the same for any [Align] value,
  /// and also the same as the result of [Packing.tight] for any [Align] value:
  /// All elements are packed together.
  ///
  /// If the available [LayedoutLengthsPositioner._freePadding] is non zero:
  ///
  /// - For [Align.start] or [Align.end] : Aligns the first element start to the min,
  ///   or the last element end to the max, respectively.
  ///   For [Align.start], the available [LayedoutLengthsPositioner._freePadding] is distributed evenly
  ///   as padding between elements and at the end. First element start is at the boundary.
  ///   For [Align.end], the available [LayedoutLengthsPositioner._freePadding] is distributed evenly
  ///   as padding at the beginning, and between elements. Last element end is at the boundary.
  /// - For [Align.center] : Same proportions of [LayedoutLengthsPositioner._freePadding]
  ///   are distributed as padding at the beginning, between elements, and at the end.
  /// - todo-01 implement and test : For [Align.centerExpand] : Same proportions of [LayedoutLengthsPositioner._freePadding]
  ///   are distributed as padding between elements; no padding at the beginning or at the end.
  ///
  loose,
}

/// todo-01-document
/// This is alignment.
enum Align {
  start,
  center,
  // todo-01 : added but not tested or used. Originally intended for chart GridContainer layout.
  //           maybe replaced with RowWithUnevenChildrenConstraints
  centerExpand,
  end,
}

/// Defines layout direction.
///
/// By default, layouters layout both primary and cross axis in the direction of increasing coordinates,
/// left to right along the horizontal direction, and top to bottom along the vertical direction.
///
/// The value [coordinatesDirection]   should be used for default layouters direction (described above).
/// The value [reversed] should be used to direct layouters to layout in a direction reverse to coordinates.
enum LayoutDirection {
  coordinatesDirection,
  reversed,
}

/// todo-011 document
enum DivideConstraintsToChildren {
  evenly,
  intWeights,
  noDivide,
}

/// Properties of [BoxLayouter] describe [packing] and [align] of the layed out elements along
/// either a main axis or cross axis.
///
/// todo-011: document the added [layoutDirection], [isPositioningMainAxis]
/// This class is also used to describe packing and alignment of the layed out elements
/// for the 1-dimensional [LayedoutLengthsPositioner], where it serves to describe the 1-dimensional packing and alignment.
class LengthsPositionerProperties {

  // todo-00 add LayoutDirection member layoutDirection, see [RollingPositioningBoxLayouter],
  //           `  final LayoutDirection mainAxisLayoutDirection` document as 'layout direction along the axis this
  //              properties object describes. MUST be on main axis (todo- assert somehow?)
  // todo-done-last: Added layoutDirection, and isPositioningMainAxis
  final Align align;
  final Packing packing;
  /// The layout direction along the axis this properties object describes.
  /// MUST be on main axis (todo-011 assert somehow?)
  final LayoutDirection layoutDirection;  // todo-done-last : added
  final bool isPositioningMainAxis; // todo-done-last : added

  LengthsPositionerProperties({
    required this.align,
    required this.packing,
    required this.layoutDirection,
    required this.isPositioningMainAxis,
  });
}

/// A 1-dimensional layouter for segments represented only by [lengths] of the segments.
///
/// The [lengths] typically originate from [BoxLayouter.layoutSize]s of children of
/// a parent [BoxLayouter] which creates this object - hence the first 'Layout'
/// in the name [LayedoutLengthsPositioner].
///
/// The [lengthsPositionerProperties] specifies [Packing] and [Align] properties.
/// They control the layout result, along with [lengthsConstraint],
/// which is the constraint for the layed out segments.
///
/// The core algorithm in [layoutLengths] lays out the [lengths] according to the
/// properties specified in member [lengthsPositionerProperties], and creates list
/// of layed out segments from the [lengths]; the layed out segments may be padded
/// if there is length available towards the [lengthsConstraint].
///
/// Note: The total length of [lengths] depends on Packing - it is
///   - sum lengths for tight or loose
///   - max length for matrjoska
///
/// If the total length of [lengths] is below [lengthsConstraint],
/// and the combination of Packing and Align allows free spacing, the remaining
/// [lengthsConstraint] are used to add spaces between, around, or to the left of the
/// resulting segments.
///
/// See [layoutLengths] for more details of this class' objects behavior.
///
class LayedoutLengthsPositioner {
  LayedoutLengthsPositioner({
    required this.lengths,
    required this.lengthsPositionerProperties,
    required this.lengthsConstraint,
  }) {
    assert(lengthsConstraint != double.infinity);
    switch (lengthsPositionerProperties.packing) {
      case Packing.matrjoska:
        // Caller should allow for lengthsConstraint to be exceeded by _maxLength, set isOverflown, deal with it in caller
        isOverflown = (_maxLength > lengthsConstraint);
        _freePadding =  isOverflown ? 0.0 : lengthsConstraint - _maxLength;
        break;
      case Packing.tight:
      case Packing.loose:
        // Caller should allow for lengthsConstraint to be exceeded by _sumLengths, set isOverflown, deal with it in caller
        isOverflown = (_sumLengths > lengthsConstraint);
        _freePadding =  isOverflown ? 0.0 : lengthsConstraint - _sumLengths;
        break;
    }
  }

  // LayedoutLengthsPositioner members
  final List<double> lengths;
  final LengthsPositionerProperties lengthsPositionerProperties;
  late final double _freePadding;
  late final double lengthsConstraint;
  late final bool isOverflown; // calculated to true if lengthsConstraint < _maxLength or _sumLengths
  double totalPositionedLengthIncludesPadding = 0.0; // can change multiple times, set after each child length in lengths

  /// Lays out a list of imaginary sticks, with lengths in member [lengths], adhering to the layout properties
  /// defined in member [lengthsPositionerProperties].
  ///
  /// From the [lengths], it creates a list of layed out segments ; the layed out segments may be padded
  /// if there is length available towards the [lengthsConstraint].
  ///
  /// The input are members
  ///   - [lengths] which holds the lengths to lay out, and
  ///   - [lengthsPositionerProperties] which specifies the layout properties:
  ///     - [LengthsPositionerProperties.packing] and [LengthsPositionerProperties.align] that control the layout process
  ///       (where the imaginary sticks are positioned in the result).
  ///     - [lengthsConstraint] which is effectively the 1-dimensional constraint for the
  ///       min and max values of the layed out segments.
  ///
  /// The result of this method is a [LayedOutLineSegments] object. In this object, this method wraps
  ///   - The layed out imaginary sticks of [lengths], are placed in [LayedOutLineSegments.lineSegments]
  ///   - The total layed out length of the layed out [LayedOutLineSegments.lineSegments], INCLUDING PADDING,
  ///     is placed in [LayedOutLineSegments.totalLayedOutLengthIncludesPadding].
  ///
  /// The [LayedOutLineSegments.lineSegments] in the result have min and max, which are positioned by the algorithm
  /// along an interval starting at `0.0`, and generally ending at [lengthsConstraint].
  ///
  /// The algorithm keeps track of, and results in, the [totalLayedOutLengthIncludesPadding]
  /// which is effectively the layout size of all the layed out imaginary sticks [LayedOutLineSegments.lineSegments].
  ///
  /// Note: The total length of [lengths] depends on Packing - it is
  ///   - sum lengths for tight or loose
  ///   - max length for matrjoska
  ///
  /// If the total length of [lengths] is below [lengthsConstraint],
  /// and the combination of Packing and Align allows free spacing, the remaining
  /// [lengthsConstraint] are used to add spaces between, around, or to the left of the
  /// resulting segments.
  ///
  /// OVERFLOW NOTES: This algorithm allows (as a valid but suspect result) an 'overflow condition', in which
  ///
  ///    -  The last endpoint of [LayedOutLineSegments.lineSegments] > [lengthsConstraint],
  ///       see [isOverflown].
  ///    - In [isOverflown] condition, no padding is used. Also, several things are true
  ///      -
  ///      - [LayedOutLineSegments.totalLayedOutLengthIncludesPadding] = the sum or max of [lengths] depending on Packing.
  ///      - [LayedOutLineSegments.totalLayedOutLengthIncludesPadding] > [lengthsConstraint]
  ///
  ///
  /// Example:
  ///   - Laying out using the [Packing.tight] and [Align.start], in [LengthsPositionerProperties] :
  ///     - The first length in [lengths] creates the first [LineSegment] in [layedOutLineSegments]; this first [LineSegment] has
  ///       - min = 0.0
  ///       - max = first length
  ///   - The second length in [lengths] creates the second [LineSegment] in [layedOutLineSegments]; this second [LineSegment] has
  ///     - min = first length (tightped to the end of the first segment)
  ///     - max = first length + second length.
  ///
  ///
  ///
  PositionedLineSegments layoutLengths() {
    PositionedLineSegments positionedLineSegments;
    switch (lengthsPositionerProperties.packing) {
      case Packing.matrjoska:
        positionedLineSegments = PositionedLineSegments(
          lineSegments: lengths.map((length) => _matrjoskaLayoutLineSegmentFor(length)).toList(growable: false),
          totalPositionedLengthIncludesPadding: totalPositionedLengthIncludesPadding,
          isOverflown: isOverflown,
        );
        break;
      case Packing.tight:
        positionedLineSegments = PositionedLineSegments(
          lineSegments: _tightOrLooseLayoutAndMapLengthsToSegments(_tightLayoutLineSegmentFor),
          totalPositionedLengthIncludesPadding: totalPositionedLengthIncludesPadding,
          isOverflown: isOverflown,
        );
        break;
      case Packing.loose:
        positionedLineSegments = PositionedLineSegments(
          lineSegments: _tightOrLooseLayoutAndMapLengthsToSegments(_looseLayoutLineSegmentFor),
          totalPositionedLengthIncludesPadding: totalPositionedLengthIncludesPadding,
          isOverflown: isOverflown,
        );
        break;
    }
    // todo-00 ONLY if [LayedoutLengthsPositioner] positions along the main axis, AND is set to reverse,
    //              then reverse before return, as this [LayedoutLengthsPositioner] instance knows
    //    - a) total length, in it's member [totalPositionedLengthIncludesPadding]
    //    - b) individual segments layed out positions in positionedLineSegments returned here
    //    - c) LayoutDirection via it's member [lengthsPositionerProperties]
    if (lengthsPositionerProperties.isPositioningMainAxis &&
        lengthsPositionerProperties.layoutDirection == LayoutDirection.reversed
    ) {
      positionedLineSegments = positionedLineSegments.reversedCopy();
    }

    return positionedLineSegments;
  }

  double get _sumLengths => lengths.fold(0.0, (previousLength, length) => previousLength + length);

  double get _maxLength => lengths.fold(0.0, (previousValue, length) => math.max(previousValue, length));

  /// Intended for use in  [Packing.matrjoska], creates and returns a [util_dart.LineSegment] for the passed [length],
  /// positioning the [util_dart.LineSegment] according to [align].
  ///
  /// [Packing.matrjoska] ignores order of lengths, so there is no dependence on length predecessor.
  ///
  /// Also, for [Packing.matrjoska], the [align] applies *both* for alignment of lines inside the Matrjoska,
  /// as well as the whole largest Matrjoska alignment inside the available [totalLayedOutLengthIncludesPadding].
  util_dart.LineSegment _matrjoskaLayoutLineSegmentFor(double length) {
    double start, end, freePadding;
    switch (lengthsPositionerProperties.align) {
      case Align.start:
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
      case Align.centerExpand:
        freePadding = 0.0; // for centerExpand, no free padding
        double matrjoskaInnerRoomLeft = (_maxLength - length) / 2;
        start = freePadding + matrjoskaInnerRoomLeft;
        end = freePadding + matrjoskaInnerRoomLeft + length;
        break;
      case Align.end:
        freePadding = _freePadding;
        start = freePadding + _maxLength - length;
        end = freePadding + _maxLength;
        break;
    }
    totalPositionedLengthIncludesPadding = _maxLength + _freePadding;

    return util_dart.LineSegment(start, end);
  }

  List<util_dart.LineSegment> _tightOrLooseLayoutAndMapLengthsToSegments(
    util_dart.LineSegment Function(util_dart.LineSegment?, double) fromPreviousLengthLayoutThis,
  ) {
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

  util_dart.LineSegment _tightLayoutLineSegmentFor(
    util_dart.LineSegment? previousSegment,
    double length,
  ) {
    return _tightOrLooseLayoutLineSegmentFor(_tightStartOffset, previousSegment, length);
  }

  util_dart.LineSegment _looseLayoutLineSegmentFor(
    util_dart.LineSegment? previousSegment,
    double length,
  ) {
    return _tightOrLooseLayoutLineSegmentFor(_looseStartOffset, previousSegment, length);
  }

  util_dart.LineSegment _tightOrLooseLayoutLineSegmentFor(
    Tuple2<double, double> Function(bool) getStartOffset,
    util_dart.LineSegment? previousSegment,
    double length,
  ) {
    bool isFirstLength = false;
    if (previousSegment == null) {
      isFirstLength = true;
      previousSegment = const util_dart.LineSegment(0.0, 0.0);
    }
    Tuple2<double, double> startOffsetAndRightPad = getStartOffset(isFirstLength);
    double startOffset = startOffsetAndRightPad.item1;
    double rightPad = startOffsetAndRightPad.item2;
    double start = startOffset + previousSegment.max;
    double end = startOffset + previousSegment.max + length;
    totalPositionedLengthIncludesPadding = end + rightPad;
    return util_dart.LineSegment(start, end);
  }

  ///
  /// [length] needed to set [totalLayedOutLengthIncludesPadding] every time this is called for each child. Value of last child sticks.
  Tuple2<double, double> _tightStartOffset(bool isFirstLength) {
    double freePadding, startOffset, freePaddingRight;
    switch (lengthsPositionerProperties.align) {
      case Align.start:
        freePadding = 0.0;
        freePaddingRight = _freePadding;
        startOffset = freePadding;
        break;
      case Align.center:
        freePadding = _freePadding / 2; // for center, half freeLength to the left
        freePaddingRight = freePadding;
        startOffset = isFirstLength ? freePadding : 0.0;
        break;
      case Align.centerExpand:
        freePadding = 0.0; // for centerExpand, no freeLength to the left
        freePaddingRight = 0.0; // for centerExpand, no freeLength to the right
        startOffset = isFirstLength ? freePadding : 0.0;
        break;
      case Align.end:
        freePadding = _freePadding; // for max, all freeLength to the left
        freePaddingRight = 0.0;
        startOffset = isFirstLength ? freePadding : 0.0;
        break;
    }
    return Tuple2(startOffset, freePaddingRight);
  }

  ///
  /// [length] needed to set [totalLayedOutLengthIncludesPadding] every time this is called for each child. Value of last child sticks.
  Tuple2<double, double> _looseStartOffset(bool isFirstLength) {
    int lengthsCount = lengths.length;
    double freePadding, startOffset, freePaddingRight;
    switch (lengthsPositionerProperties.align) {
      case Align.start:
        freePadding = lengthsCount != 0 ? _freePadding / lengthsCount : _freePadding;
        freePaddingRight = freePadding;
        startOffset = isFirstLength ? 0.0 : freePadding;
        break;
      case Align.center:
        freePadding = lengthsCount != 0 ? _freePadding / (lengthsCount + 1) : _freePadding;
        freePaddingRight = freePadding;
        startOffset = freePadding;
        break;
      case Align.centerExpand:
        freePadding = lengthsCount > 1 ? _freePadding / (lengthsCount - 1) : _freePadding; // for count = 0, 1
        freePaddingRight = 0.0;
        startOffset = 0.0;
        break;
      case Align.end:
        freePadding = lengthsCount != 0 ? _freePadding / lengthsCount : _freePadding;
        freePaddingRight = 0.0;
        startOffset = freePadding;
        break;
    }
    return Tuple2(startOffset, freePaddingRight);
  }
}

/// Holds a list of 1-dimensional [LineSegment]s layed out generally by [LayedoutLengthsPositioner] from a list of lengths.
///
/// Each line segment in [lineSegments] has a min and max (start and end), where
/// the [LayedoutLengthsPositioner] positioned them, the min and max values are
/// starting at 0.0 and ending at the [LayedoutLengthsPositioner.lengthsConstraint].
///
/// The [isOverflown] is only a marker that the process that lead to layout overflew it's constraints.
///
/// The clients of this object usually use it to convert the member [lineSegments]
/// to one side of a rectangle along the axis corresponding to children (future) positions.
///
/// Note: on creation, it should be passed segments [lineSegments] already
///       layed out to their positions with [LayedoutLengthsPositioner]
///       and [totalLayedOutLengthIncludesPadding] calculated by [LayedoutLengthsPositioner.totalLayedOutLengthIncludesPadding].
class PositionedLineSegments {
  const PositionedLineSegments({
    required this.lineSegments,
    required this.totalPositionedLengthIncludesPadding,
    required this.isOverflown,
  });

  PositionedLineSegments reversedCopy() {
    return PositionedLineSegments(
      lineSegments: _reverseLineSegments(),
      totalPositionedLengthIncludesPadding: totalPositionedLengthIncludesPadding,
      isOverflown: isOverflown,
    );
  }

  final List<util_dart.LineSegment> lineSegments;
  /// Total length after layout that includes padding.
  ///
  /// If there is padding, this may be BEYOND max on last lineSegments
  final double totalPositionedLengthIncludesPadding;
  /// A marker that the process that lead to layout overflew it's original constraints given in
  /// [LayedoutLengthsPositioner.lengthsConstraint].
  ///
  /// If can be used by clients to deal with overflow by a warning or painting a yellow rectangle.
  final bool isOverflown;

  /// Envelope of the layed out [lineSegments].
  ///
  /// This will become the [BoxLayouter.layoutSize] along the layout axis.
  ui.Size get envelope => ui.Size(0.0, totalPositionedLengthIncludesPadding);

  /* todo-00 what is this?
  /// Calculates length of all layed out [lineSegments].
  ///
  /// Because the [lineSegments] are created
  /// in [LayedOutLineSegments.layoutLengths] and start at offset 0.0 first to last,
  /// the total length is between 0.0 and the end of the last [util_dart.LineSegment] element in [lineSegments].
  /// As the [lineSegments] are all in 0.0 based coordinates, the last element end is the length of all [lineSegments].
  */

  // todo-done-last document Reverse line segments (layout from end rather than start
  List<util_dart.LineSegment> _reverseLineSegments() {
    List<util_dart.LineSegment> reversedAndRepositioned = [];
    for (util_dart.LineSegment lineSegment in lineSegments.reversed.toList(growable: false)) {
      reversedAndRepositioned.add(util_dart.LineSegment(
        totalPositionedLengthIncludesPadding - lineSegment.max,
        totalPositionedLengthIncludesPadding - lineSegment.min,
      ));
    }
    return reversedAndRepositioned;
  }

  @override
  bool operator ==(Object other) {
    bool typeSame = other is PositionedLineSegments && other.runtimeType == runtimeType;
    if (!typeSame) {
      return false;
    }

    // Dart knows other is LayedOutLineSegments, but for clarity:
    PositionedLineSegments otherSegment = other;
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
