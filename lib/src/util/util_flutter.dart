/// Utility that contain only Dart code BUT DOES import 'dart:ui' or anything Flutter.
/// See util_dart.dart for reason.
import 'dart:math' as math;
import 'package:flutter_charts/src/util/util_dart.dart';

import 'dart:ui' as ui show Rect, Size;

/// Returns the outer bound of the passed [Offset]s as [Size].
/// todo-01 test

ui.Rect boundingRectOfRects(List<ui.Rect> rectangles) {
  return ui.Rect.fromLTRB(
    rectangles.map((ui.Rect rectangle) => rectangle.left).reduce(math.min), // left
    rectangles.map((ui.Rect rectangle) => rectangle.top).reduce(math.min), // top,
    rectangles.map((ui.Rect rectangle) => rectangle.right).reduce(math.max), // right
    rectangles.map((ui.Rect rectangle) => rectangle.bottom).reduce(math.max), // bottom
  );
}

void assertSizeResultsSame(ui.Size result, ui.Size otherResult) {
  if (!(isCloserThanEpsilon(result.width, otherResult.width) ||
      isCloserThanEpsilon(result.height, otherResult.height))) {
    throw StateError('Size results do not match. Result was $result, '
        'Other result was $otherResult.');
  }
}
