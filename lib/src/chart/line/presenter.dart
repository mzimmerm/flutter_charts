import 'dart:ui' as ui show Offset, Paint, Color;

import '../presenter.dart';
import 'package:flutter_charts/src/chart/line/options.dart';
import '../container.dart';
import 'package:flutter_charts/src/chart/line_container.dart';


/// Presenter of the atomic/leaf element of one data point on the
/// line chart - the point at which data value is shown,
/// and the line from this data value point to the next data value point
/// on the right.
///
/// The line leads from this [offsetPoint]
/// to the [offsetPoint] of the [LineAndHotspotPresenter]
/// which is next in the [PresentersColumn.presenters] list.
class LineAndHotspotPresenter extends Presenter {
  late LineContainer lineContainer;
  late ui.Offset offsetPoint; // offset where the data point will be painted
  late ui.Paint innerPaint;
  late ui.Paint outerPaint;
  double innerRadius = 0.0; // todo-11-last-where-set-can-be-late?
  double outerRadius = 0.0; // todo-11-last-where-set-can-be-late?

  late ui.Paint rowDataPaint;

  LineAndHotspotPresenter({
    required StackableValuePoint point,
    StackableValuePoint? nextRightColumnValuePoint,
    required int rowIndex,
    required ChartTopContainer container,
  }) : super(
          point: point,
          nextRightColumnValuePoint: nextRightColumnValuePoint,
          rowIndex: rowIndex,
          container: container,
        ) {
    var options = container.options as LineChartOptions;

    // todo-1 move colors creation to super (shared for VerticalBar and LineAndHotspot)
    rowDataPaint = ui.Paint();
    // todo-00-last-last : consider why colors can even be null
    List<ui.Color> dataRowsColors = container.data.dataRowsColors!;
    rowDataPaint.color = dataRowsColors[rowIndex % dataRowsColors.length];

    ui.Offset fromPoint = point.scaledTo;
    ui.Offset? toPoint = nextRightColumnValuePoint?.scaledTo;
    toPoint ??= fromPoint;
    lineContainer = LineContainer(
        lineFrom: fromPoint, lineTo: toPoint, linePaint: rowDataPaint..strokeWidth = options.lineStrokeWidth);
    offsetPoint = fromPoint; // point is the left (from) end of the line
    innerPaint = ui.Paint()..color = options.hotspotInnerPaintColor;
    outerPaint = ui.Paint()..color = options.hotspotOuterPaintColor;
    innerRadius = options.hotspotInnerRadius;
    outerRadius = options.hotspotOuterRadius;
  }
}

/// Creator of the [LineAndHotspotPresenter] instances - the leaf visual
/// elements on the line chart (point and line showing one data value).
///
/// See [PresenterCreator].
class LineAndHotspotLeafCreator extends PresenterCreator {
  LineAndHotspotLeafCreator() : super();

  @override
  Presenter createPointPresenter({
    required StackableValuePoint point,
    StackableValuePoint? nextRightColumnValuePoint,
    required int rowIndex,
    required ChartTopContainer container,
  }) {
    return LineAndHotspotPresenter(
      point: point,
      nextRightColumnValuePoint: nextRightColumnValuePoint,
      rowIndex: rowIndex,
      container: container,
    );
  }
}
