import 'dart:ui' as ui;

// this level
import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart';

/// [Alignment] defines how a child should be positioned in it's parent.
///
/// [Alignment] is a helper class and required parameter for [Aligner].
///
/// Members [alignX], [alignY] have values between -1 and +1.
/// This allows [Alignment] to be represented by a Square with sides 2x2, centered at 0, 0.
/// Any point (offset) within the square represents a specific alignment (position, offset) of a child rectangle
/// inside this [Aligner].
///
/// [alignX], [alignY] represent how much is the alignerChild offset in the [Aligner] during layout.
/// Alignment with ```alignX = -1; alignY = -1``` causes no offset of alignerChild in [Aligner] .
/// Alignment with ```alignX = +1; alignY = +1``` causes offset of alignerChild in [Aligner] such that
/// the alignerChild is pushed inside Aligner all the way down and right (given text right to left).
///
/// Basic positioning (alignments) are
/// [Alignment.startTop], [Alignment.endTop], [Alignment.endBottom],  [Alignment.startBottom],
/// and [Alignment.center].
///
/// [Alignment] can represent any general alignerChild-inside-parent positioning (alignerChild offset in parent).
///
/// In a layout used in this snippet
///   ```dart
///      Parent(
///        child:
///          Aligner(
///            alignment:
///              Alignment(
///                alignX: -1,
///                alignY: -1,
///              ),
///            childWidthBy: 2,
///            childHeightBy: 3,
///            child: alignerChild
///          ),
///        )
///   ```
///
/// the [Aligner.childWidthBy] is the multiplier of the `alignerChild` width; the causes [Aligner.layoutSize] width 
/// to be the [Aligner.childWidthBy] multiple of `alignerChild`'s layoutSize. In other words, [Aligner.childWidthBy] 
/// makes more space for the `alignerChild` than it's layoutSize; the `alignerChild` is then positioned inside 
/// [Aligner] at a position specified by [Alignment].
/// 
///
/// In more details, the [Aligner]s size is
///   ```dart
///     alignerSize = Size(
///       alignerChildWidth * childWidthBy,
///       alignerChildHeight * childHeightBy,
///       )
///   ```
///
/// The alignerChild is then positioned in the [Aligner] at offset controlled by [alignX] and [alignY]
///   ```dart
///     alignerChildTopLefOffsetX = [alignerChildWidth *  (alignerChildWidthBy  - 1)] * (alignX + 1) / 2
///     alignerChildTopLefOffsetY = [alignerChildHeight * (alignerChildHeightBy - 1)] * (alignY + 1) / 2
///     Offset(alignerChildTopLefOffsetX, alignerChildTopLefOffsetY);
///   ```
///   (1)
///
/// To visualize what this means, imagine the [Alignment] square is transformed to alignerSize.
///
/// Then the alignerChild is positioned in [Aligner], making sure the whole alignerChild fits into the [Aligner].
///
/// We know that ```alignerWidth = alignerChildWidth * alignerChildWidthBy```
///
/// Let's workout a few border situations, to come up with a generic formula, given
/// [Aligner.childWidthBy] and [Alignment.alignX] :
/// ```
///     - alignX =-1 => centerOffsetX = alignerChildWidth / 2
///     - alignX = 0 => centerOffsetX = alignerChildWidth / 2 + (alignerWidth - alignerChildWidth) / 2 
///                                   = alignerWidth / 2 = (alignerChildWidth * childWidthBy) / 2
///     - alignX =+1 => centerOffsetX = alignerWidth - (alignerChildWidth / 2) 
///                                   = alignerChildWidth * alignerChildWidthBy - (alignerChildWidth / 2) 
///                                   = alignerChildWidth * (alignerChildWidthBy - 1/2)
/// ```
///
/// So the above is offset of the center of the alignerChild in aligner.
///
/// The offset of alignerChild's topLeft corner is then, for any align Value:
/// ```
///     - alignX =-1, 0, 1 => topLefOffsetX = centerOffsetX - (alignerChildWidth / 2)
/// ```
/// But if we express the 'align sensitive' centerOffset again, we have:
/// ```
///     - alignX =-1 => topLefOffsetX = alignerChildWidth / 2                    - (alignerChildWidth / 2)                                           = 0
///     - alignX = 0 => topLefOffsetX = (alignerChildWidth * alignerChildWidthBy) / 2   - (alignerChildWidth / 2)                                           = (alignerChildWidth * (alignerChildWidthBy - 1)) / 2
///     - alignX =+1 => topLefOffsetX = alignerChildWidth * (alignerChildWidthBy - 1/2) - (alignerChildWidth / 2) 
///                                   = alignerChildWidth * (alignerChildWidthBy - 1/2 - 1/2) = (alignerChildWidth * (alignerChildWidthBy - 1))
/// ```
///
/// *So for a generic [alignX], the formula can be derived by looking at the above and realizing*
///  that the 'end value' is ```alignerChildWidth * (alignerChildWidthBy - 1)```, when we linearly extrapolate it back to 0
///  using values 0, 1/2, 1 for alignX = -1, 0, +1 we get the desired result.
///  The linear extrapolate that gives 0, 1/2, 1 for alignX = -1, 0, +1 can be constructed as ```(alignX + 1) / 2```.
///
/// ```
///     topLefOffsetX = (alignerChildWidth * (alignerChildWidthBy - 1)) * (alignX + 1) / 2
/// ```
/// Which shows the reason for (1)
///
/// A pictorial of [Alignment] and [Aligner]
///
/// <span style="font-family:Courier;>
///                 +----------------+----------------+
///                 |                |                |
///                 |                |                |
///                 |                |                |                                    .
///                 |                |                |
///                 |                |                |
///                 |                |                |
///                 |                |                |
///                 +----------------+                |
///                 |         ^                       |
///                 |   Child |                       |
///                 |      for alignX=-1              |
///                 |      for alignY=-1              |
///                 |                                 |
///                 |                                 |
///                 |                +----------------+
///                 |                |                |
///                 |                |                |
///                 |                |                |
///                 |                |                |
///                 |                |                |
///                 |                |                |
///                 |                |                |
///   Aligner------>+----------------+----------------+
///     alignerChildWidthBy=2        ^
///     alignerChildHeightBy=3       |
///                                  |
///                                  Child
///                                    for alignX=1
///                                        alignY=1
/// </span>
///
class Alignment {

  const Alignment({required this.alignX, required this.alignY,});

  // Instance member '_start' cannot be accessed in initializer : Alignment.bottomStart() : this(alignX: _start, alignY: _bottom);
  // const Alignment.startTop() : this(alignX: -1, alignY: -1);
  // const Alignment.endTop() : this(alignX: 1, alignY: -1);
  // const Alignment.endBottom() : this(alignX: 11, alignY: 1);
  // const Alignment.startBottom() : this(alignX: -1, alignY: 1);
  // const Alignment.center() : this(alignX: 0, alignY: 0);

  static const startTop = Alignment(alignX: _start, alignY: _top);
  static const endTop = Alignment(alignX: _end, alignY: _top);
  static const endBottom = Alignment(alignX: _end, alignY: _bottom);
  static const startBottom = Alignment(alignX: _start, alignY: _bottom);
  static const center = Alignment(alignX: _center, alignY: _center);

  final double alignX;
  final double alignY;

  static const double _start = -1;
  static const double _end = 1;
  static const double _top = -1;
  static const double _bottom = 1;
  static const double _center = 0;
}

/// Transform object provides a way to calculate offset
/// of a small Rectangle (or Size) inside a larger Rectangle (or Size).
///
/// Explaining the context better. Let's assume we have a small rectangle,
/// with sides of length `width` and `height`. From this rectangle, we can create
/// a bigger rectangle, by *making the rectangles top-left points the same*, and stretching
/// the rectangle into a bigger one (fully containing the smaller), by giving the bigger one
/// sides sized `width * childWidthBy` and `height * childHeightBy`.
///
/// Now we can think of moving the smaller rectangle, keeping it inside the large one, by
/// transforming it using an instance of [Alignment].
///
/// This class allows us to find how much
/// is the smaller rectangle [Offset] during such transform.
///
class AlignmentTransform {

  const AlignmentTransform({
    required this.childWidthBy,
    required this.childHeightBy,
    this.alignment = Alignment.center,
  }) : assert(childWidthBy >= 1 && childHeightBy >= 1);

  final double childWidthBy;
  final double childHeightBy;
  final Alignment alignment;

  /// Returns how much is a rectangle with size [childSize] Offset,
  /// when this [AlignmentTransform] is applied to it.
  ///
  /// Note that this means we are looking at two rectangles, *fixed at the top-left point*,
  /// a smaller one passed here, and larger one, created from it by stretching it
  /// using this transform's [childWidthBy] and [childHeightBy].
  ///
  /// This function calculates how much [Offset] is applied on the smaller [childSize]s rectangle,
  /// to move it to the position defined by [alignment].
  ///
  /// See discussion in [Alignment] for the positioning of the smaller [childSize]s rectangle, given the [alignment].
  ui.Offset childOffsetWhenAlignmentApplied({
    required ui.Size childSize,
  }) {
    double childWidth = childSize.width;
    double childHeight = childSize.height;

    /// The child is then positioned in the [Aligner] at offset controlled by [alignX] and [alignY]:
    double childTopLefOffsetX = (childWidth * (childWidthBy - 1)) * (alignment.alignX + 1) / 2;
    double childTopLefOffsetY = (childHeight * (childHeightBy - 1)) * (alignment.alignY + 1) / 2;

    return ui.Offset(childTopLefOffsetX, childTopLefOffsetY);
  }


}