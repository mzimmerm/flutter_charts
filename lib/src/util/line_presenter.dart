import 'dart:ui' as ui show Offset, Paint;


/// Manages [from] and [to] positions and [paint] for a line segment.
/// todo 0 rename - not a presenter, just manages values. move to chart
class LinePresenter {
  ui.Paint paint;
  ui.Offset from;
  ui.Offset to;

  LinePresenter({ui.Offset from, ui.Offset to, ui.Paint paint}) {

    this.paint = paint;
    this.from = from;
    this.to = to;
  }
}
