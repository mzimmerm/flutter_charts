import 'dart:ui' as ui show Rect, Offset, Size;
import 'package:vector_math/vector_math.dart' as vector_math
    show Matrix2, Vector2;
import 'dart:math' as math show min, max;

/// Utility conversion Offset ==> Vector2

vector_math.Vector2 offsetToVector2(ui.Offset offset) =>
    new vector_math.Vector2(offset.dx, offset.dy);

/// Utility conversion Vector2  ==> Offset

ui.Offset vector2ToOffset(vector_math.Vector2 vector) =>
    new ui.Offset(vector.x, vector.y);

ui.Offset transform({
  vector_math.Matrix2 matrix,
  ui.Offset offset,
}) {
  return vector2ToOffset(matrix * offsetToVector2(offset));
}

/// Immutable envelope of a rotated copy of [sourceRect].
///
/// Used to create rotated (tilted) labels on the X axis,
/// which involves [canvas.rotate()].
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

  ui.Rect _sourceRect;

  /// The source, unrotated rectangle
  get sourceRect => _sourceRect;

  ui.Rect _envelopeRect;

  /// The smallest non-rotated rectangle which envelops the rotated rectangle.
  get envelopeRect => _envelopeRect;

  /// Represents a rectangle [rect] rotated around pivot at center of rectangle,
  /// by the [rotateMatrix]. Note that the [rotateMatrix] must be
  /// rotated by angle inverse to tha the canvas and text is rotated.
  /// (It is the reverse rotation that defines the [topLeft] of text start!)
  ///
  /// During rotation, a reference to the original rectangle corners
  /// [topLeft], [topRight], [bottomLeft], [bottomRight] is maintained
  ///
  /// This is to allow canvas-rotated text painting, which requires to
  /// rotate the label.
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

    //  After rotation and envelope creation, both [envelopeRect]
    //  and the corners of the rotated rectangle
    //  (the [topLeft], [topRight], [bottomLeft], [bottomRight]), are then
    // shifted so that the [envelopeRect.topLeft] = [sourceRect.topLeft]

    ui.Offset shift = _sourceRect.topLeft - _envelopeRect.topLeft;
    _envelopeRect = _envelopeRect.shift(shift);

    _topLeft = _topLeft + shift;
    _topRight = _topRight + shift;
    _bottomLeft = _bottomLeft + shift;
    _bottomRight = _bottomRight + shift;
  }

  ui.Size get size => _envelopeRect.size;
}

Iterable<double> iterableNumToDouble(Iterable<num> nums) {
  return nums.map((num aNum) => aNum.toDouble()).toList();
}
