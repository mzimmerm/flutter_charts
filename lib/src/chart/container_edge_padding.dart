import 'dart:ui' as ui;

/// Edge padding for the PaddingLayouter
class EdgePadding  {

  const EdgePadding.fromSTEB(this.start, this.top, this.end, this.bottom);

  const EdgePadding.given({
    this.start = 0.0,
    this.top = 0.0,
    this.end = 0.0,
    this.bottom = 0.0,
  });

  const EdgePadding.allSides(double value)
    : start = value,
      top = value,
      end = value,
      bottom = value;

  static const EdgePadding none = EdgePadding.given();

  final double start;

  final double top;

  final double end;

  final double bottom;

}

