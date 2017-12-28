import 'dart:ui' as ui show Offset, Paint;


/// Manages [lineFrom] and [lineTo] positions and [linePaint] for a line segment.
/// todo 0 rename - not a presenter, just manages values. move to chart
class LinePresenter {
  ui.Paint linePaint;
  ui.Offset lineFrom;
  ui.Offset lineTo;

  LinePresenter({ui.Offset lineFrom, ui.Offset lineTo, ui.Paint linePaint}) {

    this.linePaint = linePaint;
    this.lineFrom = lineFrom;
    this.lineTo = lineTo;
  }
}
