/// Utility that contain only Dart code BUT DOES import 'dart:ui' or anything Flutter.
/// See util_dart.dart for reason.
import 'dart:math' as math;

import 'dart:ui' as ui show Rect;

/// Returns the outer bound of the passed [Offset]s as [Size].
/// todo-01 test
ui.Rect outerRectangle(List<ui.Rect> rectangles) {
  return ui.Rect.fromLTRB(
    rectangles.map((ui.Rect rectangle) => rectangle.left).reduce(math.min), // left
    rectangles.map((ui.Rect rectangle) => rectangle.top).reduce(math.min), // top,
    rectangles.map((ui.Rect rectangle) => rectangle.right).reduce(math.max)
      - rectangles.map((ui.Rect rectangle) => rectangle.left).reduce(math.min), // width = max rights - min lefts
    rectangles.map((ui.Rect rectangle) => rectangle.bottom).reduce(math.max)
        - rectangles.map((ui.Rect rectangle) => rectangle.top).reduce(math.min), // height = max bottom - min top
  );
}
