import 'dart:ui' as ui;

import '../presenters.dart' as presenters; // todo -1 export in lib instead
import '../line/presenters.dart' as line_presenters; // todo -1 export in lib instead

import '../painter.dart';


/// todo 0 document
class LineChartPainter extends ChartPainter {

  // todo -2 remove layouters.ChartLayouter _layouter;

  /// See super [ChartPainter.drawPresentersColumns].
  void drawPresentersColumns(ui.Canvas canvas) {
    this.layouter.presentersColumns.presentersColumns
        .forEach((presenters.PresentersColumn presentersColumn) {
      presentersColumn.presenters
          .forEach((presenters.Presenter presenter) {
        line_presenters.LineAndHotspotPresenter presenterCast = presenter as line_presenters.LineAndHotspotPresenter;
        canvas.drawLine(
          presenterCast.linePresenter.from,
          presenterCast.linePresenter.to,
          presenterCast.linePresenter.paint,
        );
        canvas.drawCircle(
            presenterCast.offsetPoint,
            presenterCast.outerRadius,
            presenterCast.outerPaint);
        canvas.drawCircle(
            presenterCast.offsetPoint,
            presenterCast.innerRadius,
            presenterCast.innerPaint);
      });
    });
  }
}

