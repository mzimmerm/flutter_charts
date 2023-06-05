/// Library for extensions that need flutter test , namely Rect, Offset, Size;
import 'dart:math' as math;
import 'dart:ui' as ui show Rect, Offset, Size; // dart:ui is actually Flutter package

import 'package:flutter_charts/src/morphic/ui2d/point.dart';
import 'package:flutter_charts/src/util/vector/vector_2d.dart' show Vector;
import 'package:flutter_charts/src/util/util_dart.dart' show epsilon, isCloserThanEpsilon;

import '../morphic/container/container_edge_padding.dart' as edge_padding show EdgePadding;
import '../morphic/container/morphic_dart_enums.dart' show LayoutAxis;

extension SizeExtension on ui.Size {

  /// Returns a Size with [width] and [height] being self [width] and [height]
  /// increased with [other] width and height.
  ui.Size inflateWithSize(ui.Size other) {
    return ui.Size(width + other.width, height + other.height);
  }

  /// Returns a Size which [ui.Size.width] and [ui.Size.height] is self [width] and [height]
  /// shortened with [other]'s width and height.
  ///
  /// More precisely, the returned size's [ui.Size.width] is equal to `this.width - other.width`
  /// but not becoming negative.  An equivalent statement applies to the returned [ui.Size.height].
  ///
  /// If any returned size length would become negative, it is set to `0.0` instead.
  ui.Size deflateWithSize(ui.Size other) {
    return ui.Size(math.max(width - other.width, 0.0), math.max(height - other.height, 0.0));
  }

  /// Returns a Size which [ui.Size.width] and [ui.Size.height] is self [width] and [height]
  /// multiplied by [other]'s width and height.
  ui.Size multiplySidesBy(ui.Size other) {
    return ui.Size(width * other.width, height * other.height);
  }

  /// Returns  width or height of this [Size] instance along the passed [layoutAxis].
  double lengthAlong(LayoutAxis layoutAxis) {
    switch (layoutAxis) {
      case LayoutAxis.horizontal:
        return width;
      case LayoutAxis.vertical:
        return height;
    }
  }

  ui.Size fromMySideAlongPassedAxisOtherSideAlongCrossAxis({
    required ui.Size other,
    required LayoutAxis axis,
  }) {
    // if passed axis is horizontal, use my width, other's height
    if (axis == LayoutAxis.horizontal) {
      return ui.Size(width, other.height);
    } else {
      // else (passed axis is vertical), use my height, other's width
      return ui.Size(other.width, height);
    }
  }

  /// Returns [true] if this instance contains fully the passed [other] object of type [ui.Size].
  bool containsFully(ui.Size other) {
    return other.width <= width &&
        other.height <= height;
  }

  /// Outermost union of this size with [other].
  ui.Size merge(ui.Size other) {
    return ui.Size(math.max(width, other.width), math.max(height, other.height));
  }
  
  ui.Size envelope(List<ui.Size> otherSizes) => otherSizes.isNotEmpty
      ? otherSizes.fold(this, (previousSize, size) => previousSize.merge(size))
      : this;
  
  ui.Size replaceZerosFrom(ui.Size other) {

    if (this.width > 0.0 && this.height > 0.0) {
      return this;
    }
    double width = this.width;
    double height = this.height;
    if (width == 0.0) width = other.width;
    if (height == 0.0) height = other.height;

    return ui.Size(width, height);
  }

  PointOffset toPointOffset() {
    return PointOffset(inputValue: width, outputValue: height);
  }

  static ui.Size fromVector(Vector<double> vector) {
    vector.ensureLength(2, elseMessage: 'Size can only be created from vector with 2 elements.');

    return ui.Size(vector[0], vector[1]);
  }

  /// Present itself as code
  String asCodeConstructor() {
    return 'const Size($width, $height)';
  }

}

/* Any time this was needed, we can use instead:
     Size + Offset which yields Size
extension OffsetExtension on ui.Offset {
  ui.Size toSize() {
    return ui.Size(dx, dy);
  }
}
*/

extension RectExtension on ui.Rect {

  /// Inflates self on each side of self, by the padding portion corresponding to the side.
  ///
  /// That means, the Rectangle will both move (offset will change) and change size, unless padding
  /// values [padding.start] and [padding.top] are zero.
  ///
  ui.Rect inflateWithPadding(edge_padding.EdgePadding padding) {
    ui.Rect translated = translate(-padding.start, -padding.top);
    ui.Rect translatedAndInflated = ui.Rect.fromLTWH(
      translated.left,
      translated.top,
      translated.width + padding.start + padding.end,
      translated.height + padding.top + padding.bottom,
    );
    return translatedAndInflated;
  }

  ui.Rect deflateWithPadding(edge_padding.EdgePadding padding) {
    return inflateWithPadding(padding.negate());
  }

  /// Return `true` if this instance is outside of [other] within [epsilon].
  ///
  /// In other words, returns `true` if the rectangles do not intersect even one pixel; they can touch though.
  ///
  bool isOutsideOfWithinEpsilon(ui.Rect other) {
    return !isIntersectWithinEpsilon(other);
  }

  bool isIntersectWithinEpsilon(ui.Rect other) {
    ui.Rect intersection = intersect(other);

    // [epsilon] or smaller intersect in at least one orientation is considered no intersect.
    if (intersection.width.abs() < epsilon || intersection.height.abs() < epsilon) {
      return false;
    }

    // Not intersecting ui.Rect have negative width and height.
    return intersection.width > 0.0 && intersection.height > 0.0; // todo-00-next: Should this be >= 1.0 - epsilon?? test that!
  }

  /// Returns `true` if this rectangle's corner points are all the same, or differ by at most [epsilon]
  bool isEqualWithinEpsilon(ui.Rect other) {
    return topLeft.isEqualWithinEpsilon(other.topLeft) && bottomRight.isEqualWithinEpsilon(other.bottomRight);
  }

  /// If [other] intersects with self, returns the intersect, otherwise, moves [other]
  /// towards self in the closest direction, so they overlap at least by [widthIntersect] logical
  /// pixels, and returns the intersect.
  ///
  /// Used to show overlapping / protruding portion of the layout.
  ui.Rect closestIntersectWith(ui.Rect other) {
    // todo-04 : if other contains this, and other is just bigger,
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

    // Check for overlap assumption, but continue running after overlap, so the rest of the layout and paint continues
    if (!overlaps(other)) {
      print(' ### Log.Warning: closestIntersectWith: This rectangle $this does NOT overlap at all rectangle other = $other.');
    }
    ui.Rect intersection = intersect(other);
    // Check for intersection assumption that is needed to correctly paint the warning rectangle,
    //   but continue even if the assumption fails.
    if (!(intersection.width >= widthIntersect)) {
      print(' ### Log.Warning: closestIntersectWith: !(intersection.width >= widthIntersect) was INCORRECTLY true.'
          'intersection = $intersection, widthIntersect=$widthIntersect');
    }
    // assert (intersection.height >= heightIntersect);

    return intersection;
  }

  /// Shift along the passed axis by [byLength].
  ui.Rect shiftAlong({
    required LayoutAxis layoutAxis,
    required double byLength,
  }) {
    switch (layoutAxis) {
      case LayoutAxis.horizontal:
        return shift(ui.Offset(byLength, 0));
      case LayoutAxis.vertical:
        return shift(ui.Offset(0, byLength));
    }
  }

  bool isPointWithinEpsilon() {
    return width.abs() < epsilon || height.abs() < epsilon;
  }

}

extension OffsetExtension on ui.Offset {
  bool isEqualWithinEpsilon(ui.Offset other) {
    return (isCloserThanEpsilon(dx, other.dx) && isCloserThanEpsilon(dy, other.dy));
  }
}