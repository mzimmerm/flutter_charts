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
  double _radians;

  ui.Offset topLeft;
  ui.Offset topRight;
  ui.Offset bottomLeft;
  ui.Offset bottomRight;

  /// The smallest non-rotated rectangle which envelops the rotated rectangle.
  ui.Rect envelopeRect;

  /// Represents a rectangle [rect] rotated around [pivot]
  /// by angle [rotationAngle].
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
  PivotRotatedRect.from({ui.Rect rect, ui.Offset pivot, double radians}) {
    throw new StateError("Currently not supported");
  }

  /// Represents a rectangle [rect] rotated around it's center
  /// by angle [rotationAngle], which must be in interval `<-math.PI, +math.PI>`.
  ///
  /// See [PivotRotatedRect.from({ui.Rect rect, ui.Offset pivot, double radians})]
  /// for details.
  PivotRotatedRect.centerPivotedFrom({ui.Rect rect, double radians}) {

    if (!(-1 * math.PI <= radians && radians <= math.PI)) {
      throw new StateError("angle must be between -PI and +PI");
    }


    _radians = radians;

    if (_radians == 0.0) {
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
    vector_math.Matrix2 rotM = new vector_math.Matrix2.rotation(radians);

    topLeft = vector2ToOffset(rotM * offsetToVector2(topLeft));
    topRight = vector2ToOffset(rotM * offsetToVector2(topRight));
    bottomLeft = vector2ToOffset(rotM * offsetToVector2(bottomLeft));
    bottomRight = vector2ToOffset(rotM * offsetToVector2(bottomRight));

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

  /// Offset where text painter would consider topLeft when text direction
  /// in left to right.
  /// This is the point which needs be rotated by inverse to canvas rotation,
  ///   when drawing the tilted label text.
  ui.Offset get adjustOffsetOnCanvasRotate {
    if (-math.PI / 2 < _radians && _radians <= math.PI / 2) {
      return topLeft;
    } else {
      return topRight;
    }
  }
}
