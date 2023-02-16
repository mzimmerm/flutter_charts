import 'dart:ui' as ui show Rect, Offset, Paint, Color;
// base libraries
import '../presenter.dart';
import '../container.dart';
import '../view_maker.dart';

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
    required ChartViewMaker chartViewMakerOnChartArea,
  }) : super(
          nextRightColumnValuePoint: nextRightColumnValuePoint,
          rowIndex: rowIndex,
          chartViewMakerOnChartArea: chartViewMakerOnChartArea,
        ) {
    // todo-1 move colors creation to super (shared for VerticalBar and LineAndHotspot)
    dataRowPaint = ui.Paint();
    List<ui.Color> dataRowsColors = chartViewMakerOnChartArea.chartData.dataRowsColors; //!;
    dataRowPaint.color = dataRowsColors[rowIndex % dataRowsColors.length];

    ui.Offset barMidBottom = point.scaledFrom;
    ui.Offset barMidTop = point.scaledTo;
    double barWidth = chartViewMakerOnChartArea.xContainer.xGridStep *
        chartViewMakerOnChartArea.chartOptions.dataContainerOptions.gridStepWidthPortionUsedByAtomicPointPresenter;

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
    required ChartViewMaker chartViewMakerOnChartArea,
  }) {
    return VerticalBarPointPresenter(
      point: point,
      nextRightColumnValuePoint: nextRightColumnValuePoint,
      rowIndex: rowIndex,
      chartViewMakerOnChartArea: chartViewMakerOnChartArea,
    );
  }
}
