import 'dart:ui' as ui show Rect, Offset, Paint;

import '../presenters.dart';
import '../layouters.dart';

// todo -1 can this be refactored and joined with / common code with / LineAndHotspotPresenter? see move colors creation to super
/// todo 0 document
class VerticalBarPresenter extends Presenter {

  ui.Rect presentedRect;
  ui.Paint dataRowPaint;

  VerticalBarPresenter({
    StackableValuePoint point,
    StackableValuePoint nextRightColumnValuePoint,
    int rowIndex,
    ChartLayouter layouter,})
      : super(
    point: point,
    nextRightColumnValuePoint: nextRightColumnValuePoint,
    rowIndex: rowIndex,
    layouter: layouter,
  ){
    // todo -1 move colors creation to super (shared for VerticalBar and LineAndHotspot)
    dataRowPaint = new ui.Paint();
    dataRowPaint.color = layouter.options.dataRowsColors[rowIndex % layouter.options.dataRowsColors.length];

    // todo 0 simplify, unnecessary tmp vars
    ui.Offset barMidBottom     = point.scaledFrom;
    ui.Offset barMidTop        = point.scaledTo;
    double    barWidth         = layouter.gridStepWidth * layouter.options.gridStepWidthPortionUsedByAtomicPresenter;

    ui.Offset barLeftTop       = barMidTop.translate(-1 * barWidth / 2, 0.0);
    ui.Offset barRightBottom   = barMidBottom.translate(1 * barWidth / 2, 0.0);

    presentedRect = new ui.Rect.fromPoints(barLeftTop, barRightBottom);
  }
}

/// todo 0 document
class VerticalBarLeafCreator extends PresenterCreator {

  VerticalBarLeafCreator({ChartLayouter layouter,}) : super(layouter: layouter);

  Presenter createPointPresenter({
    StackableValuePoint point,
    StackableValuePoint nextRightColumnValuePoint,
    int rowIndex,
    ChartLayouter layouter,
  }) {
    return new VerticalBarPresenter(
      point: point,
      nextRightColumnValuePoint: nextRightColumnValuePoint,
      rowIndex: rowIndex,
      layouter: layouter,
    );
  }
}