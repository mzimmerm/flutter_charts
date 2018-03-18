import 'dart:ui' as ui show Rect, Offset;
import 'package:vector_math/vector_math.dart' as vector_math
    show Matrix2, Vector2;
import 'dart:math' as math show min, max, PI;

/// Utility conversion Offset ==> Vector2

vector_math.Vector2 offsetToVector2(ui.Offset offset) =>
    new vector_math.Vector2(offset.dx, offset.dy);

/// Utility conversion Vector2  ==> Offset

ui.Offset vector2ToOffset(vector_math.Vector2 vector) =>
    new ui.Offset(vector.x, vector.y);

ui.Offset rotateOffset({ui.Offset offset, vector_math.Matrix2 rotatorMatrix}) {

  return vector2ToOffset(rotatorMatrix * offsetToVector2(offset));
}

/// Represents a rotated rectangle with unrotated envelope.
///
/// The corners of rectangle rotated by (about) by -PI/4 are marked as "x" below.
///     +-x------+
///     |.  .    |
///     x     .  |
///     | .     .|
///     |   .   .x
///     +------x-+
/// The corners of rectangle rotated by (about) by +PI/4 are marked as "x" below.
///     +------x-+
///     |    .  .|
///     |   .    x
///     | .    . |
///     x.   .   |
///     +-x------+

class PivotRotatedRect {
  vector_math.Matrix2 _rotatorMatrix;

  ui.Offset topLeft;
  ui.Offset topRight;
  ui.Offset bottomLeft;
  ui.Offset bottomRight;

  /// The smallest non-rotated rectangle which envelops the rotated rectangle.
  ui.Rect envelopeRect;

  /// Represents a rectangle [rect] rotated around pivot at center of rectangle,
  /// by [rotatorMatrix] .
  ///
  /// Positive rotations are counter clockwise, as in math.
  ///
  /// During rotation, a reference to the original rectangle corners
  /// [topLeft], [topRight], [bottomLeft], [bottomRight] is maintained
  /// (even though after rotation
  /// their meaning may be completely different). This is to allow
  /// using these objects during oriented text painting.
  ///
  /// Currently only pivot = rectangle center is supported.
  ///
  PivotRotatedRect.centerPivotedFrom({ui.Rect rect, vector_math.Matrix2 rotatorMatrix}) {

    _rotatorMatrix = rotatorMatrix;

    if (_rotatorMatrix == new vector_math.Matrix2.identity()) {
      envelopeRect = rect;
      topLeft = rect.topLeft;
      topRight = rect.topRight;
      bottomLeft = rect.bottomLeft;
      bottomRight = rect.bottomRight;

      return;
    }

    // shift = translate rect to coordinates where center = origin of rect
    ui.Rect movedToCenterAsOrigin = rect.shift(-rect.center);

    topLeft = movedToCenterAsOrigin.topLeft;
    topRight = movedToCenterAsOrigin.topRight;
    bottomLeft = movedToCenterAsOrigin.bottomLeft;
    bottomRight = movedToCenterAsOrigin.bottomRight;

    // Rotate all corners of the rectangle
    topLeft = vector2ToOffset(_rotatorMatrix * offsetToVector2(topLeft));
    topRight = vector2ToOffset(_rotatorMatrix * offsetToVector2(topRight));
    bottomLeft = vector2ToOffset(_rotatorMatrix * offsetToVector2(bottomLeft));
    bottomRight = vector2ToOffset(_rotatorMatrix * offsetToVector2(bottomRight));

    var rotOffsets = [topLeft, topRight, bottomLeft, bottomRight];

    double minX = rotOffsets.map((offset) => offset.dx).reduce(math.min);
    double maxX = rotOffsets.map((offset) => offset.dx).reduce(math.max);
    double minY = rotOffsets.map((offset) => offset.dy).reduce(math.min);
    double maxY = rotOffsets.map((offset) => offset.dy).reduce(math.max);

    envelopeRect = new ui.Rect.fromPoints(
      new ui.Offset(minX, minY),
      new ui.Offset(maxX, maxY),
    );

    // shift = translate both envelopeRect and rotated corners back to the
    // old center of the rectangle
    envelopeRect = envelopeRect.shift(rect.center);

    topLeft = topLeft + rect.center;
    topRight = topRight + rect.center;
    bottomLeft = bottomLeft + rect.center;
    bottomRight = bottomRight + rect.center;
  }


}
