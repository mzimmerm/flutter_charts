import 'dart:ui' as ui show Rect, Offset, Paint, Color;

import '../presenter.dart';
import '../container.dart';

/// PointPresenter of the atomic/leaf element of one data point on the
/// vertical bar chart - a simple rectangle, in member [presentedRect],
/// for which it calculates size and color.
///
/// See [PointPresenter].
class VerticalBarPointPresenter extends PointPresenter {
  late ui.Rect presentedRect;
  late ui.Paint dataRowPaint;

  VerticalBarPointPresenter({
    required StackableValuePoint point,
    StackableValuePoint? nextRightColumnValuePoint,
    required int rowIndex,
    required ChartRootContainer chartRootContainer,
  }) : super(
          nextRightColumnValuePoint: nextRightColumnValuePoint,
          rowIndex: rowIndex,
          chartRootContainer: chartRootContainer,
        ) {
    // todo-1 move colors creation to super (shared for VerticalBar and LineAndHotspot)
    dataRowPaint = ui.Paint();
    List<ui.Color> dataRowsColors = chartRootContainer.data.dataRowsColors; //!;
    dataRowPaint.color = dataRowsColors[rowIndex % dataRowsColors.length];

    ui.Offset barMidBottom = point.scaledFrom;
    ui.Offset barMidTop = point.scaledTo;
    double barWidth = chartRootContainer.xContainer.xGridStep *
        chartRootContainer.chartOptions.dataContainerOptions.gridStepWidthPortionUsedByAtomicPointPresenter;

    ui.Offset barLeftTop = barMidTop.translate(-1 * barWidth / 2, 0.0);
    ui.Offset barRightBottom = barMidBottom.translate(1 * barWidth / 2, 0.0);

    presentedRect = ui.Rect.fromPoints(barLeftTop, barRightBottom);
  }
}

/// Creator of the [VerticalBarPointPresenter] instances - the leaf visual
/// elements on the bar chart (rectangle one data value).
///
/// See [PointPresenterCreator].
class VerticalBarLeafPointPresenterCreator extends PointPresenterCreator {
  VerticalBarLeafPointPresenterCreator() : super();

  @override
  PointPresenter createPointPresenter({
    required StackableValuePoint point,
    StackableValuePoint? nextRightColumnValuePoint,
    required int rowIndex,
    required ChartRootContainer chartRootContainer,
  }) {
    return VerticalBarPointPresenter(
      point: point,
      nextRightColumnValuePoint: nextRightColumnValuePoint,
      rowIndex: rowIndex,
      chartRootContainer: chartRootContainer,
    );
  }
}
