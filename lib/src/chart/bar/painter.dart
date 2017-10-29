import 'dart:ui' as ui;

import '../painter.dart';
import '../presenters.dart' as presenters; // todo -1 export in lib instead

import '../bar/presenters.dart' as bar_presenters; // todo -1 export in lib instead

/// todo 0 document,
class VerticalBarChartPainter extends ChartPainter {

  // todo -2 remove layouters.ChartLayouter _layouter;

  /// See super [ChartPainter.drawPresentersColumns].
  void drawPresentersColumns(ui.Canvas canvas) {
    this.layouter.presentersColumns.presentersColumns
        .forEach((presenters.PresentersColumn presentersColumn) {
      // todo 0 do not repeat loop, collapse to one construct
      presentersColumn.positivePresenters
          .forEach((presenters.Presenter presenter) {
        bar_presenters.VerticalBarPresenter presenterCast = presenter as bar_presenters.VerticalBarPresenter;
        canvas.drawRect(presenterCast.presentedRect, presenterCast.dataRowPaint);
      });

      presentersColumn.negativePresenters
          .forEach((presenters.Presenter presenter) {
        bar_presenters.VerticalBarPresenter presenterCast = presenter as bar_presenters.VerticalBarPresenter;
        canvas.drawRect(presenterCast.presentedRect, presenterCast.dataRowPaint);
      });

    });
  }
}

