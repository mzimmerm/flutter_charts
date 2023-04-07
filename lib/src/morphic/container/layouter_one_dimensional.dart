import 'dart:math' as math show max;
import 'package:tuple/tuple.dart';
import 'dart:ui' as ui;

// this level or equivalent
import 'container_layouter_base.dart' show BoxLayouter, ExternalTicksLayoutProvider, ExternalTickAtPosition;
import '../../util/util_dart.dart' as util_dart show LineSegment, Interval;

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
  /// - todo-04 implement and test : For [Align.centerExpand] : Same proportions of [LayedoutLengthsPositioner._freePadding]
  ///   are distributed as padding between elements; no padding at the beginning or at the end.
  ///
  loose,

  // todo-02 with this Packing, ANY ALIGNMENT DOES NOT MAKE SENSE. MAYBE WE INTRODUCE Align.externalTicksDefined and add a validate method that only allows
  externalTicksProvided,
}

/// Represents alignment of children during layouts.
enum Align {
  start,
  center,
  // todo-04 : added centerExpand but not tested or used. Originally intended for chart GridContainer layout. Maybe not needed?
  centerExpand,
  end,
}

/// todo-00-last-last : make Align extended enum, and add this method
Align otherEndAlign(Align align) {
  switch(align) {
    case Align.start:
      return Align.end;
    case Align.end:
      return Align.start;
    case Align.center:
    case Align.centerExpand:
      throw StateError('Invalid use here.');
  }
}



/// Describes how a constraint should be divided into multiple constraints,
/// presumably for the divided constraints to be passed to children.
///
/// The term 'divided' may be misleading for [ConstraintsDistribution.noDivide], as that
/// describes that a given constraint should create multiple constraints that are the same.
enum ConstraintsDistribution {
  evenly, // todo-023 : deprecate and remove. Rely on children to all set doubleWeights=1 instead
  doubleWeights,
  noDivide,
}

/// Properties of [BoxLayouter] describe [packing] and [align] of the layed out elements along
/// either a main axis or cross axis.
///
/// For layouters with [packing] = [Packing.externalTicksProvided], that is, for layouters using external ticks,
/// the optional [externalTicksLayoutProvider] must be also provided.
///
/// Instances are intended to be members on [RollingBoxLayouter]; they describe
/// the properties of the layouter and it's extensions such as [Row] and [Column].
/// In more detail: the members [align] and [packing] define alignment and packing of children
/// during layout; the member [layoutDirection] defines if children are layed out start-to-end
/// or end-to-start; the member [isPositioningMainAxis] is held on here for the logic in
/// [LayedoutLengthsPositioner.positionLengths] to perform [PositionedLineSegments.reversedCopy]
/// only on main axis.
///
/// This class is used to describe packing and alignment of the layed out elements
/// for the 1-dimensional [LayedoutLengthsPositioner], where it serves to describe the 1-dimensional packing and alignment.
class LengthsPositionerProperties {

  final Align align;
  final Packing packing;
  final ExternalTicksLayoutProvider? externalTicksLayoutProvider;

  const LengthsPositionerProperties({
    required this.align,
    required this.packing,
    this.externalTicksLayoutProvider,
  });
}

/// A 1-dimensional layouter for segments represented only by [lengths] of the segments.
///
/// The [lengths] typically originate from children [BoxLayouter.layoutSize]s of a parent [BoxLayouter]
/// which creates this object - this is reflected in the adjective 'Layedout'
/// in the name [LayedoutLengthsPositioner].
///
/// The [lengthsPositionerProperties] specifies [Packing] and [Align] properties.
/// They control the layout result, along with [lengthsConstraint],
/// which is the constraint for the layed out segments.
///
/// The core method providing the layout role is [positionLengths],
/// which lays out the member [lengths] according to the
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
/// See [positionLengths] for more details of this class' objects behavior.
///
class LayedoutLengthsPositioner {

  /// Creates a [LayedoutLengthsPositioner] for the passed [lengths] which should be
  /// lengths of [children], along the axis we create the positioner for.
  ///
  /// The passed objects must all correspond to the axis for which the positioner is being created:
  /// - [layoutAxis] defines horizontal or vertical,
  /// - [lengthsPositionerProperties] is the wrapper for [Align] and [Packing].
  /// - [lengthsConstraint] is the double 1D positive length into which the [lengths] should fit after positioning
  ///    by [positionLengths].
  /// - [externalTicksLayoutProvider] only applies for [Packing.externalTicksProvided]
  ///
  LayedoutLengthsPositioner({
    // todo-00-next : should we assert only positive or 0 lengths?
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
      case Packing.externalTicksProvided:
        assert(lengthsPositionerProperties.externalTicksLayoutProvider != null);
        assert(lengthsPositionerProperties.externalTicksLayoutProvider!.tickValues.length == lengths.length);
        // For external layout, isOverflown is calculated after positioning.
        // For external layout, _freePadding is unused and unchanged, but late init it to 0.0 if it is used
        _freePadding = 0.0;
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
  ///     - The first length in [lengths] creates the first [LineSegment] in [layedOutLineSegments];
  ///       this first [LineSegment] has
  ///       - min = 0.0
  ///       - max = first length
  ///   - The second length in [lengths] creates the second [LineSegment] in [layedOutLineSegments];
  ///     this second [LineSegment] has
  ///     - min = first length (tight to the end of the first segment)
  ///     - max = first length + second length.
  ///
  ///
  PositionedLineSegments positionLengths() {
    PositionedLineSegments positionedLineSegments;
    switch (lengthsPositionerProperties.packing) {
      case Packing.matrjoska:
        positionedLineSegments = PositionedLineSegments(
          lineSegments: _assertLengthsPositiveAndReturn(
              lengths.map((length) => _positionMatrjoskaLineSegmentFor(length)).toList(growable: false)),
          totalPositionedLengthIncludesPadding: totalPositionedLengthIncludesPadding,
          isOverflown: isOverflown,
        );
        break;
      case Packing.tight:
        positionedLineSegments = PositionedLineSegments(
          lineSegments:
              _assertLengthsPositiveAndReturn(
                  _positionTightOrLooseAsSegments(_positionTightLineSegmentFor)),
          totalPositionedLengthIncludesPadding: totalPositionedLengthIncludesPadding,
          isOverflown: isOverflown,
        );
        break;
      case Packing.loose:
        positionedLineSegments = PositionedLineSegments(
          lineSegments:
              _assertLengthsPositiveAndReturn(
                  _positionTightOrLooseAsSegments(_positionLooseLineSegmentFor)),
          totalPositionedLengthIncludesPadding: totalPositionedLengthIncludesPadding,
          isOverflown: isOverflown,
        );
        break;
      case Packing.externalTicksProvided:
        positionedLineSegments = PositionedLineSegments(
          lineSegments: _assertLengthsPositiveAndReturn(
              _positionToExternalTicksAsSegments()),
          totalPositionedLengthIncludesPadding: totalPositionedLengthIncludesPadding,
          isOverflown: isOverflown,
        );
        break;
    }

    return positionedLineSegments;
  }

  double get _sumLengths => lengths.fold(0.0, (previousLength, length) => previousLength + length);

  double get _maxLength => lengths.isNotEmpty ? lengths.reduce(math.max) : 0.0;

  List<util_dart.LineSegment> _positionTightOrLooseAsSegments(
    util_dart.LineSegment Function(util_dart.LineSegment?, double) fromPreviousLengthPositionThis,
  ) {
    List<util_dart.LineSegment> lineSegments = [];
    util_dart.LineSegment? previousSegment;
    for (int i = 0; i < lengths.length; i++) {
      if (i == 0) {
        previousSegment = null;
      }
      previousSegment = fromPreviousLengthPositionThis(previousSegment, lengths[i]);
      lineSegments.add(previousSegment);
    }
    return lineSegments;
  }

  /// Invoked for [Packing.externalTicksProvided], positions the member [lengths]
  /// to the right, center, or left of the external ticks, defined by the member [externalTicksLayoutProvider].
  ///
  /// The member [externalTicksLayoutProvider] must be not null for [Packing.externalTicksProvided].
  List<util_dart.LineSegment> _positionToExternalTicksAsSegments() {
    // depending on externalTicksLayoutProvider.externalTickAtPosition,
    // iterate externalTicksLayoutProvider.tickValues, and place each lenght in lengths to position given by the tickValue,
    // moved a bit depending on externalTickAtPosition\

    ExternalTicksLayoutProvider ticksProvider = lengthsPositionerProperties.externalTicksLayoutProvider!;

    List<util_dart.LineSegment> positionedSegments = [];

    for (int i = 0; i < lengths.length; i++) {
      double startOffset, endOffset;
      switch (ticksProvider.externalTickAtPosition) {
        case ExternalTickAtPosition.childStart:
          startOffset = 0.0;
          endOffset = lengths[i];
          break;
        case ExternalTickAtPosition.childCenter:
          startOffset = -1 * lengths[i] / 2;
          endOffset = lengths[i] / 2;
          break;
        case ExternalTickAtPosition.childEnd:
          startOffset = -1 * lengths[i];
          endOffset = 0;
          break;
      }
      positionedSegments.add(util_dart.LineSegment(
        ticksProvider.tickPixels[i] + startOffset,
        ticksProvider.tickPixels[i] + endOffset,
      ));
    }

    // Before returning, we can calculate the overflow and total length
    if (positionedSegments.isEmpty) {
      totalPositionedLengthIncludesPadding = 0.0;
      isOverflown = false;
    }

    util_dart.Interval envelope = positionedSegments[0].envelope(positionedSegments);

    totalPositionedLengthIncludesPadding = envelope.length;
    isOverflown = !ticksProvider.tickValuesDomain.containsFully(envelope);

    return positionedSegments;
  }

  util_dart.LineSegment _positionTightLineSegmentFor(
    util_dart.LineSegment? previousSegment,
    double length,
  ) {
    return _positionTightOrLooseLineSegmentFor(_tightStartOffset, previousSegment, length);
  }

  util_dart.LineSegment _positionLooseLineSegmentFor(
    util_dart.LineSegment? previousSegment,
    double length,
  ) {
    return _positionTightOrLooseLineSegmentFor(_looseStartOffset, previousSegment, length);
  }

  util_dart.LineSegment _positionTightOrLooseLineSegmentFor(
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
    // todo-020 : The processing of result startOffsetAndRightPad MUST be different for Align.end, so there must be some
    //             switch .. case added for all Alignments. This is the reason of a bug where Align.end does not work correctly,
    //             although it is hidden, as the result now is satisfactory, despite setting isOverflow true on the result.
    //             ALSO A QUESTION: ALIGN.END, DOES IT MEAN FIRST LENGTH IS AT THE END? SHOULD NOT BE - START AND END SHOULD BE THE SAME ORDER.!!
    //               PERHAPS THERE SHOULD BE ENUM START_TO_END (DEFAULT, DOES NOT REVERT ORDER), AND END_TO_START WHICH REVERSES ORDED.
    double startOffset = startOffsetAndRightPad.item1;
    double rightPad = startOffsetAndRightPad.item2;
    double start = startOffset + previousSegment.max;
    double end = startOffset + previousSegment.max + length;
    totalPositionedLengthIncludesPadding = end + rightPad;
    return util_dart.LineSegment(start, end);
  }

  /// Intended for use in  [Packing.matrjoska], creates and returns a [util_dart.LineSegment] for the passed [length],
  /// positioning the [util_dart.LineSegment] according to [align].
  ///
  /// [Packing.matrjoska] ignores order of lengths, so there is no dependence on length predecessor.
  ///
  /// Also, for [Packing.matrjoska], the [align] applies *both* for alignment of lines inside the Matrjoska,
  /// as well as the whole largest Matrjoska alignment inside the available [totalLayedOutLengthIncludesPadding].
  util_dart.LineSegment _positionMatrjoskaLineSegmentFor(double length) {
    double start, end, freePadding;
    switch (lengthsPositionerProperties.align) {
      case Align.start:
        // matrjoska does not do any padding, for Start or End, or Center
        //   - no space offset from the start or end
        //   - no space between lengths (this is obvious property of matrjoska)
        freePadding = 0.0;
        start = freePadding;
        end = length;
        totalPositionedLengthIncludesPadding = _maxLength + freePadding;
        break;
      case Align.center:
        // matrjoska does not do any padding, for Start or End, or Center : freePadding = _freePadding / 2;
        freePadding = 0.0;
        double matrjoskaInnerRoomLeft = (_maxLength - length) / 2;
        start = freePadding + matrjoskaInnerRoomLeft;
        end = freePadding + matrjoskaInnerRoomLeft + length;
        totalPositionedLengthIncludesPadding = _maxLength + 2 * freePadding;
        break;
      case Align.centerExpand:
        freePadding = 0.0; // for centerExpand, no free padding
        double matrjoskaInnerRoomLeft = (_maxLength - length) / 2;
        start = freePadding + matrjoskaInnerRoomLeft;
        end = freePadding + matrjoskaInnerRoomLeft + length;
        totalPositionedLengthIncludesPadding = _maxLength + freePadding;
        break;
      case Align.end:
        // matrjoska does not do any padding, for Start or End, or Center
        freePadding = 0.0;
        start = freePadding + _maxLength - length;
        end = freePadding + _maxLength;
        totalPositionedLengthIncludesPadding = _maxLength + freePadding;
        break;
    }

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

  List<util_dart.LineSegment> _assertLengthsPositiveAndReturn(List<util_dart.LineSegment> lineSegments) {
    for (var lineSegment in lineSegments) {
      if (lineSegment.min > lineSegment.max) {
        throw StateError('LineSegment min > max in lineSegment=$lineSegment; all segments=$lineSegments');
      }
    }
    return lineSegments;
  }
}

/// A value class which holds on the result of invocation
/// of the 1-dimensional layouter [LayedoutLengthsPositioner.positionLengths].
///
/// It's members and what each holds on:
///   - [lineSegments] a list of [util_dart.LineSegment]s that have been positioned
///     by [LayedoutLengthsPositioner.positionLengths] from a list of lengths
///     [LayedoutLengthsPositioner.lengths] which the [LayedoutLengthsPositioner] was asked to lay out.
///     Each line segment in [lineSegments] has a min and max (start and end), where
///     the [LayedoutLengthsPositioner.positionLengths] positioned them; the min and max values are
///     starting at 0.0 and ending at [totalPositionedLengthIncludesPadding].
///     If [totalPositionedLengthIncludesPadding] needed by the layouter was
///     greater than LayedoutLengthsPositioner.lengthsConstraint] [isOverflown] is set to true.
///   - [totalPositionedLengthIncludesPadding] is the total length used by the positioner during
///     [LayedoutLengthsPositioner.positionLengths].
///   - [isOverflown] is set to true if the [totalPositionedLengthIncludesPadding] needed
///     was larger then [LayedoutLengthsPositioner.lengthsConstraint].
///
/// The [isOverflown] is only a marker that the process that lead to layout overflew it's constraints.
///
/// The clients of this object usually use this object to convert the member [lineSegments]
/// to one side of a rectangle along the axis corresponding to children (future) positions.
///
/// Note: on creation, it should be passed segments [lineSegments] already
///       layed out to their positions with [LayedoutLengthsPositioner.positionLengths]
///       and [totalLayedOutLengthIncludesPadding]
///       calculated by [LayedoutLengthsPositioner.totalLayedOutLengthIncludesPadding],
///       as well as [isOverflown].
///
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
  // todo-02-next : how is this actually used ?? Why is width 0.0?? It must work but how?
  ui.Size get envelope => ui.Size(0.0, totalPositionedLengthIncludesPadding);

  /// Returns copy of this instance's [lineSegments] that are reversed and
  /// re-layedout (layed out from end rather than start).
  ///
  /// The reversal is equivalent to two 1-dimensional transforms:
  ///   - x -> x + -totalPositionedLengthIncludesPadding
  ///   - x -> -x
  /// Combined, the transform is
  ///   - x -> totalPositionedLengthIncludesPadding -x
  ///
  /// Because the [lineSegments] members were layed out and kept in increasing order of [LineSegment.min],
  /// for the result to keep the same order, the order of elements in [lineSegments] is also reversed.
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
