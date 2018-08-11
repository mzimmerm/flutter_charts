import 'dart:ui' as ui show Rect, Offset, Paint;

import '../presenter.dart';
import '../container.dart';

/// Presenter of the atomic/leaf element of one data point on the
/// vertical bar chart - a simple rectangle, in member [presentedRect],
/// for which it calculates size and color.
///
/// See [Presenter].
class VerticalBarPresenter extends Presenter {

  ui.Rect presentedRect;
  ui.Paint dataRowPaint;

  VerticalBarPresenter({
    StackableValuePoint point,
    StackableValuePoint nextRightColumnValuePoint,
    int rowIndex,
    ChartContainer container,})
      : super(
    point: point,
    nextRightColumnValuePoint: nextRightColumnValuePoint,
    rowIndex: rowIndex,
    container: container,
  ){
    // todo-1 move colors creation to super (shared for VerticalBar and LineAndHotspot)
    dataRowPaint = new ui.Paint();
    dataRowPaint.color = container.data.dataRowsColors[rowIndex % container.data.dataRowsColors.length];

    ui.Offset barMidBottom     = point.scaledFrom;
    ui.Offset barMidTop        = point.scaledTo;
    double    barWidth         = container.gridStepWidth * container.options.gridStepWidthPortionUsedByAtomicPresenter;

    ui.Offset barLeftTop       = barMidTop.translate(-1 * barWidth / 2, 0.0);
    ui.Offset barRightBottom   = barMidBottom.translate(1 * barWidth / 2, 0.0);

    presentedRect = new ui.Rect.fromPoints(barLeftTop, barRightBottom);
  }
}

/// Creator of the [VerticalBarPresenter] instances - the leaf visual
/// elements on the bar chart (rectangle one data value).
///
/// See [PresenterCreator].
class VerticalBarLeafCreator extends PresenterCreator {

  VerticalBarLeafCreator() : super();

  Presenter createPointPresenter({
    StackableValuePoint point,
    StackableValuePoint nextRightColumnValuePoint,
    int rowIndex,
    ChartContainer container,
  }) {
    return new VerticalBarPresenter(
      point: point,
      nextRightColumnValuePoint: nextRightColumnValuePoint,
      rowIndex: rowIndex,
      container: container,
    );
  }
}