/// Utility that contain only Dart code BUT DOES import 'dart:ui' or anything Flutter.
/// See util_dart.dart for reason.
import 'dart:math' as math;

import 'dart:ui' as ui show Rect, Offset, Size;

/// Returns the outer bound of the passed [Offset]s as [Size].
/// todo-01 test

ui.Rect boundingRectOfRects(List<ui.Rect> rectangles) {
  return ui.Rect.fromLTRB(
    rectangles.map((ui.Rect rectangle) => rectangle.left).reduce(math.min),   // left
    rectangles.map((ui.Rect rectangle) => rectangle.top).reduce(math.min),    // top,
    rectangles.map((ui.Rect rectangle) => rectangle.right).reduce(math.max),  // right
    rectangles.map((ui.Rect rectangle) => rectangle.bottom).reduce(math.max),  // bottom
  );
}

extension RectExtension on ui.Rect {
  bool isOutsideOf(ui.Rect other) {
    ui.Rect intersection = intersect(other);
    // Not intersecting ui.Rect have negative width and height
    bool isIntersect = intersection.width > 0.0 && intersection.height > 0.0;
    return !isIntersect;
  }

  bool isInsideOf(ui.Rect other) {
    ui.Rect intersection = intersect(other);
    return intersection == this;
  }

  // todo-00-document
  ui.Rect closestIntersectWith(ui.Rect other) {
    // todo-02 : if other contains this, and is just bigger,
    //           we want to return only some piece in the direction where other overflows this.
    //           currently we essentially return this overlap other, which spans the full width of this.
    if (overlaps(other)) {
      return intersect(other);
    }

    // Move other inside me by 20x20
    double widthIntersect = 50.0;
    double heightIntersect = 50.0;
    
    if (other.bottom <= top) {
      other = other.shift(ui.Offset(0.0, top - other.bottom + heightIntersect));
    } else if (bottom <= other.top) {
       other = other.shift(ui.Offset(0.0, bottom - other.top - heightIntersect));
    } else {
       if (other.bottom - top < heightIntersect && other.height > heightIntersect) {
         other = other.shift(ui.Offset(0.0, heightIntersect - (other.bottom - top)));
       } else if (other.top - bottom < heightIntersect && other.height > heightIntersect) {
         other = other.shift(ui.Offset(0.0, heightIntersect - (other.top - bottom)));
       }
    }

    // check these conditions that set offset x
    if (other.right <= left) {
      other = other.shift(ui.Offset(left - other.right + widthIntersect, 0.0));
    } else if (right <= other.left) {
      other = other.shift(ui.Offset(right - other.left - widthIntersect, 0.0));
    } else {
      if (left - other.right < widthIntersect) {
        other = other.shift(ui.Offset(widthIntersect - (left - other.right), 0.0));
      } else if (other.left - right < widthIntersect) {
        other = other.shift(ui.Offset(widthIntersect - (other.left - right), 0.0));
      }
    }
    
    assert (overlaps(other));
    ui.Rect intersection = intersect(other);
    assert (intersection.width >= widthIntersect);
    // assert (intersection.height >= heightIntersect);

    return intersection;
  }
}

