/// Utility that contain only Dart code BUT DOES import 'dart:ui' or anything Flutter.
/// See util_dart.dart for reason.
import 'dart:math' as math;
import 'package:flutter_charts/src/util/extensions_dart.dart';

import 'util_dart.dart';

import 'dart:ui' as ui show Rect, Size;

/// Returns the smallest rectangle which contains all passed [rectangles].
///
/// If the [rectangles] list is empty, an origin-based, zero-sized rectangle is returned.
// todo-00-last-done : added orElse to return point rectangle if no rectangles are passed
ui.Rect boundingRect(List<ui.Rect> rectangles, /*{double Function()? orElse}*/) {
  return ui.Rect.fromLTRB(
    rectangles.map((ui.Rect rectangle) => rectangle.left).reduceOrElse(math.min, orElse: () => 0.0), // left
    rectangles.map((ui.Rect rectangle) => rectangle.top).reduceOrElse(math.min, orElse: () => 0.0), // top,
    rectangles.map((ui.Rect rectangle) => rectangle.right).reduceOrElse(math.max, orElse: () => 0.0), // right
    rectangles.map((ui.Rect rectangle) => rectangle.bottom).reduceOrElse(math.max, orElse: () => 0.0), // bottom
  );
}

void assertSizeResultsSame(ui.Size result, ui.Size otherResult) {
  if (!(isCloserThanEpsilon(result.width, otherResult.width) ||
      isCloserThanEpsilon(result.height, otherResult.height))) {
    String msg = 'Size results do not match. Result was $result, Other result was $otherResult.';
    print(msg);
    throw StateError(msg);
  }
}
