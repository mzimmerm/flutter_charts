
/// Edge padding for the PaddingLayouter
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

