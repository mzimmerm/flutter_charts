
import 'package:flutter_charts/src/morphic/container/chart_support/chart_orientation.dart';

/// Edge padding for the [Padder] layouter.
///
/// Script-writing order dependent members [start] and [end] define padding in logical pixels
/// on the left and the right of the child for left-to-right scripts;
/// on the right and the left for right-to-left scripts
///
/// [top] and [bottom] define padding in logical pixels on the top and the bottom of the child.
///
/// Assuming left to right, using a construct such as
///   ```dart
///      Padder(
///        edgePadding: EdgePadding(start: 1, top: 2, end: 3, bottom:4),
///        child: Child(),
///      )
///   ```
///   The child is surrounded by 1, 2, 3, and 4 pixels, and it's width is increased by 1+3 pixels,
///   it's height by 2+4 pixels from child's width and height.
class EdgePadding  {

  // Generative unnamed
  const EdgePadding({
    required this.start,
    required this.top,
    required this.end,
    required this.bottom,
  });

  const EdgePadding.withSides({
    this.start = 0.0,
    this.top = 0.0,
    this.end = 0.0,
    this.bottom = 0.0,
  });

  factory EdgePadding.TransposingWithSides({
    required ChartSeriesOrientation chartSeriesOrientation,
    double start = 0.0,
    double top = 0.0,
    double end = 0.0,
    double bottom = 0.0,
  }) {
    switch(chartSeriesOrientation) {
      case ChartSeriesOrientation.column:
        return EdgePadding.withSides(start: start, top: top, end: end, bottom: bottom);
      case ChartSeriesOrientation.row:
        return EdgePadding.withSides(start: bottom, top: end, end: top, bottom: start);
    }
  }

  // constructor const EdgePadding.none() : this.withSides();
  static const EdgePadding none = EdgePadding.withSides(); // member field

  const EdgePadding.withAllSides(double value)
      : start = value,
        top = value,
        end = value,
        bottom = value;

  /// Padding copy of self with all sides reversed signs.
  ///
  /// Useful for inflating and deflating Rectangles.
  EdgePadding negate() => EdgePadding(start: -start, top: -top, end: -end, bottom: -bottom);

  final double start;

  final double top;

  final double end;

  final double bottom;
}

