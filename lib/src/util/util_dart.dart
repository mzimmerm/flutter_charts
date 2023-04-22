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

// import 'test/generate_test_data_from_app_runs.dart';

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
  /// Motivation: Used during lextr related to data ranges.
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


/// Encapsulates the concept of linear transformations in 1D.
///
/// The unnamed generative constructor [LTransform1D] creates a transformation which,
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
///   - any combination of scaling and inversion commute (scale1, scale2), (scale, inverse), (inverse1, inverse2). This is a consequence of multiplication being commutative
///   - any combination of translations commute
///   - any other combination (that is, with translate) does NOT commute.
/// todo-013 : Add tests for easier refactoring
class LTransform1D {
  final double _scaleBy;
  final double _moveOriginBy;

  const LTransform1D({
    required scaleBy,
    required moveOriginBy,
  }) : _scaleBy = scaleBy, _moveOriginBy = moveOriginBy;

  /// Constructs transformation which scales (stretches or compresses),
  /// all points on the axis by the multiplying [_scaleBy] factor.
  ///
  /// Origin (double 0.0) is the fixed point, of [scaleAtOrigin].
  const LTransform1D.scaleAtOrigin({
    required scaleBy,
  }) : this(scaleBy: scaleBy, moveOriginBy: 0.0,);

  /// Constructs transformation which transforms (moves)
  /// all points on the axis with origin as the fixed point by the additive [_moveOriginBy] value.
  ///
  /// This transform has no fixed point (so no 'origin' in the name).
  const LTransform1D.moveOriginBy({
    required moveAmount,
  }) : this(scaleBy: 1.0, moveOriginBy: moveAmount,);

  /// Constructs transformation which inverts (flips, reverses),
  /// all points on the axis with origin as the fixed point.
  ///
  /// This transform is equivalent to
  /// ```
  ///    LinearTransform1D.scaleAtOrigin(-1.0)
  /// ```
  const LTransform1D.inverse() : this(scaleBy: -1.0, moveOriginBy: 0.0,);


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

/// A linear transformation in 1D that linearly extrapolates a value in the 'from' domain to
/// a value in the 'to' domain.
///
/// The extrapolation is a combination of
///   - translation (move) of origin in the 'from' domain by [_fromMoveOriginBy]
///   - followed by linear stretching by [_domainStretch]
///   - followed by translation (move) of origin in the in the 'to' domain by  [_toMoveOriginBy]
///
/// Both the stretching factor and move factors are determined
/// by the starts and ends of the 'from' and 'to' domains,
///   - [_fromDomainStart]
///   - [_fromDomainEnd]
///   - [_toDomainStart]
///   - [_toDomainEnd]
/// as follows:
///   - [_domainStretch] = ([_toDomainEnd] - [_toDomainStart]) / ([_fromDomainEnd] - [_fromDomainStart])
///   - [_fromMoveOriginBy] = [_fromDomainStart]
///   - [_toMoveOriginBy] = -1 * [_toDomainStart]
///
/// Note that the stretching includes inversion of axis if  [_domainStretch] is negative.
/// Also note how the move factors are inverse signs of the start points in the 'from' and 'to' domains.
///
/// The [apply] method, invoked on a double value in the 'from' domain,
/// performs the extrapolation, and answers a the linearly extrapolated value
/// in the 'to' domain which is stretched by the [_domainStretch].
///
/// Preconditions:
///   - ```dart
///      (fromDomainStart != fromDomainEnd && toDomainStart != toDomainEnd) == true;
///      ```
///
/// Notes:
///   - This does not extend [LTransform1D]; however, any [DomainLTransform1D]
///     can be replaced with two suitably chosen [LTransform1D] applied consequently.
///   - DomainLTransform1D (DLT)
///
///     - DLT definition:
///              ```
///              Given: domainStretch = (_toDomainEnd - _toDomainStart) / (_fromDomainEnd - _fromDomainStart)
///              DLT(fromValue) = _domainStretch * (fromValue - _fromDomainStart) + _toDomainStart;
///              ```
///
///     - Facts about DLT be shown by using the above definition:
///
///       - Lemma 1 : 'linearity lemma' : DLT is a linear transform
///              ```
///              DLT(A * (a1 + a2)) == A * (DLT(a1) + DLT(a2))
///              ```
///          - Easy to prove by substituting A, a1, a2 to the DLT definition
///
///       - Lemma 2 : 'fixed points lemma' : DLT has start and end points fixed - they map into each other.
///              ```
///                // 'fixed points lemma'
///                DLT(fromStart) == toStart
///                DLT(fromEnd) == toEnd
///              ```
///          - Easy to prove by substituting start and end to the DLT definition
///          - Lemma 2 'fixed points lemma' is NOT a consequence of linearity, but a consequence of the DLT definition.
///
///       - Lemma: Taking a point in the middle of the 'from' domain
///            (in the geometrical sense, no matter start and end values),
///            is transformed to the middle of the 'to' domain, in the same geometrical sense.
///
///            Lemma, stated formally:
///            ```
///              DLT(1/2 (fromStart + fromEnd)) == 1/2 * (toStart + toEnd)
///            ```
///
///            Note: Lemma is a consequence of definition of DLT, via Lemma 1 and Lemma 2
///
///              Proof of Lemma: For x = 1/2 (fromStart + fromEnd):
///              ```
///                DLT(x) = DLT(1/2 (fromStart + fromEnd))  = // Use Lemma 1, linearity
///                  1/2 * (DLT(fromStart) + DLT(fromEnd)) =  // Use Lemma 2, fixed points
///                  1/2 * (toStart + toEnd)
///              ```
/// todo-013: Add tests, then extend from LTransform1D. Also remove _domainStretch, this is parent _scaleBy
class DomainLTransform1D {
  DomainLTransform1D({
    required double fromDomainStart,
    required double fromDomainEnd,
    required double toDomainStart,
    required double toDomainEnd,
  })
      :
        // Allow the TO domain to be collapsed, but not the FROM domain, which is in denominator -
        //  DomainExtrapolation1D.apply would not be a function.
        assert (fromDomainStart != fromDomainEnd),
        _fromDomainStart = fromDomainStart,
        _fromDomainEnd = fromDomainEnd,
        _toDomainStart = toDomainStart,
        _toDomainEnd = toDomainEnd,
        _domainStretch = (toDomainEnd - toDomainStart) / (fromDomainEnd - fromDomainStart),
        _fromMoveOriginBy = fromDomainStart,
        _toMoveOriginBy = -1 * toDomainStart {
    if (isCloserThanEpsilon(toDomainStart, toDomainEnd)) {
      print( ' ### Log.Info: to domain is collapsed or closer than epsilon: '
          'toDomainStart $_toDomainStart == toDomainEnd = $_toDomainEnd');
    }
  }

  /// First point of the 'from' domain. If larger than [_fromDomainEnd], represents reversed direction.
  final double _fromDomainStart;
  final double _fromDomainEnd;
  final double _toDomainStart;
  final double _toDomainEnd;

  /// This is the scaling factor, equivalent to [LTransform1D._scaleBy].
  final double _domainStretch;
  /// 'from' domain is translated by moving origin by this number;
  /// this causes `value` in 'from' domain to be `value - _fromMoveOriginBy` in 'to' domain.
  final double _fromMoveOriginBy;
  final double _toMoveOriginBy;

  /// Transform [fromValue] from the 'from' domain to it's corresponding linearly
  /// extrapolated value it the 'to' domain.
  ///
  /// In detail: If [fromValue] is a point's value on the 'from' domain, the point's distances to [_fromDomainStart]
  /// and [_fromDomainEnd] are at a certain ratio, call it R.
  /// This returns a value of point in the 'to' domain, which ratio of distances to the
  /// [_toDomainStart] and [_toDomainEnd] is same as R.
  ///
  /// This transform includes BOTH stretching AND translation of origin, in that order
  ///
  /// Note: Assuming 'from' domain is the interval of values we want to display,
  ///       and the 'to' domain is the downwards oriented Y axis on screen (0 on top)
  ///       on which we want for display the values, then:
  ///
  ///       This linearly transforms a point in the 'from' domain, to the point in the 'to' domain.
  ///
  ///       The term 'pixels' in this method name may be misleading, as the 'to' domain does not have to be
  ///       pixels or coordinates on screen, but it does reflect the predominant use of this method in this application.
  ///
  double apply(double fromValue) {
    double movedInFrom = LTransform1D.moveOriginBy(moveAmount: _fromDomainStart).apply(fromValue);
    double scaled = LTransform1D.scaleAtOrigin(scaleBy: _domainStretch).apply(movedInFrom);
    double scaledAndMovedInTo = LTransform1D.moveOriginBy(moveAmount: -1 * _toDomainStart).apply(scaled);

    double result = _domainStretch * (fromValue - _fromDomainStart) + _toDomainStart;

    assertDoubleResultsSame(
      scaledAndMovedInTo,
      result,
      'in caller $this: fromValue=$fromValue, _domainStretch=$_domainStretch, '
          'scaled=$scaled, scaledAndMoved=$scaledAndMovedInTo',
    );

    return result;
  }

  /// Returns the size of a segment in the 'to' domain
  /// scaled from a segment with [length] size in the 'from' domain.
  ///
  /// This method's name, 'applyOnlyScaleOnLength', and the parameter name, 'length', is used to express
  /// the use pattern of this method: It should be used in situations where we only care about
  /// length change between the value domain and the pixel domain, not about change in position.
  ///
  /// Negative lengths are supported. Direction matters - that means, a segment of a positive length can
  /// turn into a negative length. if the [_domainStretch] is negative (this means inverted domain directions).
  double applyOnlyScaleOnLength(double length) {
    return length * _domainStretch;
  }

  @override
  String toString() {
    return '_fromDomainStart = $_fromDomainStart, '
        '_fromDomainEnd = $_fromDomainEnd,'
        '_toDomainStart   = $_toDomainStart,'
        '_toDomainEnd   = $_toDomainEnd, '
        '_domainStretch = $_domainStretch'
        '_fromDomainTranslateBy = $_fromMoveOriginBy'
        '_tomDomainTranslateBy = $_toMoveOriginBy'
    ;
  }
}

/// Extension of [DomainLTransform1D] which makes the assumption that both 'from' domain
/// and 'to' domain are in the same direction, in the sense that
///
///   ```dart
///    (fromValuesMin < fromValuesMax && toPixelsMin < toPixelsMax) == true;
///   ```
/// which is also the precondition.
///
/// Exists solely for reading clarity when used in an application that needs to
/// extrapolate data values to pixels, to be clear which parameters ore values and which are pixels.
///
/// However, it also provides ability to invert the extrapolation, by setting [doInvertToDomain] to true,
/// which causes the extrapolation to behave as if
///   ```dart
///    (toPixelsMin > toPixelsMax) == true; // Note min is GREATER than max
///   ```
///
///  [doInvertToDomain] default is [false]. Setting [doInvertToDomain] to [true] is useful
///  if the 'to' domain represents the Y axis and  we are *extrapolating data values*,
///  as smaller data values end up showing on larger pixel values.
///  However, when we are *extrapolating sizes* (which is technically *scaling sizes*),
///  we generally stay with the [doInvertToDomain] default [false],
///  as we normally want sizes positive after extrapolation.
///
/// todo-010-refactoring (functional) : Refactor throughout to accept Intervals, to explicitly express min < max on both values and pixels.
class ToPixelsLTransform1D extends DomainLTransform1D {
  ToPixelsLTransform1D({
    required double fromValuesMin,
    required double fromValuesMax,
    required double toPixelsMin,
    required double toPixelsMax,
    this.doInvertToDomain = false,
  }) : super(
    fromDomainStart: fromValuesMin,
    fromDomainEnd: fromValuesMax,
    toDomainStart: doInvertToDomain ? toPixelsMax : toPixelsMin,
    toDomainEnd: doInvertToDomain ? toPixelsMin : toPixelsMax,
  ) {
    assert(fromValuesMin < fromValuesMax && toPixelsMin <= toPixelsMax);
    
    // Allow the TO pixels domain to be collapsed, but not the FROM values domain, which is in the denominator of [_scaleBy] in super.
    if (!(fromValuesMin < fromValuesMax)) {
      throw StateError('$runtimeType: fromValuesMin=$fromValuesMin < fromValuesMax=$fromValuesMax NOT true on $this.');
    }
    if (!(toPixelsMin <= toPixelsMax)) {
      throw StateError('$runtimeType: toPixelsMin=$toPixelsMin <= toPixelsMax=$toPixelsMax NOT true on $this.');
    }
    if (toPixelsMin == toPixelsMax)  {
      print(' ### Log.Info: $runtimeType: TO domain is COLLAPSED: '
          'toPixelsMin=$toPixelsMin == toPixelsMax=$toPixelsMax TRUE on $this.');
    }

  }

  /// Explicitly invert domains, which are assumed in the same direction,
  /// due to the precondition `fromValuesMin < fromValuesMax && toPixelsMin <= toPixelsMax`
  final bool doInvertToDomain;

  @override
  String toString() {
    return '${super.toString()}, _doInvertToDomain=$doInvertToDomain';
  }
}


// ################ Functions ########################

/// Transposes, as if across it's top-to-bottom / left-to-right diagonal,
/// the [_valuesRows] 2D array List<List<Object>>, so that
/// for each row and column index in valid range,
/// ```dart
///   _valuesRows[row][column] = transposed[column][row];
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
  // Walk length of first row (if exists) and fill all columns assuming fixed size of _valuesRows
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
