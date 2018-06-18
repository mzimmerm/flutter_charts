import 'dart:ui' as ui;

import '../painter.dart';
import '../presenter.dart' as presenters;

import '../bar/presenter.dart' as bar_presenters;

/// Paints the columns of the bar chart.
///
/// The core override is the [drawPresentersColumns] method
/// which call on each column area of the chart, to paint the
/// [VerticalBarPresenter]s - painting a rectangle for
/// each data value across series.
///
/// See [ChartPainter]

class VerticalBarChartPainter extends ChartPainter {
  /// See super [ChartPainter.drawPresentersColumns].
  void drawPresentersColumns(ui.Canvas canvas) {
    presenters.PresentersColumns presentersColumns = this.container.dataContainer.presentersColumns;

     presentersColumns.forEach((presenters.PresentersColumn presentersColumn) {

      // todo-2 do not repeat loop, collapse to one construct

      var positivePresenterList = presentersColumn.positivePresenters;
      positivePresenterList = optionalPaintOrderReverse(positivePresenterList);
      positivePresenterList.forEach((presenters.Presenter presenter) {
        bar_presenters.VerticalBarPresenter presenterCast =
            presenter as bar_presenters.VerticalBarPresenter;
        canvas.drawRect(
            presenterCast.presentedRect, presenterCast.dataRowPaint);
      });

      var negativePresenterList = presentersColumn.negativePresenters;
      negativePresenterList = optionalPaintOrderReverse(negativePresenterList);
      negativePresenterList.forEach((presenters.Presenter presenter) {
        bar_presenters.VerticalBarPresenter presenterCast =
            presenter as bar_presenters.VerticalBarPresenter;
        canvas.drawRect(
            presenterCast.presentedRect, presenterCast.dataRowPaint);
      });

    });

  }
}
