import 'dart:ui' as ui show Offset, Paint;

// base libraries
import 'package:flutter_charts/src/coded_layout/chart/container.dart';
import 'package:flutter_charts/src/coded_layout/chart/line_container.dart';
import 'package:flutter_charts/src/coded_layout/chart/presenter.dart'; // OLD

import 'package:flutter_charts/src/chart/view_model/view_model.dart';

/// PointPresenter of the atomic/leaf element of one data point on the
/// line chart - the point at which data value is shown,
/// and the line from this data value point to the next data value point
/// on the right.
///
/// The line leads from this [offsetPoint]
/// to the [offsetPoint] of the [LineAndHotspotPointPresenter]
/// which is next in the [PointPresentersColumn.pointPresenters] list.
class LineAndHotspotPointPresenter extends PointPresenter {
  late LineContainerCL lineContainer;
  late ui.Offset offsetPoint; // offset where the data point will be painted
  late ui.Paint innerPaint;
  late ui.Paint outerPaint;
  double innerRadius = 0.0;
  double outerRadius = 0.0;

  late ui.Paint rowDataPaint;

  LineAndHotspotPointPresenter({
    required StackableValuePoint point,
    StackableValuePoint? nextRightColumnValuePoint,
    required int rowIndex,
    required ChartViewModel chartViewModel,
  }) : super(
          nextRightColumnValuePoint: nextRightColumnValuePoint,
          rowIndex: rowIndex,
          chartViewModel: chartViewModel,
        ) {
    var options = chartViewModel.chartOptions;

    // todo-1 move colors creation to super (shared for VerticalBar and LineAndHotspot)
    rowDataPaint = ui.Paint();
    rowDataPaint.color = chartViewModel.getLegendItemAt(rowIndex).color;

    ui.Offset fromPoint = point.scaledTo;
    ui.Offset? toPoint = nextRightColumnValuePoint?.scaledTo;
    toPoint ??= fromPoint;
    lineContainer = LineContainerCL(
        chartViewModel: chartViewModel,
        lineFrom: fromPoint,
        lineTo: toPoint,
        linePaint: rowDataPaint..strokeWidth = options.lineChartOptions.lineStrokeWidth);
    offsetPoint = fromPoint; // point is the left (from) end of the line
    innerPaint = ui.Paint()..color = options.lineChartOptions.hotspotInnerPaintColor;
    outerPaint = ui.Paint()..color = options.lineChartOptions.hotspotOuterPaintColor;
    innerRadius = options.lineChartOptions.hotspotInnerRadius;
    outerRadius = options.lineChartOptions.hotspotOuterRadius;
  }
}

/// Creator of the [LineAndHotspotPointPresenter] instances - the leaf visual
/// elements on the line chart (point and line showing one data value).
///
/// See [PointPresenterCreator].
class LineAndHotspotLeafPointPresenterCreator extends PointPresenterCreator {
  LineAndHotspotLeafPointPresenterCreator() : super();

  @override
  PointPresenter createPointPresenter({
    required StackableValuePoint point,
    StackableValuePoint? nextRightColumnValuePoint,
    required int rowIndex,
    required ChartViewModel chartViewModel,
  }) {
    return LineAndHotspotPointPresenter(
      point: point,
      nextRightColumnValuePoint: nextRightColumnValuePoint,
      rowIndex: rowIndex,
      chartViewModel: chartViewModel,
    );
  }
}
