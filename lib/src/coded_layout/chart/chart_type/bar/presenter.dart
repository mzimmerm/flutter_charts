import 'dart:ui' as ui show Rect, Offset, Paint;
// base libraries
import 'package:flutter_charts/src/coded_layout/chart/presenter.dart';
import 'package:flutter_charts/src/coded_layout/chart/container.dart';
import 'package:flutter_charts/src/coded_layout/chart/axis_container.dart';
import 'package:flutter_charts/src/chart/view_model/view_model.dart';

/// PointPresenterOCL of the atomic/leaf element of one data point on the
/// vertical bar chart - a simple rectangle, in member [presentedRect],
/// for which it calculates size and color.
///
/// See [PointPresenterOCL].
class VerticalBarPointPresenter extends PointPresenterOCL {
  late ui.Rect presentedRect;
  late ui.Paint valuesRowPaint;

  VerticalBarPointPresenter({
    required StackableValuePointOCL point,
    StackableValuePointOCL? nextRightColumnValuePoint,
    required int rowIndex,
    required ChartViewModel chartViewModel,
  }) : super(
          nextRightColumnValuePoint: nextRightColumnValuePoint,
          rowIndex: rowIndex,
          chartViewModel: chartViewModel,
        ) {
    // todo-1 move colors creation to super (shared for VerticalBar and LineAndHotspot)
    valuesRowPaint = ui.Paint();
    valuesRowPaint.color = chartViewModel.getLegendItemAt(rowIndex).color;

    ui.Offset barMidBottom = point.scaledFrom;
    ui.Offset barMidTop = point.scaledTo;
    HorizontalAxisContainerCL horizontalAxisContainerCL = chartViewModel.chartRootContainer.horizontalAxisContainer as HorizontalAxisContainerCL;
    double barWidth = horizontalAxisContainerCL.xGridStep *
        chartViewModel.chartOptions.dataContainerOptions.gridStepWidthPortionUsedByAtomicPointPresenter;

    ui.Offset barLeftTop = barMidTop.translate(-1 * barWidth / 2, 0.0);
    ui.Offset barRightBottom = barMidBottom.translate(1 * barWidth / 2, 0.0);

    presentedRect = ui.Rect.fromPoints(barLeftTop, barRightBottom);
  }
}

/// Creator of the [VerticalBarPointPresenter] instances - the leaf visual
/// elements on the bar chart (rectangle one data value).
///
/// See [PointPresenterCreatorOCL].
class VerticalBarLeafPointPresenterCreator extends PointPresenterCreatorOCL {
  VerticalBarLeafPointPresenterCreator() : super();

  @override
  PointPresenterOCL createPointPresenter({
    required StackableValuePointOCL point,
    StackableValuePointOCL? nextRightColumnValuePoint,
    required int rowIndex,
    required ChartViewModel chartViewModel,
  }) {
    return VerticalBarPointPresenter(
      point: point,
      nextRightColumnValuePoint: nextRightColumnValuePoint,
      rowIndex: rowIndex,
      chartViewModel: chartViewModel,
    );
  }
}
