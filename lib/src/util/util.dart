// todo 1 - Functions here should eventually be held by a Utility class

import 'package:flutter_charts/src/chart/container.dart';

/// Scale the [value] that must be from the scale
/// given by [ownScaleMin] - [ownScaleMax]
/// to the "to scale" given by  [toScaleMin] - [toScaleMax].
///
/// The calculations are rather pig headed and should be made more terse;
/// also could be separated by caching the scales which do not change
/// unless data change.
double scaleValue({
  required double value,
  required double ownScaleMin,
  required double ownScaleMax,
  required double toScaleMin,
  required double toScaleMax,
}) {
  // first move scales to be both starting at 0; also move value equivalently.
  // Naming the 0 based coordinates ending with 0
  double value0 = value - ownScaleMin;
  double ownScaleMin0 = 0.0;
  double ownScaleMax0 = ownScaleMax - ownScaleMin;
  double toScaleMin0 = 0.0;
  double toScaleMax0 = toScaleMax - toScaleMin;

  // Next scale the value to 0 - 1 segment
  double value0ScaledTo01 = value0 / (ownScaleMax0 - ownScaleMin0);

  // Then scale value0Scaled01 to the 0 based toScale0
  double valueOnToScale0 = value0ScaledTo01 * (toScaleMax0 - toScaleMin0);

  // And finally shift the valueOnToScale0 to a non-0 start on "to scale"

  double scaled = valueOnToScale0 + toScaleMin;

  return scaled;
}

/// Assuming even length 2D matrix [colsRows], return it's transpose copy.
/* todo-00-nullable : converted List to List.filled
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

// todo-00-attention
// todo-00-nullable-list todo-00-nullable-? : added ? in T? : List<List<T>> transpose<T>(List<List<T>> colsInRows) {
List<List<StackableValuePoint>> transpose(List<List<StackableValuePoint>> colsInRows) {
  int nRows = colsInRows.length;
  if (colsInRows.length == 0) return colsInRows;

  int nCols = colsInRows[0].length;
  if (nCols == 0) throw new StateError("Degenerate matrix");

  // todo-00-nullable-attention : all section is probably wrong due to non fixed list size
  // Init the transpose to make sure the size is right
  // todo-00-nullable-list todo-00-nullable-? : added ? in T? : was : List<List<T>> rowsInCols = new List(nCols);
  List<List<StackableValuePoint>> rowsInCols = new List.filled(nCols, []);
  for (int col = 0; col < nCols; col++) {
    // todo-00-nullable-list : was : rowsInCols[col] =  new List(nRows);
    rowsInCols[col] = new List.filled(nRows, new StackableValuePoint.initial()); // todo-00-nullable-list : new List(nRows);
  }

  // Transpose
  for (int row = 0; row < nRows; row++) {
    for (int col = 0; col < nCols; col++) {
      rowsInCols[col][row] = colsInRows[row][col];
    }
  }
  return rowsInCols;
}

double get epsilon => 0.000001;
