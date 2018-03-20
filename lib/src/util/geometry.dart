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

ui.Offset transform({ vector_math.Matrix2 matrix, ui.Offset offset,}) {
  return vector2ToOffset(matrix * offsetToVector2(offset));
}

/// Immutable envelope of a rotated copy of [sourceRect].
///
/// The [sourceRect] is rotated around it's center, then enveloped by
/// it's unrotated (parallel to axes) [envelopeRect]. The corners
/// of the rotated copy of the [sourceRect] are maintained as
///  [topLeft], [topRight], [bottomLeft], [bottomRight].
///
///  After rotation and envelope creation, both [envelopeRect]
///  and the corners of the rotated rectangle
///  (the [topLeft], [topRight], [bottomLeft], [bottomRight]), are then
/// shifted so that the [envelopeRect.topLeft] = [sourceRect.topLeft]
///
/// *Note that the rotation origin ("pivot") is NOT the center of the coordinate
/// system, but the center of the rectangle*.
///
/// Positive rotations are counter clockwise, as in math.
///
/// Pictorial example of the corners of the [sourceRect]
/// rotated by (about) by -PI/4 (first picture) and +PI/4 (second)
/// are marked as "x" below, also showing the enveloping [envelopeRect].
///     +-x------+ <-- x = TL
///     |.  .    |
///     x     .  | <-- x = TR
///     | .     .|                -PI/4, text direction: \
///     |   .   .x <-- x = BR                             \
///     +------x-+ <-- x = BL                              v
///
///     +------x-+ <-- x = TR
///     |    .  .|                                          ^
///     |   .    x <-- x = BR                              /
///     | .    . |                 +PI/4, text direction: /
///     x.   .   | <-- x = TL
///     +-x------+ <-- x = BL

class EnvelopedRotatedRect {
  ui.Offset _topLeft;
  get topLeft => _topLeft;

  ui.Offset _topRight;
  get topRight => _topRight;

  ui.Offset _bottomLeft;
  get bottomLeft => _bottomLeft;

  ui.Offset _bottomRight;
  get bottomRight => _bottomRight;

  vector_math.Matrix2 _rotatorMatrix;

  /// The matrix used for rotation of the [sourceRect], after which the
  /// rotated corners [topLeft] etc) are created.
  get rotatorMatrix => _rotatorMatrix;

  double _rotatorRadians;

  /// Extra info, currently needed in [textTopLeftOnCanvasRotate] to check
  ///   which corner [TextPainter] shoiuld use on canvas rotate.
  /// This angle MUST be the angle used to create [rotatorMatrix].
  // get rotatorRadians => _rotatorRadians;

  ui.Rect _sourceRect;

  /// The source, unrotated rectangle
  get sourceRect => _sourceRect;

  ui.Rect _envelopeRect;

  /// The smallest non-rotated rectangle which envelops the rotated rectangle.
  get envelopeRect => _envelopeRect;

  /// Represents a rectangle [rect] rotated around pivot at center of rectangle,
  /// by [rotateMatrix] .
  ///
  /// During rotation, a reference to the original rectangle corners
  /// [_topLeft], [_topRight], [_bottomLeft], [_bottomRight] is maintained
  /// (even though after rotation
  /// their meaning may be completely different). This is to allow
  /// using these objects during oriented text painting.
  ///
  /// Currently only pivot = rectangle center is supported.
  ///
  EnvelopedRotatedRect.centerRotatedFrom({
    ui.Rect rect,
    vector_math.Matrix2 rotateMatrix,
  }) {

    assert(rotateMatrix != null);

    _rotatorMatrix = rotateMatrix;
    _sourceRect = rect;

    if (_rotatorMatrix == new vector_math.Matrix2.identity()) {
      _envelopeRect = rect;
      _topLeft = rect.topLeft;
      _topRight = rect.topRight;
      _bottomLeft = rect.bottomLeft;
      _bottomRight = rect.bottomRight;

      return;
    }

    // shift = translate rect to coordinates where center = origin of rect
    ui.Rect movedToCenterAsOrigin = rect.shift(-rect.center);

    _topLeft = movedToCenterAsOrigin.topLeft;
    _topRight = movedToCenterAsOrigin.topRight;
    _bottomLeft = movedToCenterAsOrigin.bottomLeft;
    _bottomRight = movedToCenterAsOrigin.bottomRight;

    // Rotate all corners of the rectangle. Coordinates are the
    _topLeft = transform(matrix: _rotatorMatrix, offset: _topLeft);
    _topRight = transform(matrix: _rotatorMatrix, offset: _topRight);
    _bottomLeft = transform(matrix: _rotatorMatrix, offset: _bottomLeft);
    _bottomRight = transform(matrix: _rotatorMatrix, offset: _bottomRight);

    var rotOffsets = [_topLeft, _topRight, _bottomLeft, _bottomRight];

    double minX = rotOffsets.map((offset) => offset.dx).reduce(math.min);
    double maxX = rotOffsets.map((offset) => offset.dx).reduce(math.max);
    double minY = rotOffsets.map((offset) => offset.dy).reduce(math.min);
    double maxY = rotOffsets.map((offset) => offset.dy).reduce(math.max);

    _envelopeRect = new ui.Rect.fromPoints(
      new ui.Offset(minX, minY),
      new ui.Offset(maxX, maxY),
    );
    /* todo -12

    // shift = translate both envelopeRect and rotated corners back to the
    // old center of the rectangle
    _envelopeRect = _envelopeRect.shift(rect.center);

    _topLeft = _topLeft + rect.center;
    _topRight = _topRight + rect.center;
    _bottomLeft = _bottomLeft + rect.center;
    _bottomRight = _bottomRight + rect.center;
*/
    //  After rotation and envelope creation, both [envelopeRect]
    //  and the corners of the rotated rectangle
    //  (the [topLeft], [topRight], [bottomLeft], [bottomRight]), are then
    // shifted so that the [envelopeRect.topLeft] = [sourceRect.topLeft]

    ui.Offset shift =_sourceRect.topLeft - _envelopeRect.topLeft;
    _envelopeRect = _envelopeRect.shift(shift);

    _topLeft = _topLeft + shift;
    _topRight = _topRight + shift;
    _bottomLeft = _bottomLeft + shift;
    _bottomRight = _bottomRight + shift;
 }

  /// Offset where text painter would use as "start of text" (topLeft),
  /// when [ui.TextDirection] in left to right.
  /// This is the point which needs be rotated by inverse to canvas rotation,
  ///   when drawing the tilted label text.
  ui.Offset textTopLeftOnCanvasRotate() {
    // todo -12
    /*
    if (-math.PI / 2 < _rotatorRadians && _rotatorRadians <= math.PI / 2 + 0.1) {
      return topRight;  // PI/2
    } else {
      return bottomLeft; // - PI/2
    }
    */
    return topLeft;
  }

/*
  /// By definition, rotation of a vector by a rotation matrix is always around center!!
  /// (because matrix values are independent on the coordinate system, and vector coordinates are always center)
  /// 
  /// todo -1 document and prove that for any 2 pivot (pivot = origin) `o` and `o'` (o prime),
  ///   R(o) = R(o - o` + o`) = R(o - o`) + R(o')
  /// so
  ///   R(o') = R(o) - R(o - o`)
  ///   R(newOrigin) = R(oldOrigin) - R(oldOrigin - newOrigin) = R(oldOrigin) + R(newOrigin - oldOrigin)

  void changeRotationOriginTo(ui.Offset newOrigin) {

    ui.Offset oldOrigin = _sourceRect.center;
    ui.Offset rOldOriMinusNewOri = multiply(matrix: _rotatorMatrix, offset: newOrigin - oldOrigin,);

    // now shift all values by rOldOriMinusNewOri
    _envelopeRect = _envelopeRect.shift(oldOrigin);

    _topLeft = _topLeft + oldOrigin;
    _topRight = _topRight + oldOrigin;
    _bottomLeft = _bottomLeft + oldOrigin;
    _bottomRight = _bottomRight + oldOrigin;
  }
*/
}
