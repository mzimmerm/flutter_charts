import 'dart:ui' as ui show Offset, Paint, PaintingStyle;

import 'package:flutter/painting.dart' as painting show TextPainter;
import 'package:flutter/widgets.dart' as widgets show Widget;
import 'package:flutter/material.dart' as material;

import 'chart_options.dart';
import 'layouters.dart';


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

// todo -1 refactor - can this be a behavior?
ui.Paint gridLinesPaint(ChartOptions options) {
  ui.Paint paint = new ui.Paint();
  paint.color = options.gridLinesColor;
  paint.style = ui.PaintingStyle.stroke;
  paint.strokeWidth = 1.0;

  return paint;
}

/// Base class for todo 0 document
/// todo -1 remove options, we take them from _layout
class StackableValuePointPresenter {

  StackableValuePoint valuePoint;
  StackableValuePoint nextRightColumnValuePoint;
  int rowIndex;
  ChartLayouter layouter;

  StackableValuePointPresenter({
    StackableValuePoint valuePoint,
    StackableValuePoint nextRightColumnValuePoint,
    int rowIndex,
    ChartLayouter layouter,}) {
    this.valuePoint = valuePoint;
    this.nextRightColumnValuePoint = nextRightColumnValuePoint;
    this.rowIndex = rowIndex;
    this.layouter = layouter; // todo -2 do we need to store the layouter, or just pass?
  }
}

/// Represents the point at which data value is shown,
/// and the line from this point to the next point
/// on the right.
///
/// The line leads from this [valuePoint]
/// to the [valuePoint] of the [PointAndLinePresenter]
/// which is next in the [PresentersColumn.presenters] list.
///
// todo -1 can this be refactored and joined with / common code with / VerticalBarPresenter? see move colors creation to super
class PointAndLinePresenter extends StackableValuePointPresenter {

  // todo 1 consider: extends StackableValuePoint / ValuePresenter

  LinePresenter linePresenter;
  ui.Offset point; // offset where the data point will be painted
  ui.Paint innerPaint;
  ui.Paint outerPaint;
  double innerRadius;
  double outerRadius;

  PointAndLinePresenter({
    StackableValuePoint valuePoint,
    StackableValuePoint nextRightColumnValuePoint,
    int rowIndex,
    ChartLayouter layouter,
  })
      : super(
    valuePoint: valuePoint,
    nextRightColumnValuePoint: nextRightColumnValuePoint,
    rowIndex: rowIndex,
    layouter: layouter,
  ){
    // todo -1 move colors creation to super (shared for VerticalBar and PointAndLine)
    ui.Paint rowDataPaint = new ui.Paint();
    rowDataPaint.color = layouter.options.dataRowsColors[rowIndex % layouter.options.dataRowsColors.length];

    ui.Offset fromPoint = valuePoint.scaledTo;
    ui.Offset toPoint = nextRightColumnValuePoint?.scaledTo;
    toPoint ??= fromPoint;
    linePresenter = new LinePresenter(
      from: fromPoint,
      to: toPoint,
      paint: rowDataPaint,
    );
    this.point = fromPoint; // point is the left (from) end of the line
    this.innerPaint = new ui.Paint();
    this.innerPaint.color = material.Colors.yellow;
    this.outerPaint = new ui.Paint();
    this.outerPaint.color = material.Colors.black;
    this.innerRadius = (layouter.options as LineChartOptions).hotspotInnerRadius;
    this.outerRadius = (layouter.options as LineChartOptions).hotspotOuterRadius;
  }
}

// todo -2 make this an actual bar presenter
// todo -1 can this be refactored and joined with / common code with / PointAndLinePresenter? see move colors creation to super

class VerticalBarPresenter extends StackableValuePointPresenter {

  // todo -3 replace with BarPresenter
  LinePresenter linePresenter;
  ui.Offset point;

  VerticalBarPresenter({
    StackableValuePoint valuePoint,
    StackableValuePoint nextRightColumnValuePoint,
    int rowIndex,
    ChartLayouter layouter,})
      : super(
    valuePoint: valuePoint,
    nextRightColumnValuePoint: nextRightColumnValuePoint,
    rowIndex: rowIndex,
    layouter: layouter,
  ){

    // todo -1 move colors creation to super (shared for VerticalBar and PointAndLine)
    ui.Paint rowDataPaint = new ui.Paint();
    rowDataPaint.color = layouter.options.dataRowsColors[rowIndex % layouter.options.dataRowsColors.length];

    ui.Offset fromPoint = valuePoint.scaledTo;
    ui.Offset toPoint = nextRightColumnValuePoint?.scaledTo;
    toPoint ??= fromPoint;
    linePresenter = new LinePresenter(
      from: fromPoint,
      to: toPoint,
      paint: rowDataPaint,
    );
    this.point = fromPoint; // point is the left (from) end of the line

  }
}

/* todo -2 remove when Bar working.
class VerticalBarPresenter extends StackableValuePointPresenter {

  LinePresenter linePresenter;
  ui.Offset point;

  VerticalBarPresenter({
    StackableValuePoint valuePoint,
    StackableValuePoint nextRightColumnValuePoint,
    int rowIndex,
    LineChartOptions options})
      : super(
    valuePoint: valuePoint,
    nextRightColumnValuePoint: nextRightColumnValuePoint,
    rowIndex: rowIndex,
    options: options,
  ){

    ui.Paint rowDataPaint = new ui.Paint();
    rowDataPaint.color = options.dataRowsColors[rowIndex % options.dataRowsColors.length];

    ui.Offset fromPoint = valuePoint.scaledTo;
    ui.Offset toPoint = nextRightColumnValuePoint?.scaledTo;
    toPoint ??= fromPoint;
    linePresenter = new LinePresenter(
      from: fromPoint,
      to: toPoint,
      paint: rowDataPaint,
    );
    this.point = fromPoint; // point is the left (from) end of the line

  }
}

 */
class PresentersColumn {

// todo 1 consider: extends ValuePointsColumn / ValuePresentersColumn

  List<StackableValuePointPresenter> presenters = new List();
  PresentersColumn nextRightPointsColumn; // todo -2 address the base class (not a presenter)

  PresentersColumn({
    ValuePointsColumn pointsColumn,
    ChartLayouter layouter,
    PointAndPresenterCreator pointAndPresenterCreator,
  }) {
    // setup the contained presenters from points
    int rowIndex = 0;
    pointsColumn.stackablePoints.forEach((StackableValuePoint stackablePoint) {
      var nextRightColumnValuePoint =
      pointsColumn.nextRightPointsColumn != null ? pointsColumn.nextRightPointsColumn.stackablePoints[rowIndex] : null;

      StackableValuePointPresenter presenter = pointAndPresenterCreator.createPointPresenter(
        valuePoint: stackablePoint,
        nextRightColumnValuePoint: nextRightColumnValuePoint,
        rowIndex: rowIndex,
        layouter: layouter,
      );
      this.presenters.add(presenter);
      rowIndex++;
    });
  }
}

// todo -1 : write this in terms of abstracts, reuse implementation - may be done now
// todo -1 document
class PresentersColumns {

  // todo 1 consider: extends ValuePresentersColumns or extend List

  List<PresentersColumn> presentersColumns = new List();

  PresentersColumns({
    ValuePointsColumns pointsColumns,
    ChartLayouter layouter,
    PointAndPresenterCreator pointAndPresenterCreator,
  }) {
    // iterate "column first", that is, over valuePointsColumns.
    PresentersColumn leftPresentersColumn = null;
    pointsColumns.pointsColumns.forEach((ValuePointsColumn pointsColumn) {
      var presentersColumn = new PresentersColumn(
        pointsColumn: pointsColumn,
        layouter: layouter,
        pointAndPresenterCreator: pointAndPresenterCreator,
      );
      presentersColumns.add(presentersColumn);
      leftPresentersColumn?.nextRightPointsColumn = presentersColumn;
      leftPresentersColumn = presentersColumn;
    });
  }

}

// todo -1 document as creating the actual presenter of the value for chart - creates instances of PointAndLine Presenter and value, , VerticalBar
abstract class PointAndPresenterCreator {

  /// The layouter is generally needed for the creation of Presenters, as
  /// presenters may need some layout values.
  ///
  /// todo 0 : The question is , is it worth to narrow down the information
  ///          passed to something more narrow? (e.g. width of each column, etc)
  ChartLayouter _layouter;
  PointAndPresenterCreator({ChartLayouter layouter,})  {
    this._layouter = layouter;
  }

  StackableValuePoint createPoint({
    String xLabel,
    double y,
    StackableValuePoint underThisPoint,});

  StackableValuePointPresenter createPointPresenter({
    StackableValuePoint valuePoint,
    StackableValuePoint nextRightColumnValuePoint,
    int rowIndex,
    ChartLayouter layouter,
  });

}

class PointAndLineLeafCreator extends PointAndPresenterCreator {

  PointAndLineLeafCreator({ChartLayouter layouter,}) : super(layouter: layouter);

  StackableValuePoint createPoint({
    String xLabel,
    double y,
    StackableValuePoint underThisPoint,
  }) {
    double fromY = underThisPoint == null ? 0.0 : underThisPoint.fromY; // VerticalBar: toY
    return new StackableValuePoint(xLabel: null, y: y, stackFromY: fromY);  // fromY remains 0.0 for all hotspots
  }
    StackableValuePointPresenter createPointPresenter({
    StackableValuePoint valuePoint,
    StackableValuePoint nextRightColumnValuePoint,
    int rowIndex,
    ChartLayouter layouter,
  }) {
    return new PointAndLinePresenter(
      valuePoint: valuePoint,
      nextRightColumnValuePoint: nextRightColumnValuePoint,
      rowIndex: rowIndex,
      layouter: layouter,
    );
  }

}

class VerticalBarLeafCreator extends PointAndPresenterCreator {

  VerticalBarLeafCreator({ChartLayouter layouter,}) : super(layouter: layouter);

  StackableValuePoint createPoint({
    String xLabel,
    double y,
    StackableValuePoint underThisPoint,
  }) {
    double fromY = underThisPoint == null ? 0.0 : underThisPoint.toY; // PointAndLine: fromY
    return new StackableValuePoint(xLabel: null, y: y, stackFromY: fromY);
  }

  StackableValuePointPresenter createPointPresenter({
    StackableValuePoint valuePoint,
    StackableValuePoint nextRightColumnValuePoint,
    int rowIndex,
    ChartLayouter layouter,
  }) {
    return new VerticalBarPresenter(
      valuePoint: valuePoint,
      nextRightColumnValuePoint: nextRightColumnValuePoint,
      rowIndex: rowIndex,
      layouter: layouter,
    );
  }
}