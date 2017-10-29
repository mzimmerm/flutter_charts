import 'dart:ui' as ui show Offset, Paint;


/// todo 0 document
/// todo 0 move to chart, maybe
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
