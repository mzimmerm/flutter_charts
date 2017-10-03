import 'dart:ui' as ui show Offset, Paint, PaintingStyle;

import 'package:flutter/painting.dart' as painting show TextPainter;
import 'package:flutter/widgets.dart' as widgets show Widget;
import 'package:flutter/material.dart' as material;

// MVC-M
import 'chart_options.dart';
// import 'chart_data.dart';

// MVC-VC
import 'layouters.dart'; // C


/// todo 0 document
class LinePresenter {
  ui.Paint paint;
  ui.Offset from;
  ui.Offset to;

  LinePresenter({ui.Offset from, ui.Offset to, ui.Paint paint}) {

    this.paint = paint;
    this.paint.strokeWidth = 3.0; // todo 1 set as option
    this.from = from;
    this.to = to;
  }
}

ui.Paint gridLinesPaint(ChartOptions options) {
  ui.Paint paint = new ui.Paint();
  paint.color = options.gridLinesColor;
  paint.style = ui.PaintingStyle.stroke;
  paint.strokeWidth = 1.0;

  return paint;
}


/// Represents the point at which data value is shown,
/// and the line from this point to the next point
/// on the right.
///
/// The line, is from this [valuePoint]
/// to the valuePoint of the PointAndLinePresenter
/// next in the [PointAndLinePresentersColumn]'s
/// [presenters] list.
class PointAndLinePresenter {

  // todo 1 consider: extends StackableValuePoint / ValuePresenter

  LinePresenter linePresenter;
  ui.Offset point; // value point
  ui.Paint innerPaint;
  ui.Paint outerPaint;
  double innerRadius;
  double outerRadius;
  ChartOptions options;

  PointAndLinePresenter({
    StackableValuePoint valuePoint,
    StackableValuePoint nextRightColumnValuePoint,
    int rowIndex,
    LineChartOptions options}) {

    ui.Paint linePresenterPaint = new ui.Paint();
    linePresenterPaint.color = options.dataRowsColors[rowIndex % options.dataRowsColors.length];

    ui.Offset fromPoint = valuePoint.to;
    ui.Offset toPoint = nextRightColumnValuePoint?.to;
    toPoint ??= fromPoint;
    linePresenter = new LinePresenter(
      from: fromPoint,
      to: toPoint,
      paint: linePresenterPaint,
    );
    this.point = fromPoint; // point is the left (from) end of the line
    this.innerPaint = new ui.Paint();
    this.innerPaint.color = material.Colors.yellow;
    this.outerPaint = new ui.Paint();
    this.outerPaint.color = material.Colors.black;
    this.innerRadius = options.hotspotInnerRadius;
    this.outerRadius = options.hotspotOuterRadius;

  }
}


class PointAndLinePresentersColumn {

// todo 1 consider:  extends ValuePointsColumn / ValuePresentersColumn / List

  List<PointAndLinePresenter> presenters = new List();
  PointAndLinePresentersColumn nextRightPointsColumn;

  PointAndLinePresentersColumn({
    ValuePointsColumn pointsColumn,
    LineChartOptions options}) {
    // setup the contained presenters from points
    int rowIndex = 0;
    pointsColumn.stackablePoints.forEach((StackableValuePoint stackablePoint) {
      var nextRightColumnValuePoint =
      pointsColumn.nextRightPointsColumn != null ? pointsColumn.nextRightPointsColumn.stackablePoints[rowIndex] : null;

      PointAndLinePresenter presenter = new PointAndLinePresenter(
        valuePoint: stackablePoint,
        nextRightColumnValuePoint: nextRightColumnValuePoint,
        rowIndex: rowIndex,
        options: options,
      );
      this.presenters.add(presenter);
      rowIndex++;
    });

  }

}

// todo 0 : write this in terms of abstracts, reuse implementation
class PointAndLinePresentersColumns {

  // todo 1 consider: extends ValuePresentersColumns or extend List

  List<PointAndLinePresentersColumn> presentersColumns = new List();

  PointAndLinePresentersColumns({
    ValuePointsColumns pointsColumns,
    LineChartOptions options,
  }) {
    // iterate "column first", that is, over valuePointsColumns.
    PointAndLinePresentersColumn leftPresentersColumn = null;
    pointsColumns.pointsColumns.forEach((ValuePointsColumn pointsColumn) {
      var presentersColumn = new PointAndLinePresentersColumn(
        pointsColumn: pointsColumn,
        options: options,
      );
      presentersColumns.add(presentersColumn);
      leftPresentersColumn?.nextRightPointsColumn = presentersColumn;
      leftPresentersColumn = presentersColumn;
    });
  }

  static StackableValuePoint createPoint(double x, double y, StackableValuePoint underThisPoint) {
    double fromY = underThisPoint == null ? 0.0 : underThisPoint.fromY; // Bar: toY
    return new StackableValuePoint(x: x, y: y, stackFromY: fromY);
  }
}
