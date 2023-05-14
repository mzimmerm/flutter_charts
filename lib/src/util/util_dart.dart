/// Utility that contain only Dart code and do NOT import 'dart:ui' or anything Flutter.
/// Reason: If a test or a main file depends on flutter or dart:ui, you need to use flutter test, not dart or pub commands,
/// otherwise a run such as
///    dart run something_with_main.dart
///    dart test some_test.dart
/// causes
///    Error: Not found: 'dart:ui'
/// This behavior feels like a bug rather than intention. Dart:ui is still Dart!
///
// todo 1 - Functions here should eventually be held by a Utility class

import 'dart:math' as math;
import 'package:decimal/decimal.dart' as decimal;

/// A minimal polynomial needed for Y label and axis extrapolating.
///
/// Not fully a polynomial. Uses the [decimal] package.
class Poly {
  // ### members

  final decimal.Decimal _dec;
  final decimal.Decimal _one;
  final decimal.Decimal _ten;
  final decimal.Decimal _zero;

  // ### constructors

  /// Create
  Poly({required num from})
      : _dec = dec(from.toString()),
        _one = numToDec(1),
        // 1.0
        _ten = numToDec(10),
        _zero = numToDec(0);

  // ### methods

  static decimal.Decimal dec(String value) => decimal.Decimal.parse(value);

  static decimal.Decimal numToDec(num value) => dec(value.toString());

  int get signum => _dec.signum;

  int get fractLen => _dec.scale;

  int get totalLen => _dec.precision;

  int get coefficientAtMaxPower =>
      (_dec.abs() / numToDec(math.pow(10, maxPower))).floor().toInt();

  int get floorAtMaxPower => (numToDec(coefficientAtMaxPower) * numToDec(math.pow(10, maxPower)))
      .floor()
      .toDouble()
      .toInt();

  int get ceilAtMaxPower => ((numToDec(coefficientAtMaxPower) + dec('1')) * numToDec(math.pow(10, maxPower)))
      .floor()
      .toDouble()
      .toInt();

  /// Position of first significant non zero digit.
  ///
  /// Calculated by starting from 0 at the decimal point, first to the left,
  /// if no non zero is find on the left, then to the right.
  ///
  /// Zeros (0, 0.0 +-0.0 etc) are the only numbers where [maxPower] is 0.
  ///
  int get maxPower {
    if (_dec == _zero) {
      return 0;
    }
    // Power calcs should be done on positives due to the algorithm
    decimal.Decimal decAbs = _dec.abs();
    if (decAbs < _one) {
      // pure fraction
      // multiply by 10 till >= 1.0 (not pure fraction)
      return _ltOnePower(decAbs);
    }
    return totalLen - fractLen - 1;
  }

/*
  int get maxPower {
    if (totalLen == fractLen) {
      // pure fraction
      // multiply by 10 till >= 1.0 (not pure fraction)
      return _ltOnePower(_dec);
    }
    return totalLen - fractLen - 1;
  }
*/

  int _ltOnePower(decimal.Decimal tester) {
    if (tester >= _one) throw Exception('$tester Failed: tester < 1.0');
    int power = 0;
    while (tester < _one) {
      tester = tester * _ten;
      power -= 1; // power = -1, -2, etc
    }
    return power;
  }
}

// todo-020: multiple things:
//    - replace num with double,  parametrize with T instead so it works for both
//    - make const constructor
//    - add tests
//    - add (optional?) validation for min < max

class Interval {
  const Interval(this.min, this.max, [this.includesMin = true, this.includesMax = true]);

  Interval.from(Interval other) : this(other.min, other.max);

  final double min;
  final double max;
  final bool includesMin;
  final bool includesMax;

  double get length {

    if ( min > max) {
      throw StateError('Interval min is after max in $this');
    }
    return max - min;
  }

  double get center => (max + min) / 2;

  bool includes(num comparable) {
    // before - read as: if negative, true, if zero test for includes, if positive, false.
    int beforeMin = comparable.compareTo(min);
    int beforeMax = comparable.compareTo(max);

    // Hopefully these complications gain some minor speed,
    // dealing with the obvious cases first.
    if (beforeMin < 0 || beforeMax > 0) return false;
    if (beforeMin > 0 && beforeMax < 0) return true;
    if (beforeMin == 0 && includesMin) return true;
    if (beforeMax == 0 && includesMax) return true;

    return false;
  }

  bool isIntersects(Interval other) {
    return includes(other.min) || includes(other.max);
  }

  bool isAcrossZero() {
    return (min < 0.0 && max > 0.0);
  }

  /// Returns [true] if the passed [other] is inside self.
  bool containsFully(Interval other) {
    return includes(other.min) && includes(other.max);
  }

  /// Outermost union of this interval with [other].
  Interval merge(Interval other) {
    return Interval(math.min(min, other.min), math.max(max, other.max));
  }

  Interval envelope(List<Interval> otherIntervals) => otherIntervals.isNotEmpty
      ? otherIntervals.fold(this, (previousInterval, interval) => previousInterval.merge(interval))
      : this;

  /// Calculates portion of the length in the positive values.
  ///
  /// Result is always in interval <0.0, 1.0>.
  ///
  /// 0.0 value represents there are only negative values,
  /// 1.0 represents there are only positive or zero values.
  ///
  /// Motivation: Used during affmap related to data ranges.
  double ratioOfPositivePortion() {
    if (min >= max) {
      // Arbitrary portion if interval is collapsed
      if (max < 0.0) {
        return 0.0;
      } else if (max >= 0.0) {
        return 1.0;
      }
      throw StateError('Invalid interval=$this');
    }

    if (max <= 0.0) {
      // dataRange negative or 0
      return 0.0;
    } else if (min >= 0.0) {
      // dataRange purely positive or 0
      return 1.0;
    }

    assert(min < 0.0 && 0.0 < max);

    // Here min < 0.0 && 0.0 < max
    return max / (max - min);
  }

  /// Calculates portion of the length in the negative values.
  ///
  /// Result is always in interval <0.0, 1.0>.
  ///
  /// Same as the remainder to 1.0 of [ratioOfPositivePortion]. See [ratioOfPositivePortion] for details.
  double ratioOfNegativePortion() {
    return 1.0 - ratioOfPositivePortion();
  }

  double ratioOfAnySignPortion() {
    return 1.0;
  }

  /// If this [Interval] intersects with the passed [other] interval,
  /// returns a new interval which is an intersection of this interval with the passed interval;
  /// Otherwise, returns an Interval which is collapsed on the single point of my range, specified
  /// by [orPosition].
  Interval intersectionOr(Interval other, LineSegmentPosition orPosition,) {
    if (!isIntersects(other)) {
      switch (orPosition) {
        case LineSegmentPosition.min:
          return Interval(min, min);
        case LineSegmentPosition.max:
          return Interval(max, max);
        case LineSegmentPosition.center:
          return Interval(center, center);
      }
    }
    // There is an intersection
    return Interval(math.max(min, other.min), math.min(max, other.max));
  }

  Interval intersectionOrException(Interval other) {
    if (!isIntersects(other)) {
      throw StateError('Intervals this=$this and other=$other do not intersect');
    }
    // There is an intersection
    return Interval(math.max(min, other.min), math.min(max, other.max));
  }
  Interval get positivePortionOrException => intersectionOrException(const Interval(0.0, double.infinity));
  Interval get negativePortionOrException => intersectionOrException(const Interval(double.negativeInfinity, 0.0));

  Interval portionForSignOfValue(double value) {
    if (value < 0.0) {
      return negativePortionOrException;
    }
    return positivePortionOrException;
  }

  /// Assumes other starts at 0.0
  Interval portionOfIntervalAsMyPosNegRatio(Interval other, double value) {
    assert (other.min == 0.0);
    assert (length > 0.0);
    if (value < 0.0) {
      return Interval(other.min, other.max * (negativePortionOrException.length / length));
    }
    return Interval(other.min, other.max * (positivePortionOrException.length / length));
  }

  @override
  String toString() {
    return 'Interval($min, $max)';
  }

  @override
  bool operator ==(Object other) {
    bool typeSame = other is Interval &&
        other.runtimeType == runtimeType;
    if (!typeSame) {
      return false;
    }

    // now Dart knows other is LayedOutLineSegments, but for clarity:
    Interval otherInterval = other;
    
    return (min == otherInterval.min && 
        max == otherInterval.max && 
        includesMin == otherInterval.includesMin &&
        includesMax == otherInterval.includesMax);
  }

  @override
  int get hashCode {
    return min.hashCode + 13*max.hashCode + 17*includesMin.hashCode + 23*includesMax.hashCode;
  }

  /// Present itself as code
  String asCodeConstructor() {
    return 'const Interval($min, $max)';
  }

}

class LineSegment extends Interval {
  const LineSegment(double min, double max)
      : super(min, max, true, false);

  LineSegment clone() {
    return LineSegment(min, max);
  }
}


/// Position in [LineSegment].
enum LineSegmentPosition {
  min,
  center,
  max,
}


/// Encapsulates the concept of affine map in 1D.
///
/// The unnamed generative constructor [AffineMap1D] creates a transformation which,
/// applied on a value, first extrapolates the value by the factor [_scaleBy],
/// then translates by the translation amount is [_moveOriginBy].
///
/// The application of the transform on a double value is performed by the [apply] method.
///
/// Note: The atomic transformation actions we can do in 1D are:
///   - Multiplicative extrapolating (stretching or compression) around origin, with origin the fixed point.
///     The scaling factor is [_scaleBy]. Note that scaling by [_scaleBy] = -1.0 is equivalent to
///     reversing direction.
///   - Additive translation (moving along) (no fixed point).
///     The translation amount is [_moveOriginBy].
///   - Multiplicative reversing direction (flipping around origin), with origin the fixed point.
///     This is the same as scaling by -1 (as noted above).
///
/// Commutation notes:
///   - any combination of scaling and inversion commute:  (scale1, scale2), (scale, inverse), (inverse1, inverse2).
///      This is a consequence of multiplication being commutative
///   - any combination of translations commute
///   - any other combination (that is, with translate) does NOT commute.
class AffineMap1D {
  final double _scaleBy;
  final double _moveOriginBy;

  const AffineMap1D({
    required scaleBy,
    required moveOriginBy,
  }) : _scaleBy = scaleBy, _moveOriginBy = moveOriginBy;

  /// Constructs transformation which scales (stretches or compresses),
  /// all points on the axis by the multiplying [scaleBy] factor.
  ///
  /// Origin (double 0.0) is the fixed point, of [scaleAtOrigin].
  const AffineMap1D.scaleAtOrigin({
    required scaleBy,
  }) : this(scaleBy: scaleBy, moveOriginBy: 0.0,);

  /// Constructs transformation which transforms (moves)
  /// all points on the axis with origin as the fixed point by the additive [_moveOriginBy] value.
  ///
  /// This transform has no fixed point (so no 'origin' in the name).
  const AffineMap1D.moveOriginBy({
    required moveAmount,
  }) : this(scaleBy: 1.0, moveOriginBy: moveAmount,);

  /// Constructs transformation which inverts (flips, reverses),
  /// all points on the axis with origin as the fixed point.
  ///
  /// This is a linear transform, which [apply] flips values around origin.
  ///
  const AffineMap1D.inverse() : this(scaleBy: -1.0, moveOriginBy: 0.0,);


  /// Default transformation first scales, then translates the passed [fromValue].
  ///
  /// Equivalent to scaling the coordinate system by [_scaleBy],
  /// then translating (moving) origin by [_moveOriginBy].
  ///
  /// Note that extrapolating may include inversion during scaling.
  double apply(double fromValue) {
    return _scaleBy * fromValue - _moveOriginBy;
  }
}

/// Affine map in 1D that transforms a value in the 'from' range to
/// a value in the 'to' range, so that the start and end points of the from/to ranges map to each other
/// (start to start, end to end).
/// 
/// The mapping is a combination of
///   - translation (move) of origin in the 'from' range by [_fromMoveOriginBy]
///   - followed with linear stretching by [_rangeScale]
///   - followed by translation (move) of origin in the in the 'to' range by  [_toMoveOriginBy]
///
/// Both the stretching factor and move factors are determined
/// by the starts and ends of the 'from' and 'to' ranges,
///   - [_fromRangeStart]
///   - [_fromRangeEnd]
///   - [_toRangeStart]
///   - [_toRangeEnd]
/// as follows:
///   - [_rangeScale] = ([_toRangeEnd] - [_toRangeStart]) / ([_fromRangeEnd] - [_fromRangeStart])
///   - [_fromMoveOriginBy] = [_fromRangeStart]
///   - [_toMoveOriginBy] = -1 * [_toRangeStart]
///
/// A few obvious notes:
///   - stretching includes inversion of axis if  [_rangeScale] is negative.
///   - the move factors have inverse signs of the range start points in the 'from' and 'to' ranges.
///
/// The [apply] method, invoked on a double value in the 'from' range,
/// performs the affine mapping, and answers a the value
/// in the 'to' range which is stretched by the [_rangeScale].
///
/// Preconditions:
///   - ```dart
///      (fromRangeStart != fromRangeEnd && toRangeStart != toRangeEnd) == true;
///      ```
///
/// Notes:
///   - This does not extend [AffineMap1D]; however, any [AffineRangedMap1D]
///     can be replaced with three suitably chosen [AffineMap1D] applied consequently.
///   - AffineRangedMap1D (ARM)
///
///     - ARM definition:
///              ```
///              Given: rangeScale = s = (_toRangeEnd - _toRangeStart) / (_fromRangeEnd - _fromRangeStart)
///                     toValue = ARM(fromValue) = _rangeScale * (fromValue - _fromRangeStart) + _toRangeStart;
///              (1) s  = (te - ts) / (fe - fs);      // just a short form
///              (2) tv = ARM(fv) = s*(fv - fs) + ts; // just a short form
///              ```
///     - Facts about ARM be shown by using the above definition:
///
///       - Lemma 1 : 'affinity lemma' : ARM is an affine transform but NOT a linear transform (only showing this):
///              ```
///              ARM(fv1) + ARM(fv2) = s*(fv1 - fs) + ts + s*(fv2 - fs) + ts = [s*((fv1 + fv2)) - fs) + ts] - s*fs + ts
///                             = ARM(fv1 + fv2) - s*fs + ts != ARM(fv1 + fv2)
///              ```
///       - Lemma 2 : 'inverse lemma' : ARM has an inverse, call in ARI,  ARI(tv) = fv, with the following formula:
///             ```
///               (2)     ((tv - ts) / s) + fs = fv
///                 we can show (2) is true
///                 Proof:
///                 ((tv - ts) / s) + fs = .. subs tv from (2), definition of ARM .. = ((s*(fv-fs) + ts -ts) / s + fs
///                 = s*(fv-fs)/s + fs = (fv-fs) + fs = fv QED
///             ```
///       - Lemma 3 : 'fixed points lemma' : ARM has start and end points fixed - they map into each other.
///              ```
///                (3) ARM(fromStart) = ARM(fs) = s*(fs-fs) + ts = ts = toStart
///                (4) ARM(fromEnd) = ARM(fe) = s*(fe-fs) + ts = .. use (1) subs for s ..
///                             = [(te - ts) / (fe - fs)] * (fe-fs) + ts = (te - ts)  + ts = te QED///              ```
///       - Lemma 4: Taking a point in the middle of the 'from' range
///            (in the geometrical sense, no matter start and end values),
///            is transformed to the middle of the 'to' range, in the same geometrical sense.
///
///            More precisely:
///            ```
///              ARM(1/2 (fromStart + fromEnd)) == 1/2 * (toStart + toEnd)
///            ```
///
///            Note: Lemma is a consequence of definition of ARM, via Lemma 1 and Lemma 2
///
///              Proof of Lemma: For x = 1/2 (fromStart + fromEnd):
///              ```
///                ARM(x) = ARM(1/2 (fromStart + fromEnd))  = // Use Lemma 1, linearity
///                  1/2 * (ARM(fromStart) + ARM(fromEnd)) =  // Use Lemma 2, fixed points
///                  1/2 * (toStart + toEnd)
///              ```
/// Later: Extend from [AffineMap1D]. Also remove _rangeScale, this is parent _scaleBy
class AffineRangedMap1D {
  AffineRangedMap1D({
    required double fromRangeStart,
    required double fromRangeEnd,
    required double toRangeStart,
    required double toRangeEnd,
  })
      :
        // Allow the TO range to be collapsed, but not the FROM range, which is in denominator -
        //  RangeExtrapolation1D.apply would not be a function.
        assert (fromRangeStart != fromRangeEnd),
        _fromRangeStart = fromRangeStart,
        _fromRangeEnd = fromRangeEnd,
        _toRangeStart = toRangeStart,
        _toRangeEnd = toRangeEnd,
        _rangeScale = (toRangeEnd - toRangeStart) / (fromRangeEnd - fromRangeStart),
        _fromMoveOriginBy = fromRangeStart,
        _toMoveOriginBy = -1 * toRangeStart {
    if (isCloserThanEpsilon(toRangeStart, toRangeEnd)) {
      print( ' ### Log.Info: to range is collapsed or closer than epsilon: '
          'toRangeStart $_toRangeStart == toRangeEnd = $_toRangeEnd');
    }
  }

  /// First point of the 'from' range. If larger than [_fromRangeEnd], represents reversed direction.
  final double _fromRangeStart;
  final double _fromRangeEnd;
  final double _toRangeStart;
  final double _toRangeEnd;

  /// This is the scaling factor, equivalent to [AffineMap1D._scaleBy].
  final double _rangeScale;
  /// 'from' range is translated by moving origin by this number;
  /// this causes `value` in 'from' range to be `value - _fromMoveOriginBy` in 'to' range.
  final double _fromMoveOriginBy;
  final double _toMoveOriginBy;

  /// Transform [fromValue] from the 'from' range to the 'to' range.
  ///
  /// In detail: If [fromValue] is a point's value on the 'from' range, the point's distances to [_fromRangeStart]
  /// and [_fromRangeEnd] are at a certain ratio, call it R.
  /// [apply] returns a value of point in the 'to' range, which ratio of distances to the
  /// [_toRangeStart] and [_toRangeEnd] is same as R.
  ///
  /// This transform includes scaling the segment of positive length [fromValue] - [_fromRangeStart],
  /// stretching it by the positive [_rangeScale] THEN adding the result to [_toRangeStart].
  ///
  /// Note: The context of use is a chart situation where the 'from' range is the interval of values we want to display,
  ///       and the 'to' range is the downwards oriented Y pixel axis on screen (0 on top)
  ///       on which we want for display the values. The term 'pixels' in the 'to range'
  ///       reflects the predominant use of this method in this application.
  ///
  double apply(double fromValue) {
    double result = _rangeScale * (fromValue - _fromRangeStart) + _toRangeStart;

    return result;

    /* KEEP
    double movedInFrom = AffineMap1D.moveOriginBy(moveAmount: _fromRangeStart).apply(fromValue);
    double scaled = AffineMap1D.scaleAtOrigin(scaleBy: _rangeScale).apply(movedInFrom);
    double scaledAndMovedInTo = AffineMap1D.moveOriginBy(moveAmount: -1 * _toRangeStart).apply(scaled);

    double result = _rangeScale * (fromValue - _fromRangeStart) + _toRangeStart;

    assertDoubleResultsSame(
      scaledAndMovedInTo,
      result,
      'in caller $this: fromValue=$fromValue, _rangeScale=$_rangeScale, '
          'scaled=$scaled, scaledAndMoved=$scaledAndMovedInTo',
    );
    */

  }

  /// Returns the size of a segment in the 'to' range
  /// scaled from a segment with [length] size in the 'from' range.
  ///
  /// This method's name, [applyOnlyLinearScale], and the parameter name, 'length', is used to express
  /// the main use context of this method: It should be used in situations where we only care about
  /// the linear length change between the value range and the pixel range, not about the affine change in position.
  ///
  /// Negative lengths are supported. Direction matters - that means, a segment of a positive length can
  /// turn into a negative length. if the [_rangeScale] is negative (this means inverted range directions).
  double applyOnlyLinearScale(double length) {
    return length * _rangeScale;
  }

  @override
  String toString() {
    return '_fromRangeStart = $_fromRangeStart, '
        '_fromRangeEnd = $_fromRangeEnd,'
        '_toRangeStart   = $_toRangeStart,'
        '_toRangeEnd   = $_toRangeEnd, '
        '_rangeScale = $_rangeScale'
        '_fromRangeTranslateBy = $_fromMoveOriginBy'
        '_tomRangeTranslateBy = $_toMoveOriginBy'
    ;
  }
}

/// Extension of [AffineRangedMap1D] which makes the assumption that both 'from' range
/// and 'to' range are in the same direction, in the sense that
///
///   ```dart
///    (fromValuesMin < fromValuesMax && toPixelsMin < toPixelsMax) == true;
///   ```
/// which is also the precondition.
///
/// Exists solely for reading clarity when used in an application that needs to
/// extrapolate data values to pixels, to be clear which parameters ore values and which are pixels.
///
/// However, it also provides ability to invert the extrapolation, by setting [isFlipToRange] to true,
/// which causes the extrapolation to behave as if
///   ```dart
///    (toPixelsMin > toPixelsMax) == true; // Note min is GREATER than max
///   ```
///
///  [isFlipToRange] default is [false]. Setting [isFlipToRange] to [true] is useful
///  if the 'to' range represents the Y axis and  we are *extrapolating data values*,
///  as smaller data values end up showing on larger pixel values.
///  However, when we are *extrapolating sizes* (which is technically *scaling sizes*),
///  we generally stay with the [isFlipToRange] default [false],
///  as we normally want sizes positive after extrapolation.
///
/// todo-014 : try to make all 1D constructors const.
class ToPixelsAffineMap1D extends AffineRangedMap1D {

  ToPixelsAffineMap1D({
    required Interval fromValuesRange,
    required Interval toPixelsRange,
    this.isFlipToRange = false,
  }) : super(
    fromRangeStart: fromValuesRange.min,
    fromRangeEnd: fromValuesRange.max,
    toRangeStart: isFlipToRange ? toPixelsRange.max : toPixelsRange.min,
    toRangeEnd: isFlipToRange ? toPixelsRange.min : toPixelsRange.max,
  ) {
    assert(fromValuesRange.min < fromValuesRange.max && toPixelsRange.min <= toPixelsRange.max);
    
    // Allow the TO pixels range to be collapsed, but not the FROM values range, which is in the denominator of [_scaleBy] in super.
    if (!(fromValuesRange.min < fromValuesRange.max)) {
      throw StateError('$runtimeType: fromValues.min=$fromValuesRange.min < fromValues.max=$fromValuesRange.max NOT true on $this.');
    }
    if (!(toPixelsRange.min <= toPixelsRange.max)) {
      throw StateError('$runtimeType: toPixels.min=$toPixelsRange.min <= toPixels.max=$toPixelsRange.max NOT true on $this.');
    }
    if (toPixelsRange.min == toPixelsRange.max)  {
      print(' ### Log.Info: $runtimeType: TO range is COLLAPSED: '
          'toPixels.min=$toPixelsRange.min == toPixels.max=$toPixelsRange.max TRUE on $this.');
    }

  }

  /// Explicitly invert ranges, which are assumed in the same direction,
  /// due to the precondition `fromValues.min < fromValues.max && toPixels.min <= toPixels.max`
  final bool isFlipToRange;

  @override
  String toString() {
    return '${super.toString()}, isFlipToRange=$isFlipToRange';
  }
}

// ################ Functions ########################

/// Transposes, as if across it's [Diagonal.leftToRightUp],
/// the data rows 2D array List<List<Object>>, so that
/// for each row and column index in valid range,
/// ```dart
///   dataRows[row][column] = transposed[column][row];
/// ```
/// The original and transposed example
/// ```
///  // original
///  [
///    [ 1, A ],
///    [ 2, B ],
///    [ 3, C ],
///  ]
///  // transposed
///  [
///    [ 1, 2, 3 ],
///    [ A, B, C ],
///  ]
/// ```
List<List<T>> transposeRowsToColumns<T>(List<List<T>> rows) {
  List<List<T>> columns = [];
  // Walk length of first row (if exists) and fill all columns assuming fixed size of [ChartMode.dataRows]
  if (rows.isNotEmpty) {
    for (int column = 0; column < rows[0].length; column++) {
      List<T> dataColumn = [];
      for (int row = 0; row < rows.length; row++) {
        // Add a row value on the row where dataColumn stands
        dataColumn.add(rows[row][column]);
      }
      columns.add(dataColumn);
    }
  }
  return columns;
}

double get epsilon => 0.000001;

bool isCloserThanEpsilon(double d1, double d2) {
  if (-epsilon < d1 - d2 && d1 - d2  < epsilon) {
    return true;
  }
  return false;
}

void assertDoubleResultsSame(double result, double otherResult, [String callerMessage = '']) {
  if (!isCloserThanEpsilon(result, otherResult)) {
    throw StateError('Double results do not match. Result was $result, other result was $otherResult.\n'
        'Caller message: $callerMessage');
  }
}

String enumName(Enum e) {
  return e.toString().split('.')[1];
}
