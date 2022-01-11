import 'dart:ui' as ui show Rect, Offset, Paint, Color;

import '../presenter.dart';
import '../container.dart';

/// Presenter of the atomic/leaf element of one data point on the
/// vertical bar chart - a simple rectangle, in member [presentedRect],
/// for which it calculates size and color.
///
/// See [Presenter].
class VerticalBarPresenter extends Presenter {
  late ui.Rect presentedRect;
  late ui.Paint dataRowPaint;

  VerticalBarPresenter({
    required StackableValuePoint point,
    StackableValuePoint? nextRightColumnValuePoint,
    required int rowIndex,
    required ChartTopContainer chartTopContainer,
  }) : super(
          point: point,
          nextRightColumnValuePoint: nextRightColumnValuePoint,
          rowIndex: rowIndex,
          chartTopContainer: chartTopContainer,
        ) {
    // todo-1 move colors creation to super (shared for VerticalBar and LineAndHotspot)
    dataRowPaint = ui.Paint();
    List<ui.Color> dataRowsColors = chartTopContainer.data.dataRowsColors; //!;
    dataRowPaint.color = dataRowsColors[rowIndex % dataRowsColors.length];

    ui.Offset barMidBottom = point.scaledFrom;
    ui.Offset barMidTop = point.scaledTo;
    double barWidth = chartTopContainer.xContainer.xGridStep *
        chartTopContainer.data.chartOptions.dataContainerOptions.gridStepWidthPortionUsedByAtomicPresenter;

    ui.Offset barLeftTop = barMidTop.translate(-1 * barWidth / 2, 0.0);
    ui.Offset barRightBottom = barMidBottom.translate(1 * barWidth / 2, 0.0);

    presentedRect = ui.Rect.fromPoints(barLeftTop, barRightBottom);
  }
}

/// Creator of the [VerticalBarPresenter] instances - the leaf visual
/// elements on the bar chart (rectangle one data value).
///
/// See [PresenterCreator].
class VerticalBarLeafCreator extends PresenterCreator {
  VerticalBarLeafCreator() : super();

  @override
  Presenter createPointPresenter({
    required StackableValuePoint point,
    StackableValuePoint? nextRightColumnValuePoint,
    required int rowIndex,
    required ChartTopContainer chartTopContainer,
  }) {
    return VerticalBarPresenter(
      point: point,
      nextRightColumnValuePoint: nextRightColumnValuePoint,
      rowIndex: rowIndex,
      chartTopContainer: chartTopContainer,
    );
  }
}
