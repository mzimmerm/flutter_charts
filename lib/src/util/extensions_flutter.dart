/// Library for extensions that need flutter test , namely Rect, Offset, Size;
import 'dart:math' as math;
import 'dart:ui' as ui show Rect, Offset, Size;

import 'package:flutter_charts/src/chart/container_edge_padding.dart' show EdgePadding;

extension SizeExtension on ui.Size {

  /// Add the [other] width and height to self width and height.
  ui.Size inflateBySize(ui.Size other) {
    return ui.Size(width + other.width, height + other.height);
  }

  /// Subtract the [other] width and height to self width and height.
  ui.Size deflateBySize(ui.Size other) {
    return ui.Size(math.max(width - other.width, 0.0), math.max(height - other.height, 0.0));
  }

  /// Multiply self width and height by the [other] width and height.
  ui.Size multiplySidesBy(ui.Size other) {
    return ui.Size(width * other.width, height * other.height);
  }

}

extension RectExtension on ui.Rect {

  /// Inflates self on each side of self, by the padding portion corresponding to the side.
  ///
  /// That means, the Rectangle will both move (offset will change) and change size, unless padding
  /// values [padding.start] and [padding.top] are zero.
  ///
  ui.Rect inflateByPadding(EdgePadding padding) {
    ui.Rect translated = translate(-padding.start, -padding.top);
    ui.Rect translatedAndInflated = ui.Rect.fromLTWH(
      translated.left,
      translated.top,
      translated.width + padding.start + padding.end,
      translated.height + padding.top + padding.bottom,
    );
    return translatedAndInflated;
  }

  ui.Rect deflateByPadding(EdgePadding padding) {
    return inflateByPadding(padding.negate());
  }

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

  /// If [other] intersects with self, returns the intersect, otherwise, moves [other]
  /// towards self in the closest direction, so they overlap at least by [widthIntersect] logical
  /// pixels, and returns the intersect.
  ///
  /// Used to show overlapping / protruding portion of the layout.
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

