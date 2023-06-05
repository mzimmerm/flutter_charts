import 'dart:math' as math show max;

// this level or equivalent
import 'container_layouter_base.dart';
import 'morphic_dart_enums.dart' show ExternalTickAtPosition;
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
  // todo-02 Should add multiple Packing enums, which would collapse to a common 'wide' enum in the 1D layouter.
  //         the enums can be: RollingPacking (matrjoska, tight, loose) - used in Box layouters
  //                           ExternalPacking (externalTicksProvided) - used in ExternalTicks layouters
  //                           WrappingPacking (tight) - used in Wrapping layouters
  externalTicksProvided,
}

/// Represents alignment of children along one dimension (orientation) during layouts,
///   in the dimension of the alignment; the dimension of the alignment is typically
///   defined as a 'main axis' / 'cross axis' of the layouter or 'horizontal axis' and 'vertical axis' of the layouter.
///
/// Layouters may or may not define alignment. Most layouters do define alignment, and if they do,
/// they must define alignment in both 2D dimensions (orientations).
/// Some layouters use the term 'horizontal axis' and 'vertical axis', others use the term 'main axis' and 'cross axis'.
/// Examples:
///   - [TableLayouter] define orientation alignments in members [TableLayouter.horizontalAlign]
///     and [TableLayouter.verticalAlign] and corresponding construction parameters names.
///   - [MainAndCrossAxisBoxLayouter] and extensions define orientation alignments in construction parameters names
///     `mainAxisAlign` and `crossAxisAlign`.
///
/// [Packing] is a related concept which describes how the positioned 1D segments are placed in 1D relative
/// to each other. We describe the positioned 1D segments as 'group of segments'.
///
///   - For [Packing.tight] and [Packing.loose], the alignment describes the position of the group of segments
///     in one dimension of [BoxLayouter.constraints] - in other words, alignment describes how the whole group of segments
///     is aligned in constraints. In those packing(s), there may be a free space between the start of constraints
///     and start of the group of segments (equivalent at the end).
///   - For [Packing.matrjoska], the alignment describes the position INSIDE the group of segments. There is no free space
///     between the start of constraints and the start of the group of segments - the group of segments is always aligned
///     at the start of the constraints.
///
enum Align {
  start,
  center,
  // todo-04 : added centerExpand but not tested or used. Originally intended for chart GridContainer layout. Maybe not needed?
  centerExpand,
  end;

  /// Returns the [Align] transposed to the other end of this [Align].
  Align otherEndAlign() {
    switch(this) {
      case Align.start:
        return Align.end;
      case Align.end:
        return Align.start;
      case Align.center:
        return Align.center;
      case Align.centerExpand:
        return Align.center;
    }
  }
}

/// Describes how a constraint should be divided into multiple constraints,
/// before the divided constraints are passed to children.
///
/// The decision if or how constraints are divided, is determined by two concepts:
///   - The constraints weights of children 'for parent', use the [ConstraintsWeight] instances,
///     and its wrapper [ConstraintsWeights] instances.
///   - The constraints division strategy 'to children (as parent)', use this [ConstraintsDivideMethod] instances.
///
/// Because both can be set, priorities must be defined. The detail priorities are implemented
/// by individual layouters. So far, the single use is in [MainAndCrossAxisBoxLayouter].
/// See [MainAndCrossAxisBoxLayouter.constraintsDivideMethod].
///
enum ConstraintsDivideMethod {
  evenDivision,
  byChildrenWeights,
  noDivision;

  bool isNot(ConstraintsDivideMethod other) {
    if (this != other) return true;
    return false;
  }
}

/// Properties of [BoxLayouter] describe [packing] and [align] of the layed out elements along
/// either a main axis or cross axis.
///
/// For layouters with [packing] = [Packing.externalTicksProvided], that is, for layouters using external ticks,
/// the optional [externalTicksLayoutDescriptor] must be also provided.
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

  const LengthsPositionerProperties({
    required this.align,
    required this.packing,
    this.externalTicksLayoutDescriptor,
  });

  final Align align;
  final Packing packing;
  final ExternalTicksLayoutDescriptor? externalTicksLayoutDescriptor;

}

/// A 1-dimensional layouter for segments represented only by [lengths] of the segments.
///
/// The [lengths] typically originate from children [BoxLayouter.layoutSize]s of a parent [BoxLayouter]
/// which creates this object - this is reflected in the adjective 'Layedout'
/// in the name [LayedoutLengthsPositioner].
///
/// The [lengthsPositionerProperties] specifies [Packing] and [Align] properties.
/// They control the layout result, along with [_lengthsConstraint],
/// which is the constraint for the layed out segments.
///
/// The core method providing the layout role is [positionLengths],
/// which lays out the member [lengths] according to the
/// properties specified in member [lengthsPositionerProperties], and creates list
/// of layed out segments from the [lengths]; the layed out segments may be padded
/// if there is length available towards the [_lengthsConstraint].
///
/// Note: The total length of [lengths] depends on Packing - it is
///   - sum lengths for tight or loose
///   - max length for matrjoska
///
/// If the total length of [lengths] is below [_lengthsConstraint],
/// and the combination of Packing and Align allows free spacing, the remaining
/// [_lengthsConstraint] are used to add spaces between, around, or to the left of the
/// resulting segments.
///
/// See [positionLengths] for more details of this class' objects behavior.
///
class LayedoutLengthsPositioner {

  /// Constructor of a [LayedoutLengthsPositioner] for the passed [lengths] which should be
  /// lengths of children, along the axis the positioner handles.
  ///
  /// Note: The axis the positioner handles is not a member, arguably it should be! Clients manage that information.
  ///
  /// The passed objects must all correspond to the axis for which this positioner is being created:
  /// - The [lengthsPositionerProperties] is the wrapper for [Align] and [Packing].
  /// - [_lengthsConstraint] is the double 1D positive length into which the [lengths] should fit after positioning
  ///    by [positionLengths].
  /// - [externalTicksLayoutDescriptor] only applies for [Packing.externalTicksProvided]
  ///
  LayedoutLengthsPositioner({
    required this.lengths,
    required this.lengthsPositionerProperties,
    required double lengthsConstraint,
    bool isStopBeforeFirstOverflow = false,
  }) :
        _lengthsConstraint = lengthsConstraint,
        _isStopBeforeFirstOverflow = isStopBeforeFirstOverflow
  {
    // 2023-04-27: Added assert only positive or 0 lengths allowed. Later we can use negative positioning
    for(var length in lengths) {
      if (length < 0.0) {
        throw StateError('$runtimeType: at least one lenght in lengths is negative: $lengths');
      }
    }
    if (_lengthsConstraint == double.infinity || _lengthsConstraint < 0) {
      throw StateError('$runtimeType: lengthsConstraint must be finite non-negative, but it is $_lengthsConstraint');
    }

    if (_isStopBeforeFirstOverflow) {
      // If set _freePadding and isOverflown is set later during processing
      // We have to ensure that late finals isOverflown and _freePadding are set!
      // But likely, this should be done when _isStopBeforeFirstOverflow is returning,
      // to allow for some _freePadding to be used! But this does not seem crucial ATM.
      _freePadding = 0.0;
      _isOverflown = false;
    } else {
      switch (lengthsPositionerProperties.packing) {
        case Packing.matrjoska:
          // Caller should allow for lengthsConstraint to be exceeded by _maxLength, set isOverflown, deal with it in caller
          _isOverflown = (_maxLength > _lengthsConstraint);
          _freePadding = _isOverflown ? 0.0 : _lengthsConstraint - _maxLength;
          break;
        case Packing.tight:
        case Packing.loose:
          // Caller should allow for lengthsConstraint to be exceeded by _sumLengths, set isOverflown, deal with it in caller
          _isOverflown = (_sumLengths > _lengthsConstraint);
          _freePadding = _isOverflown ? 0.0 : _lengthsConstraint - _sumLengths;
          break;
        case Packing.externalTicksProvided:
          assert(lengthsPositionerProperties.externalTicksLayoutDescriptor != null);
          assert(lengthsPositionerProperties.externalTicksLayoutDescriptor!.tickValues.length == lengths.length);
          // For external layout, isOverflown is calculated after positioning.
          // For external layout, _freePadding is unused and unchanged, but late init it to 0.0 if it is used
          _freePadding = 0.0;
          break;
      }
    }
  }

  // LayedoutLengthsPositioner members
  final List<double> lengths;
  final LengthsPositionerProperties lengthsPositionerProperties;
  late final double _freePadding;
  /// The maximum length the [lengths] positioned as [PositionedLineSegments] returned
  /// from [positionLengths] should use before being considered overflown.
  late final double _lengthsConstraint;
  /// Indicates the [lengths] cannot be layed out, given the [lengthsPositionerProperties],
  /// in the length available in [_lengthsConstraint].
  ///
  /// Calculated in constructor to true if lengthsConstraint < _maxLength or _sumLengths.
  ///
  /// Passed to [PositionedLineSegments] for clients to know about overflow situation.
  late final bool _isOverflown;
  /// During processing, manages the total length of [lengths] positioned so far.
  /// Can change multiple times, set after each child length in lengths is converted to [LineSegment].
  /// todo-011-simplify : Not used in anything in layout, only in test. Consider removal
  double _totalPositionedLengthIncludesPadding = 0.0;
  /// If `true`, the [positionLengths] algorithm stops and returns before positioning the length which would
  /// exceed the [_lengthsConstraint].
  ///
  /// Used in [WrappingBoxLayouter] and extensions to wrap to next line (or column)
  /// before exceeding the [_lengthsConstraint].
  final bool _isStopBeforeFirstOverflow;

  /// Return `true` if the passed [positionedSegment] would exceed the [_lengthsConstraint].
  ///
  /// Should be only called if [_isStopBeforeFirstOverflow] `true`
  bool _isExceedLengthsConstraint(util_dart.LineSegment positionedSegment) {
    return positionedSegment.max > _lengthsConstraint;
  }

  /// Lays out a list of imaginary sticks, with lengths in member [lengths], adhering to the layout properties
  /// defined in member [lengthsPositionerProperties].
  ///
  /// Returns the imaginary sticks layed out, as [PositionedLineSegments].
  ///
  /// From the [lengths], it creates a list of layed out segments ; the layed out segments may be padded
  /// if there is length available towards the [_lengthsConstraint].
  ///
  /// The input are members
  ///   - [lengths] which holds the lengths to lay out, and
  ///   - [lengthsPositionerProperties] which specifies the layout properties:
  ///     - [LengthsPositionerProperties.packing] and [LengthsPositionerProperties.align] that control the layout process
  ///       (where the imaginary sticks are positioned in the result).
  ///     - [_lengthsConstraint] which is effectively the 1-dimensional constraint for the
  ///       min and max values of the layed out segments.
  ///
  /// The result of this method is a [PositionedLineSegments] object which wraps the imaginary layed out sticks.
  ///
  /// Note: The total length of [lengths] depends on Packing - it is
  ///   - sum lengths for tight or loose
  ///   - max length for matrjoska
  ///
  /// If the total length of [lengths] is below [_lengthsConstraint],
  /// and the combination of Packing and Align allows free spacing, the remaining
  /// [_lengthsConstraint] are used to add spaces between, around, or to the left of the
  /// resulting segments.
  ///
  /// OVERFLOW NOTES: This algorithm allows (as a valid but suspect result) an 'overflow condition', in which
  ///
  ///    -  The last endpoint of [PositionedLineSegments.lineSegments] > [lengthsConstraint],
  ///       see [_isOverflown].
  ///    - In [_isOverflown] condition, no padding is used. Also, several things are true
  ///      -
  ///      - [PositionedLineSegments.totalPositionedLengthIncludesPadding] = the sum or max of [lengths] depending on Packing.
  ///      - [PositionedLineSegments.totalPositionedLengthIncludesPadding] > [_lengthsConstraint]
  ///
  ///
  /// Example:
  ///   - Laying out using the [Packing.tight] and [Align.start], in [LengthsPositionerProperties] :
  ///     - The first length in [lengths] creates the first [LineSegment] in [PositionedLineSegments];
  ///       this first [LineSegment] has
  ///       - min = 0.0
  ///       - max = first length
  ///   - The second length in [lengths] creates the second [LineSegment] in [PositionedLineSegments];
  ///     this second [LineSegment] has
  ///     - min = first length (tight to the end of the first segment)
  ///     - max = first length + second length.
  ///
  ///
  /// If [_isStopBeforeFirstOverflow] is `true`, and first overflow happens, stop and return PositionedLineSegments
  /// which may not contain all lengths (PositionedLineSegments). Caller must process this situation.
  PositionedLineSegments positionLengths() {
    PositionedLineSegments positionedLineSegments;
    switch (lengthsPositionerProperties.packing) {
      case Packing.matrjoska:
        positionedLineSegments = PositionedLineSegments(
          lineSegments:
              _assertLengthsPositiveAndReturn(_positionAsSegments(_positionMatrjoskaLineSegmentFromPreviousAndLength)),
          totalPositionedLengthIncludesPadding: _totalPositionedLengthIncludesPadding,
          isOverflown: _isOverflown,
        );

        break;
      case Packing.tight:
        positionedLineSegments = PositionedLineSegments(
          lineSegments:
              _assertLengthsPositiveAndReturn(_positionAsSegments(_positionTightLineSegmentFromPreviousAndLength)),
          totalPositionedLengthIncludesPadding: _totalPositionedLengthIncludesPadding,
          isOverflown: _isOverflown,
        );
        break;
      case Packing.loose:
        positionedLineSegments = PositionedLineSegments(
          lineSegments:
              _assertLengthsPositiveAndReturn(_positionAsSegments(_positionLooseLineSegmentFromPreviousAndLength)),
          totalPositionedLengthIncludesPadding: _totalPositionedLengthIncludesPadding,
          isOverflown: _isOverflown,
        );
        break;
      case Packing.externalTicksProvided:
        positionedLineSegments = PositionedLineSegments(
          lineSegments: _assertLengthsPositiveAndReturn(_positionToExternalTicksAsSegments()),
          totalPositionedLengthIncludesPadding: _totalPositionedLengthIncludesPadding,
          isOverflown: _isOverflown,
        );
        break;
    }

    return positionedLineSegments;
  }

  double get _sumLengths => lengths.fold(0.0, (previousLength, length) => previousLength + length);

  double get _maxLength => lengths.isNotEmpty ? lengths.reduce(math.max) : 0.0;

  /// Calculates and returns [util_dart.LineSegment]s positioned from [lengths]
  /// using a function [fromPreviousLengthPositionThis] which calculates current segment position
  /// from previous segment position and current segment's length.
  ///
  /// There are several implementations of [fromPreviousLengthPositionThis], each calculating
  /// for a specific [Packing]. For [Packing.externalTicksProvided], there is a specific function
  /// [_positionToExternalTicksAsSegments] with a different signature for the same purpose.
  List<util_dart.LineSegment> _positionAsSegments(
      util_dart.LineSegment Function(util_dart.LineSegment?, double) fromPreviousLengthPositionThis,
      ) {
    List<util_dart.LineSegment> lineSegments = [];
    util_dart.LineSegment? previousSegment;
    for (int i = 0; i < lengths.length; i++) {
      if (i == 0) {
        previousSegment = null;
      }
      util_dart.LineSegment lengthSegment = fromPreviousLengthPositionThis(previousSegment, lengths[i]);
      if (_isStopBeforeFirstOverflow && _isExceedLengthsConstraint(lengthSegment)) {
        // If client asked to stop before overflow (used by [WrappingBoxLayouter]):
        //   - for first segment, still add it, it will overflow but do not want to loose it
        //   - for further segments, do not add, and return the previous list which did not overflow
        if (i == 0) {
          lineSegments.add(lengthSegment);
        }
        return lineSegments;
      }
      lineSegments.add(lengthSegment);

      previousSegment = lengthSegment;
    }
    return lineSegments;
  }

  /// Invoked for [Packing.externalTicksProvided], returns positions for the member [lengths]
  /// to the right, center, or left of the external ticks in [ExternalTicksLayoutDescriptor.tickPixels].
  ///
  /// The position being right, center, or left of the external ticks
  /// is defined by the member's [lengthsPositionerProperties] enum member
  /// [LengthsPositionerProperties.externalTicksLayoutDescriptor];
  /// this nullable enum member must be not null for [Packing.externalTicksProvided].
  List<util_dart.LineSegment> _positionToExternalTicksAsSegments() {
    // depending on [ExternalTicksLayoutDescriptor.externalTickAtPosition] value of [ExternalTickAtPosition]
    // childStart, childEnd, or childCenter, iterate [lengths], and place each [tickPixels] member
    // in lengths to position given by the tickValue, moved left or right depending on externalTickAtPosition

    ExternalTicksLayoutDescriptor ticksDescriptor = lengthsPositionerProperties.externalTicksLayoutDescriptor!;

    List<util_dart.LineSegment> positionedSegments = [];

    for (int i = 0; i < lengths.length; i++) {
      double startOffset, endOffset;
      switch (ticksDescriptor.externalTickAtPosition) {
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
        ticksDescriptor.tickPixels[i] + startOffset,
        ticksDescriptor.tickPixels[i] + endOffset,
      ));
    }

    // Before returning, we can calculate the overflow and total length
    if (positionedSegments.isEmpty) {
      _totalPositionedLengthIncludesPadding = 0.0;
      _isOverflown = false;
    }

    util_dart.Interval envelope = positionedSegments[0].envelope(positionedSegments);

    _totalPositionedLengthIncludesPadding = envelope.length;
    _isOverflown = !ticksDescriptor.tickValuesRange.containsFully(envelope);

    return positionedSegments;
  }

  util_dart.LineSegment _positionTightLineSegmentFromPreviousAndLength(
    util_dart.LineSegment? previousSegment,
    double length,
  ) {
    return _positionTightOrLooseLineSegmentFromPreviousAndLength(_tightStartOffset, previousSegment, length);
  }

  util_dart.LineSegment _positionLooseLineSegmentFromPreviousAndLength(
    util_dart.LineSegment? previousSegment,
    double length,
  ) {
    return _positionTightOrLooseLineSegmentFromPreviousAndLength(_looseStartOffset, previousSegment, length);
  }

  /// Creates and returns a [util_dart.LineSegment] for the passed [length],
  /// positioning the [length] after the [previousSegment].
  ///
  /// Common process to position length as [util_dart.LineSegment] given [lengthsPositionerProperties] with
  /// [Packing.tight] or [Packing.loose].
  ///
  /// - The [previousSegment] captures the position of previous segment as [util_dart.LineSegment.min] and
  ///   [util_dart.LineSegment.max].
  /// - [length] is the length of this segment.
  /// - [getStartOffset] function calculates start offset of the first length.
  /// - Calculates and returns the position of the segment with length [length],
  ///   taking into account the [lengthsPositionerProperties] alignment and padding,
  ///   the free padding maintained in [_freePadding] (which can be distributed at the beginning, at the end, or between
  ///   [lengths]), the total available length [_lengthsConstraint], as well as overflow state [_isOverflown].
  util_dart.LineSegment _positionTightOrLooseLineSegmentFromPreviousAndLength(
      _StartAndRightPad Function(bool) getStartOffset,
      util_dart.LineSegment? previousSegment,
      double length,
      ) {
    bool isFirstLength = false;
    if (previousSegment == null) {
      isFirstLength = true;
      previousSegment = const util_dart.LineSegment(0.0, 0.0);
    }
    _StartAndRightPad startOffsetAndRightPad = getStartOffset(isFirstLength);
    // todo-020 : The processing of result startOffsetAndRightPad MUST be different for Align.end, so there must be some
    //             switch .. case added for all Alignments. This is the reason of a bug where Align.end does not work correctly,
    //             although it is hidden, as the result now is satisfactory, despite setting isOverflow true on the result.
    //             ALSO A QUESTION: ALIGN.END, DOES IT MEAN FIRST LENGTH IS AT THE END? SHOULD NOT BE - START AND END SHOULD BE THE SAME ORDER.!!
    //               PERHAPS THERE SHOULD BE ENUM START_TO_END (DEFAULT, DOES NOT REVERT ORDER), AND END_TO_START WHICH REVERSES ORDED.
    double startOffset = startOffsetAndRightPad.startOffset;
    double rightPad = startOffsetAndRightPad.freePaddingRight;
    double start = startOffset + previousSegment.max;
    double end = startOffset + previousSegment.max + length;
    _totalPositionedLengthIncludesPadding = end + rightPad;
    return util_dart.LineSegment(start, end);
  }

  /// For this [lengthsPositionerProperties] packing [Packing.matrjoska],
  /// creates and returns a [util_dart.LineSegment] for the passed [length],
  /// positioning the [length] after the [previousSegment]
  /// according to this [lengthsPositionerProperties] alignment.
  ///
  /// [Packing.matrjoska] ignores order of lengths, so there is no dependence
  /// on the length predecessor, the [previousSegment].
  ///
  /// Also, for [Packing.matrjoska], the [align] applies *both* for alignment of lines inside the Matrjoska,
  /// as well as the whole largest Matrjoska alignment inside the available [totalPositionedLengthIncludesPadding].
  ///
  /// See [_positionTightLineSegmentFromPreviousAndLength] for discussion of state of this instance
  /// used in the calculation.
  util_dart.LineSegment _positionMatrjoskaLineSegmentFromPreviousAndLength(
    util_dart.LineSegment? previousSegment,
    double length,
  ) {
    double start, end, freePadding;
    switch (lengthsPositionerProperties.align) {
      case Align.start:
        // matrjoska does not do any padding, for Start or End, or Center
        //   - no space offset from the start or end
        //   - no space between lengths (this is obvious property of matrjoska)
        freePadding = 0.0;
        start = freePadding;
        end = length;
        _totalPositionedLengthIncludesPadding = _maxLength + freePadding;
        break;
      case Align.center:
        // matrjoska does not do any padding, for Start or End, or Center : freePadding = _freePadding / 2;
        freePadding = 0.0;
        double matrjoskaInnerRoomLeft = (_maxLength - length) / 2;
        start = freePadding + matrjoskaInnerRoomLeft;
        end = freePadding + matrjoskaInnerRoomLeft + length;
        _totalPositionedLengthIncludesPadding = _maxLength + 2 * freePadding;
        break;
      case Align.centerExpand:
        freePadding = 0.0; // for centerExpand, no free padding
        double matrjoskaInnerRoomLeft = (_maxLength - length) / 2;
        start = freePadding + matrjoskaInnerRoomLeft;
        end = freePadding + matrjoskaInnerRoomLeft + length;
        _totalPositionedLengthIncludesPadding = _maxLength + freePadding;
        break;
      case Align.end:
        // matrjoska does not do any padding, for Start or End, or Center
        freePadding = 0.0;
        start = freePadding + _maxLength - length;
        end = freePadding + _maxLength;
        _totalPositionedLengthIncludesPadding = _maxLength + freePadding;
        break;
    }

    return util_dart.LineSegment(start, end);
  }

  /// Calculates offset at the start of each length segment, for [Packing.tight].
  ///
  /// Needed to set [totalPositionedLengthIncludesPadding] every time this is called for each child.
  /// Value of last child sticks.
  _StartAndRightPad _tightStartOffset(bool isFirstLength) {
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
    return _StartAndRightPad(startOffset, freePaddingRight);
  }

  /// Calculates offset at the start of each length segment, for [Packing.loose].
  ///
  /// Needed to set [totalPositionedLengthIncludesPadding] every time this is called for each child.
  /// Value of last child sticks.
  _StartAndRightPad _looseStartOffset(bool isFirstLength) {
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
    return _StartAndRightPad(startOffset, freePaddingRight);
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

class _StartAndRightPad {

  _StartAndRightPad(
    this.startOffset,
    this.freePaddingRight
  );

  final double startOffset;
  final double freePaddingRight;

}

/// A value class which holds on the result of invocation
/// of the 1-dimensional layouter [LayedoutLengthsPositioner.positionLengths].
///
/// It's members and what each holds on:
///   - [lineSegments] is a list of [util_dart.LineSegment]s that have been positioned
///     by [LayedoutLengthsPositioner.positionLengths] from [LayedoutLengthsPositioner.lengths] leading to this object.
///     Each line segment in [lineSegments] has a min and max (start and end), where
///     the [LayedoutLengthsPositioner.positionLengths] positioned them; the min and max values are
///     starting at 0.0 and ending at or before [totalPositionedLengthIncludesPadding].
///     If [totalPositionedLengthIncludesPadding] ended up greater than [LayedoutLengthsPositioner.lengthsConstraints]
///     then [isOverflown] was set to true.
///   - [totalPositionedLengthIncludesPadding] is the total length managed by the [LayedoutLengthsPositioner] during
///     [LayedoutLengthsPositioner.positionLengths].
///   - [isOverflown] is set to true if the [totalPositionedLengthIncludesPadding] needed
///     was larger then [LayedoutLengthsPositioner._lengthsConstraint]. It is only a marker that the process that
///     lead to layout overflew it's constraints.
///
/// The clients of this object usually use this object to convert the member [lineSegments]
/// to one side of a rectangle along the axis corresponding to children (future) positions.
///
/// Note: on creation, it should be passed segments [lineSegments] already
///       layed out to their positions with [LayedoutLengthsPositioner.positionLengths]
///       and [totalPositionedLengthIncludesPadding]
///       calculated by [LayedoutLengthsPositioner.totalPositionedLengthIncludesPadding],
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
  /// todo-011-simplify : Not used in anything in layout, only in test. Consider removal
  final double totalPositionedLengthIncludesPadding;
  /// A marker that the process that lead to layout, the [LayedoutLengthsPositioner.positionLengths]
  /// overflew it's original constraints given in [LayedoutLengthsPositioner._lengthsConstraint].
  ///
  /// It can be used by clients to deal with overflow by a warning or painting a yellow rectangle.
  final bool isOverflown;

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

    // Dart knows other is PositionedLineSegments, but for clarity:
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
