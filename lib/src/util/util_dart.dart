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
import 'test/generate_test_data_from_app_runs.dart';

// todo-13 write test for this and refactor scaling
/// Scale the [value] that must be from the scale
/// given by [fromDomainMin] - [fromDomainMax]
/// to the "to scale" given by  [toDomainMin] - [toDomainMax].
///
/// The calculations are rather pig headed and should be made more terse;
/// also could be separated by caching the scales which do not change
/// unless data change.
double scaleValue({
  required double value,
  required double fromDomainMin,
  required double fromDomainMax,
  required double toDomainMin,
  required double toDomainMax,
}) {

  var fromDomainLength = fromDomainMax - fromDomainMin;
  var toDomainLength = toDomainMax - toDomainMin;
  // Handle degenerate cases:
  // 1. If exactly one of the scales is zero length, exception.
  if (exactlyOneHasValue(
    one: fromDomainLength,
    two: toDomainLength,
    value: 0.0,
  )) {
    if (fromDomainLength == 0.0 && value == fromDomainMin) {
      // OK to have own scale degenerate, if value is the same as the degenerate min/max
      return toDomainMin;
      // all other cases (it is the axisY which is degenerate, or value is outside dataYsEnvelop
    } else {
      throw StateError(
          'Cannot convert value $value between scales $fromDomainMin, $fromDomainMax and $toDomainMin $toDomainMax');
    }
    // 2. If both scales are zero length:
  } else if (bothHaveValue(
    one: fromDomainLength,
    two: toDomainLength,
    value: 0.0,
  )) {
    // if value != dataYsEnvelopMin (same as dataYsEnvelopMax), exception
    if (value != fromDomainMin) {
      throw StateError('Value is not on own scale: $fromDomainMin, $fromDomainMax and $toDomainMin $toDomainMax');
      //  else return axisYMin (same as axisYMax)
    } else {
      return toDomainMin;
    }
  }
  // first move scales to be both starting at 0; also move value equivalently.
  // Naming the 0 based coordinates ending with 0
  double value0 = value - fromDomainMin;
  /*
  double dataYsEnvelopMin0 = 0.0;
  double dataYsEnvelopMax0 = fromDomainLength;
  double axisYMin0 = 0.0;
  double axisYMax0 = toDomainLength;
  */

  // Next scale the value to the 0 - 1 segment
  double value0ScaledTo01 = value0 / fromDomainLength;

  // Then scale value0Scaled01 to the 0 based axisY0
  double valueOnAxisY0 = value0ScaledTo01 * toDomainLength;

  // And finally shift the valueOnAxisY0 to a non-0 start on "to scale"

  double scaled = valueOnAxisY0 + toDomainMin;

  // todo-00-last-last remove when done 
  collectTestData('for_scaleValue_test', [value, fromDomainMin, fromDomainMax, toDomainMin, toDomainMax], scaled);
  
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

/* todo-13-make-transpose-generics : original version before nullability
List<List<T>> transpose<T>(List<List<T>> colsInRows) {
  int nRows = colsInRows.length;
  if (colsInRows.length == 0) return colsInRows;

  int nCols = colsInRows[0].length;
  if (nCols == 0) throw new StateError("Degenerate matrix");

  // Init the transpose to make sure the size is right
  List<List<T>> rowsInCols = new List(nCols);
  for (int col = 0; col < nCols; col++) {
    rowsInCols[col] = new List(nRows);
  }

  // Transpose
  for (int row = 0; row < nRows; row++) {
    for (int col = 0; col < nCols; col++) {
      rowsInCols[col][row] = colsInRows[row][col];
    }
  }
  return rowsInCols;
}
*/

double get epsilon => 0.000001;

String enumName(Enum e) {
  return e.toString().split('.')[1];
}
