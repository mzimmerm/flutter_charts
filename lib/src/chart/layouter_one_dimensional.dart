import 'dart:math' as math show max;
import 'package:tuple/tuple.dart';

import 'package:flutter_charts/src/util/util_dart.dart' as util_dart show LineSegment;

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
  /// the result is the same for any [Lineup] value.
  ///
  /// If the available [LengthsLayouter._freePadding] is non zero:
  ///
  /// - For [Lineup.start] or [Lineup.end] : Also aligns the group to min or max boundary.
  ///   For [Lineup.start], there is no padding between min and first element of the group,
  ///   all the padding [LengthsLayouter._freePadding] is after the end of the group;
  ///   similarly for [Lineup.end], for which the group end is aligned with the end,
  ///   and all the padding [LengthsLayouter._freePadding] is before the group.
  /// - For [Lineup.center] : The elements are packed into a group and the group centered.
  ///   That means, when [LengthsLayouter._freePadding] is available, half of the free length pads
  ///   the group on the boundaries
  ///
  snap,

  /// [Packing.loose] should layout elements so that they are separated with even amount of padding,
  /// if the available padding defined by [LengthsLayouter._freePadding] is not zero.
  /// If the available padding is zero, layout is the same as [Packing.snap] with no padding.
  ///
  /// If the available [LengthsLayouter._freePadding] is zero,
  /// the result is the same for any [Lineup] value,
  /// and also the same as the result of [Packing.snap] for any [Lineup] value:
  /// All elements are packed together.
  ///
  /// If the available [LengthsLayouter._freePadding] is non zero:
  ///
  /// - For [Lineup.start] or [Lineup.end] : Aligns the first element start to the min,
  ///   or the last element end to the max, respectively.
  ///   For [Lineup.start], the available [LengthsLayouter._freePadding] is distributed evenly
  ///   as padding between elements and at the end. First element start is at the boundary.
  ///   For [Lineup.end], the available [LengthsLayouter._freePadding] is distributed evenly
  ///   as padding at the beginning, and between elements. Last element end is at the boundary.
  /// - For [Lineup.center] : Same proportions of [LengthsLayouter._freePadding]
  ///   are distributed as padding at the beginning, between elements, and at the end.
  ///
  loose,
}

/// todo-01-document
/// This is alignment.
enum Lineup {
  start,
  center,
  end,
}

enum DivideConstraintsToChildren {
  evenly,
  ratios,
  noDivide,
}

// todo-00-last : document this
/// Properties of [BoxLayouter] describe [packing] and [alignment] of the layed out elements along
/// either a main axis or cross axis, along with [totalLength] the constraint on where the layout ends.
///
/// This class is also used to describe packing and alignment of the layed out elements
/// for the [LengthsLayouter], where it serves to describe the one-dimensional packing and alignment.
class OneDimLayoutProperties {
  final Packing packing;
  final Lineup lineup;
  // todo-00-last-last : changed from : double? totalLength : to : late final double totalLength
  double? totalLength;

  OneDimLayoutProperties({
    required this.packing,
    required this.lineup,
    // todo-00-last-last : added and removed required
    this.totalLength,
  });
}

/// This is a 1-dimensional layouter for segments represented only by list of [lengths].
///
/// The core algorithm in [layoutLengths] lays out the member list of [lengths] according to the
/// properties specified in member [oneDimLayoutProperties], and creates list of layed out segments from the [lengths].
///
/// The class of the member [oneDimLayoutProperties], [OneDimLayoutProperties], allows to specify
/// [Packing] and [Lineup] properties which control the layout result, along with [OneDimLayoutProperties.totalLenght],
/// which is the constraint for the layed out segments.
///
/// See [layoutLengths] for more details of this class' objects behavior.
///
class LengthsLayouter {
  LengthsLayouter({
    required this.lengths,
    required this.oneDimLayoutProperties,
  }) {
    switch (oneDimLayoutProperties.packing) {
      case Packing.matrjoska:
        oneDimLayoutProperties.totalLength ??= _maxLength;
        // Replacing asserts with setting _freePadding to 0 if negative.
        // Caller should allow this, and if layoutSize exceeds Constraints, deal with it in caller
        // assert(oneDimLayoutProperties.totalLength! >= _maxLength);
        // _freePadding = oneDimLayoutProperties.totalLength! - _maxLength;
        double freePadding = oneDimLayoutProperties.totalLength! - _maxLength;
        _freePadding = freePadding >= 0.0 ? freePadding : 0.0;
        break;
      case Packing.snap:
      case Packing.loose:
        oneDimLayoutProperties.totalLength ??= _sumLengths;
        // Replacing asserts with setting _freePadding to 0 if negative.
        // Caller should allow this, and if layoutSize exceeds Constraints, deal with it in caller
        // assert(oneDimLayoutProperties.totalLength! >= _sumLengths);
        // _freePadding = oneDimLayoutProperties.totalLength! - _sumLengths;
        double freePadding = oneDimLayoutProperties.totalLength! - _sumLengths;
        _freePadding = freePadding >= 0.0 ? freePadding : 0.0;
        break;
    }
  }

  // LengthsLayouter members
  final List<double> lengths;
  final OneDimLayoutProperties oneDimLayoutProperties;
  late final double _freePadding;
  double totalLayedOutLength = 0.0; // can change multiple times, set after each child length in lengths

  /// Lays out a list of imaginary sticks, with lengths in member [lengths], adhering to the layout properties
  /// defined in member [oneDimLayoutProperties].
  ///
  /// The input are members
  ///   - [lengths] which holds the lengths to lay out, and
  ///   - [oneDimLayoutProperties] which specifies the layout properties:
  ///     - [OneDimLayoutProperties.packing] and [OneDimLayoutProperties.lineup] that control the layout process
  ///       (where the imaginary sticks are positioned in the result).
  ///     - [OneDimLayoutProperties.totalLength] which is effectively the 1-dimensional constraint for the
  ///       min and max values of the layed out segments.
  ///
  /// The result of this method is a [LayedOutLineSegments] object, where this method wraps
  ///   - The layed out imaginary sticks of [lengths],is  placed in [LayedOutLineSegments.lineSegments]
  ///   - The total layed out length of the layed out [LayedOutLineSegments.lineSegments], INCLUDING PADDING,
  ///     is placed in [LayedOutLineSegments.totalLayedOutLength].
  ///
  /// The [LayedOutLineSegments.lineSegments] in the result have min and max, which are positioned by the algorithm
  /// along an interval starting at `0.0`, and generally ending at [OneDimLayoutProperties.totalLength].
  ///
  /// The algorithm keeps track of, and results in, the [totalLayedOutLength]
  /// which is effectively the layout size of all the layed out imaginary sticks [LayedOutLineSegments.lineSegments].
  ///
  /// OVERFLOW NOTE: This algorithm allows (as a valid but suspect result) each of two 'overflow conditions'
  ///    1. The last endpoint of [LayedOutLineSegments.lineSegments] > [OneDimLayoutProperties.totalLength]
  ///    2. [OneDimLayoutProperties.totalLength] < [LayedOutLineSegments.totalLayedOutLength]
  ///
  ///
  /// For example:
  ///   - Laying out using the [Packing.snap] and [Lineup.start], in [OneDimLayoutProperties] :
  ///     - The first length in [lengths] creates the first [LineSegment] in [layedOutLineSegments]; this first [LineSegment] has
  ///       - min = 0.0
  ///       - max = first length
  ///   - The second length in [lengths] creates the second [LineSegment] in [layedOutLineSegments]; this second [LineSegment] has
  ///     - min = first length (snapped to the end of the first segment)
  ///     - max = first length + second length.
  ///
  ///
  ///
  LayedOutLineSegments layoutLengths() {
    LayedOutLineSegments layedOutLineSegments;
    switch (oneDimLayoutProperties.packing) {
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
  /// positioning the [util_dart.LineSegment] according to [lineup].
  ///
  /// [Packing.matrjoska] ignores order of lengths, so there is no dependence on length predecessor.
  ///
  /// Also, for [Packing.matrjoska], the [lineup] applies *both* for alignment of lines inside the Matrjoska,
  /// as well as the whole largest Matrjoska alignment inside the available [totalLength].
  util_dart.LineSegment _matrjoskaLayoutLineSegmentFor(double length) {
    double start, end, freePadding;
    switch (oneDimLayoutProperties.lineup) {
      case Lineup.start:
        freePadding = _freePadding;
        start = 0.0;
        end = length;
        break;
      case Lineup.center:
        freePadding = _freePadding / 2;
        double matrjoskaInnerRoomLeft = (_maxLength - length) / 2;
        start = freePadding + matrjoskaInnerRoomLeft;
        end = freePadding + matrjoskaInnerRoomLeft + length;
        break;
      case Lineup.end:
        freePadding = _freePadding;
        start = freePadding + _maxLength - length;
        end = freePadding + _maxLength;
        break;
    }
    totalLayedOutLength = _maxLength + _freePadding;

    // todo-00-last : We should add [freePaddingLeft, freePaddingRight] and set them to LineSegment as that can be used if we want to create a boundRectangle that goes around the padding, not just tightly around the rectangles.
    return util_dart.LineSegment(start, end);
  }

  List<util_dart.LineSegment> _snapOrLooseLayoutAndMapLengthsToSegments(
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

  util_dart.LineSegment _snapLayoutLineSegmentFor(
    util_dart.LineSegment? previousSegment,
    double length,
  ) {
    return _snapOrLooseLayoutLineSegmentFor(_snapStartOffset, previousSegment, length);
  }

  util_dart.LineSegment _looseLayoutLineSegmentFor(
    util_dart.LineSegment? previousSegment,
    double length,
  ) {
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
      previousSegment = const util_dart.LineSegment(0.0, 0.0);
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
    switch (oneDimLayoutProperties.lineup) {
      case Lineup.start:
        freePadding = 0.0;
        freePaddingRight = _freePadding;
        startOffset = freePadding;
        break;
      case Lineup.center:
        freePadding = _freePadding / 2; // for center, half freeLength to the left
        freePaddingRight = freePadding;
        startOffset = isFirstLength ? freePadding : 0.0;
        break;
      case Lineup.end:
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
    switch (oneDimLayoutProperties.lineup) {
      case Lineup.start:
        freePadding = lengthsCount != 0 ? _freePadding / lengthsCount : _freePadding;
        freePaddingRight = freePadding;
        startOffset = isFirstLength ? 0.0 : freePadding;
        break;
      case Lineup.center:
        freePadding = lengthsCount != 0 ? _freePadding / (lengthsCount + 1) : _freePadding;
        freePaddingRight = freePadding;
        startOffset = freePadding;
        break;
      case Lineup.end:
        freePadding = lengthsCount != 0 ? _freePadding / lengthsCount : _freePadding;
        freePaddingRight = 0.0;
        startOffset = freePadding;
        break;
    }
    return Tuple2(startOffset, freePaddingRight);
  }
}

/// Holds a list of 1-dimensional [LineSegment]s layed out generally by [LengthsLayouter] from a list of lengths.
///
/// Each line segment in [lineSegments] has a min and max (start and end), where
/// the [LengthsLayouter] positioned them, the min and max values are
/// starting at 0.0 and ending at the [LengthsLayouter.oneDimLayoutProperties.totalLength].
///
/// The clients of this object usually use it to convert the member [lineSegments]
/// to one side of a rectangle along the axis corresponding to children (future) positions.
///
/// Note: on creation, it should be passed segments [lineSegments] already
///       layed out to their positions with [LengthsLayouter]
///       and [totalLayedOutLength] calculated by [LengthsLayouter.totalLayedOutLength].
class LayedOutLineSegments {
  const LayedOutLineSegments({required this.lineSegments, required this.totalLayedOutLength});

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
    bool typeSame = other is LayedOutLineSegments && other.runtimeType == runtimeType;
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
