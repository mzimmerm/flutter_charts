import 'dart:ui' as ui;

import '../presenter.dart' as presenters;
import '../line/presenter.dart' as line_presenters;

import '../painter.dart';

/// Paints the columns of the line chart.
///
/// The core override is the [drawPresentersColumns] method
/// which call on each column area of the chart, to paint the
/// [LineAndHotspotPresenter]s - painting a point and line for
/// each data value across series.
///
/// See [ChartPainter]
class LineChartPainter extends ChartPainter {
  /// See super [ChartPainter.drawPresentersColumns].
  void drawPresentersColumns(ui.Canvas canvas) {
    var presentersColumns = this.container.dataContainer.presentersColumns;
    presentersColumns.forEach((presenters.PresentersColumn presentersColumn) {
      var presenterList = presentersColumn.presenters;
      presenterList = optionalPaintOrderReverse(presenterList);
      presenterList.forEach((presenters.Presenter presenter) {
        line_presenters.LineAndHotspotPresenter presenterCast =
            presenter as line_presenters.LineAndHotspotPresenter;
        // todo 0-future-minor Use call to Container.paint
        canvas.drawLine(
          presenterCast.lineContainer.lineFrom,
          presenterCast.lineContainer.lineTo,
          presenterCast.lineContainer.linePaint,
        );
        // todo 0-future-medium Add hotspot as Container, use Container.paint
        canvas.drawCircle(presenterCast.offsetPoint, presenterCast.outerRadius,
            presenterCast.outerPaint);
        canvas.drawCircle(presenterCast.offsetPoint, presenterCast.innerRadius,
            presenterCast.innerPaint);
      });
    });
  }
}
