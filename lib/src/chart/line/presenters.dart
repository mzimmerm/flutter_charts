import 'dart:ui' as ui show Offset, Paint;

import 'package:flutter/material.dart' as material;

import '../presenters.dart';
import 'package:flutter_charts/src/chart/line/options.dart';
import '../containers.dart';
import '../../util/line_presenter.dart' as line_presenter;


/// Presenter of the atomic/leaf element of one data point on the
/// line chart - the point at which data value is shown,
/// and the line from this data value point to the next data value point
/// on the right.
///
/// The line leads from this [offsetPoint]
/// to the [offsetPoint] of the [LineAndHotspotPresenter]
/// which is next in the [PresentersColumn.presenters] list.
class LineAndHotspotPresenter extends Presenter {

  line_presenter.LinePresenter linePresenter;
  ui.Offset offsetPoint; // offset where the data point will be painted
  ui.Paint innerPaint;
  ui.Paint outerPaint;
  double innerRadius;
  double outerRadius;

  ui.Paint rowDataPaint;

  LineAndHotspotPresenter({
    StackableValuePoint point,
    StackableValuePoint nextRightColumnValuePoint,
    int rowIndex,
    ChartContainer container,
  })
      : super(
    point: point,
    nextRightColumnValuePoint: nextRightColumnValuePoint,
    rowIndex: rowIndex,
    container: container,
  ){
    var options = container.options as LineChartOptions;

    // todo -1 move colors creation to super (shared for VerticalBar and LineAndHotspot)
    rowDataPaint = new ui.Paint();
    rowDataPaint.color = container.data.dataRowsColors[rowIndex % container.data.dataRowsColors.length];

    ui.Offset fromPoint = point.scaledTo;
    ui.Offset toPoint = nextRightColumnValuePoint?.scaledTo;
    toPoint ??= fromPoint;
    linePresenter = new line_presenter.LinePresenter(
      lineFrom: fromPoint,
      lineTo: toPoint,
      linePaint: rowDataPaint..strokeWidth = options.lineStrokeWidth
    );
    offsetPoint = fromPoint; // point is the left (from) end of the line
    innerPaint = options.hotspotInnerPaint;
    outerPaint = options.hotspotOuterPaint;
    innerRadius = options.hotspotInnerRadius;
    outerRadius = options.hotspotOuterRadius;
  }
}

/// Creator of the [LineAndHotspotPresenter] instances - the leaf visual
/// elements on the line chart (point and line showing one data value).
///
/// See [PresenterCreator].
class LineAndHotspotLeafCreator extends PresenterCreator {

  LineAndHotspotLeafCreator({ChartContainer container,}) : super(container: container);

  Presenter createPointPresenter({
    StackableValuePoint point,
    StackableValuePoint nextRightColumnValuePoint,
    int rowIndex,
    ChartContainer container,
  }) {
    return new LineAndHotspotPresenter(
      point: point,
      nextRightColumnValuePoint: nextRightColumnValuePoint,
      rowIndex: rowIndex,
      container: container,
    );
  }

}

