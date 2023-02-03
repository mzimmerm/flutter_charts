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

import 'test/generate_test_data_from_app_runs.dart';

/// A minimal polynomial needed for Y label and axis scaling.
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

// todo 0 add tests; also make constant; also add validation for min before max
// todo-2: replaced num with double,  parametrize with T instead so it works for both

class Interval {
  const Interval(this.min, this.max, [this.includesMin = true, this.includesMax = true]);

  final double min;
  final double max;
  final bool includesMin;
  final bool includesMax;

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

  /// Outermost union of this interval with [other].
  Interval merge(Interval other) {
    return Interval(math.min(min, other.min), math.max(max, other.max));
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

/// Encapsulates the concept of linear transformations in 1D.
///
/// The unnamed generative constructor [LinearTransform1D] creates a transformation which,
/// applied on a value, first scales the value by the scaling factor is [_scaleBy],
/// then translates by the translation amount is [_translateBy].
///
/// The application of the transform on a double value is performed by the [apply] method.
/// 
/// Note: The atomic transformation actions we can do in 1D are:
///   - Multiplicative scaling (stretching or compression) around origin, with origin the fixed point.
///     The scaling factor is [_scaleBy]. Note that scaling by [_scaleBy] = -1.0 is equivalent to
///     reversing direction.
///   - Additive translation (moving along) (no fixed point).
///     The translation amount is [_translateBy].
///   - Multiplicative reversing direction (flipping around origin), with origin the fixed point.
///     This is the same as scaling by -1 (as noted above).
///
/// Commutation notes:
///   - any combination of scaling and inversion commute (scale1, scale2), (scale, inverse), (inverse1, inverse2). This is a consequence of multiplication being commutative
///   - any combination of translations commute
///   - any other combination (that is, with translate) does NOT commute.

class LinearTransform1D {
  final double _scaleBy;
  final double _translateBy;

  const LinearTransform1D({
    required scaleBy,
    required translateBy,
  }) : _scaleBy = scaleBy, _translateBy = translateBy;

  /// Constructs transformation which scales (stretches or compresses),
  /// all points on the axis with origin as the fixed point, by the multiplying [_scaleBy] factor.
  const LinearTransform1D.scaleAtOrigin({
    required scaleBy,
  }) : this(scaleBy: scaleBy, translateBy: 0.0,);

  /// Constructs transformation which transforms (moves)
  /// all points on the axis with origin as the fixed point by the additive [_translateBy] value.
  ///
  /// This transform has no fixed point (so no 'origin' in the name).
  const LinearTransform1D.translateAtOrigin({
    required translateBy,
  }) : this(scaleBy: 1.0, translateBy: translateBy,);

  /// Constructs transformation which inverts (flips, reverses),
  /// all points on the axis with origin as the fixed point.
  ///
  /// This transform is equivalent to
  /// ```
  ///    LinearTransform1D.scaleAtOrigin(-1.0)
  /// ```
  const LinearTransform1D.inverse() : this(scaleBy: -1.0, translateBy: 0.0,);


  /// Default transformation first scales, then translates all points.
  ///
  /// Note that scaling may include inversion.
  double apply(double fromValue) {
    return _scaleBy * fromValue - _translateBy;
  }
}

/// A transformation between domains which [apply] method, invoked on a double value
/// assumed to be on the 'from' domain, answers the linearly extrapolated value in the 'to' domain.
///
/// The start and end points on both domains define uniquely (up to a ratio of domain sizes) a linear transform and it's
/// scaleBy and translateBy factors.
///
/// Transforms a value in 'from' domain into a 'linearly correspondent' value in the 'to' domain, assuming
/// the two domains are linearly scaled using a scaling that transforms
/// the [fromDomainStart] to [toDomainStart] and  [fromDomainEnd] to [toDomainEnd]. This defines the
/// scaling factor to be
/// ```
///   (toDomainEnd - toDomainStart) / (fromDomainEnd - fromDomainStart); // this may include inversion if negative
/// ```
/// and the following translation factor to be
/// ```
///   toDomainStart
/// ```
///
class DomainExtrapolation1D {
  const DomainExtrapolation1D({
    required this.fromDomainStart,
    required this.fromDomainEnd,
    required this.toDomainStart,
    required this.toDomainEnd,
  }) : domainStretch = (toDomainEnd - toDomainStart) / (fromDomainEnd - fromDomainStart);

  /// First point of the 'from' domain. If larger than [fromDomainEnd], represents reversed direction.
  final double fromDomainStart;
  final double fromDomainEnd;
  final double toDomainStart;
  final double toDomainEnd;

  final double domainStretch;

  /// Transform [fromValue] from the 'from' domain to it's corresponding linear transform value it the 'to' domain.
  ///
  /// In detail: If [fromValue] is a point's value on the 'from' domain, the point's distances to [fromDomainStart]
  /// and [fromDomainEnd] are at a certain ratio, call it R.
  /// This returns a value of point in the 'to' domain, which ratio of distances to the
  /// [toDomainStart] and [toDomainEnd] is same as R.
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
    double scaled = LinearTransform1D.scaleAtOrigin(scaleBy: domainStretch).apply(fromValue);
    double scaledAndMoved = LinearTransform1D.translateAtOrigin(translateBy: -toDomainStart).apply(scaled);

    double result = domainStretch * (fromValue - fromDomainStart) + toDomainStart;

    assertResultsSame(scaledAndMoved, result);

    return result;
  }

  @override
  String toString() {
    return 'fromDomainStart = $fromDomainStart, '
        'fromDomainEnd = $fromDomainEnd,'
        'toDomainStart   = $toDomainStart,'
        'toDomainEnd   = $toDomainEnd, '
        'domainStretch = $domainStretch';
  }
}

// todo-02 Refactor scaling
/// Scale the [value] that must be from the scale
/// given by [fromDomainMin] - [fromDomainMax]
/// to the "to scale" given by  [toDomainNewMax] - [toDomainNewMin].
///
/// The calculations are rather pig headed and should be made more terse;
/// also could be separated by caching the scales which do not change
/// unless data change.
double scaleValue({
  required double value,
  required double fromDomainMin,
  required double fromDomainMax,
  required double toDomainNewMax,
  required double toDomainNewMin,
}) {
  var fromDomainLength = fromDomainMax - fromDomainMin;
  var toDomainLength = toDomainNewMin - toDomainNewMax;

  // Handle degenerate cases:
  // 1. If exactly one of the scales is zero length, exception.
  if (exactlyOneHasValue(
    one: fromDomainLength,
    two: toDomainLength,
    value: 0.0,
  )) {
    if (fromDomainLength == 0.0 && value == fromDomainMin) {
      // OK to have own scale degenerate, if value is the same as the degenerate min/max
      return toDomainNewMax;
      // all other cases (it is the axisY which is degenerate, or value is outside dataYsEnvelope
    } else {
      throw StateError(
          'Cannot convert value $value between scales $fromDomainMin, $fromDomainMax and $toDomainNewMax $toDomainNewMin');
    }
    // 2. If both scales are zero length:
  } else if (bothHaveValue(
    one: fromDomainLength,
    two: toDomainLength,
    value: 0.0,
  )) {
    // if value != dataYsEnvelopeMin (same as dataYsEnvelopeMax), exception
    if (value != fromDomainMin) {
      throw StateError('Value is not on own scale: $fromDomainMin, $fromDomainMax and $toDomainNewMax $toDomainNewMin');
      //  else return axisYMin (same as axisYMax)
    } else {
      return toDomainNewMax;
    }
  }
  // first move scales to be both starting at 0; also move value equivalently.
  // Naming the 0 based coordinates ending with 0
  double value0 = value - fromDomainMin;
  /*
  double dataYsEnvelopeMin0 = 0.0;
  double dataYsEnvelopeMax0 = fromDomainLength;
  double axisYMin0 = 0.0;
  double axisYMax0 = toDomainLength;
  */

  // Next scale the value to the 0 - 1 segment
  double value0ScaledTo01 = value0 / fromDomainLength;

  // Then scale value0Scaled01 to the 0 based axisY0
  double valueOnAxisY0 = value0ScaledTo01 * toDomainLength;

  // And finally shift the valueOnAxisY0 to a non-0 start on "to scale"

  double scaled = valueOnAxisY0 + toDomainNewMax;

  collectTestData('for_scaleValue_test', [value, fromDomainMin, fromDomainMax, toDomainNewMax, toDomainNewMin], scaled);

  return scaled;
}

/// Returns [true] if exactly one of the passed values [one], [two] hase the passed [value],
/// [false] otherwise.
bool exactlyOneHasValue({
  required double one,
  required double two,
  required double value,
}) {
  return (math.min(one, two) != math.max(one, two) && (one == value || two == value));
}

/// Returns [true] if both of the passed values [one], [two] hase the passed [value],
/// [false] otherwise.
bool bothHaveValue({
  required double one,
  required double two,
  required double value,
}) {
  return math.min(one, two) == value && value == math.max(one, two) && math.min(one, two) == value;
}

double get epsilon => 0.000001;

bool isCloserThanEpsilon(double d1, double d2) {
  if (-epsilon < d1 - d2 && d1 - d2  < epsilon) {
    return true;
  }
  return false;
}

void assertResultsSame(double result, double otherResult) {
  if (!isCloserThanEpsilon(result, otherResult)) {
    throw StateError('Results do not match. Result was $result, '
        'Simple result was $otherResult.');
  }
}

String enumName(Enum e) {
  return e.toString().split('.')[1];
}
