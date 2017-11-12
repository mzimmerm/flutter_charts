import 'dart:ui' as ui show Paint, PaintingStyle;

import 'package:flutter_charts/src/chart/options.dart';
import 'layouters.dart';

// todo -1 refactor - can this be a behavior?
ui.Paint gridLinesPaint(ChartOptions options) {
  ui.Paint paint = new ui.Paint();
  paint.color = options.gridLinesColor;
  paint.style = ui.PaintingStyle.stroke;
  paint.strokeWidth = 1.0;

  return paint;
}

/// The visual element representing one data value on the chart.
///
/// Presenter of the atomic/leaf element of one data point on the chart.
///
/// For example, on a bar chart, this is one rectangle;
/// on a line chart this is a point with line connecting to the next
/// value point.
class Presenter {

  StackableValuePoint point;
  StackableValuePoint nextRightColumnValuePoint;
  int rowIndex;
  ChartLayouter layouter;

  Presenter({
    StackableValuePoint point,
    StackableValuePoint nextRightColumnValuePoint,
    int rowIndex,
    ChartLayouter layouter,}) {
    this.point = point;
    this.nextRightColumnValuePoint = nextRightColumnValuePoint;
    this.rowIndex = rowIndex;
    this.layouter = layouter; // todo 0 do we need to store the layouter, or just pass?
  }
}


/// Manages and presents one "visual column" on the chart.
///
/// By one "visual column" here we mean the area above one label, which
/// shows all data value at that label, each value in one instance of
/// [Presenter].
class PresentersColumn {


  List<Presenter> presenters = new List();
  List<Presenter> positivePresenters = new List();
  List<Presenter> negativePresenters = new List();
  PresentersColumn nextRightPointsColumn;

  PresentersColumn({
    PointsColumn pointsColumn,
    ChartLayouter layouter,
    PresenterCreator presenterCreator,
  }) {
    // setup the contained presenters from points
    _createPresentersInColumn(
        fromPoints: pointsColumn.points,
        toPresenters: this.presenters,
        pointsColumn: pointsColumn,
        presenterCreator: presenterCreator,
        layouter: layouter);
    _createPresentersInColumn(
        fromPoints: pointsColumn.stackedPositivePoints,
        toPresenters: this.positivePresenters,
        pointsColumn: pointsColumn,
        presenterCreator: presenterCreator,
        layouter: layouter);
    _createPresentersInColumn(
        fromPoints: pointsColumn.stackedNegativePoints,
        toPresenters: this.negativePresenters,
        pointsColumn: pointsColumn,
        presenterCreator: presenterCreator,
        layouter: layouter);
  }

  void _createPresentersInColumn({List fromPoints, List toPresenters, PointsColumn pointsColumn, PresenterCreator presenterCreator, ChartLayouter layouter,}) {
    int rowIndex = 0;
    fromPoints.forEach((StackableValuePoint point) {
      // todo -1 nextRightPointsColumn IS LIKELY UNUSED, REMOVE.
      var nextRightColumnValuePoint =
      pointsColumn.nextRightPointsColumn != null ? pointsColumn.nextRightPointsColumn.points[rowIndex] : null;

      Presenter presenter = presenterCreator.createPointPresenter(
        point: point,
        nextRightColumnValuePoint: nextRightColumnValuePoint,
        rowIndex: point.dataRowIndex,
        layouter: layouter,
      );
      toPresenters.add(presenter);
      rowIndex++;
    });
  }
}

/// Manages the visual elements (leafs) presented in each
/// "visual column" in chart - that is, all widgets representing
/// series of data displayed above each X label.
///
/// The "column oriented" list of data is managed by [PointsColumns.pointsColumns],
/// and is a "source" for creating this object.
/// In addition to [PointsColumns.pointsColumns], a constructor
/// of this object needs to be given a way to create each "visual atomic widget"
/// to display each data value. This is provided by the passed
/// [PresenterCreator], which "create" methods know how to create the concrete
/// instances of the "atomic stacked display widget of the data value" using
///
///   [PresenterCreator.createPointPresenter]
///
/// Notes:
///   - Each [PresentersColumn] element of [presentersColumns]
///   manages a link to the [PresentersColumn] on it's right, allowing
///   walk without the [presentersColumns] list. todo 0 consider if this is needed
class PresentersColumns {

  List<PresentersColumn> presentersColumns = new List();

  PresentersColumns({
    PointsColumns pointsColumns,
    ChartLayouter layouter,
    PresenterCreator presenterCreator,
  }) {
    // iterate "column oriented", that is, over valuePointsColumns.
    PresentersColumn leftPresentersColumn;
    pointsColumns.pointsColumns.forEach((PointsColumn pointsColumn) {
      var presentersColumn = new PresentersColumn(
        pointsColumn: pointsColumn,
        layouter: layouter,
        presenterCreator: presenterCreator,
      );
      presentersColumns.add(presentersColumn);
      leftPresentersColumn?.nextRightPointsColumn = presentersColumn;
      leftPresentersColumn = presentersColumn;
    });
  }

}

/// Maker of Presenter instances.
///
/// It's core method [createPointPresenter] creates [Presenter]s,
/// the visuals painted on each chart column that
/// represent data, (points and lines for the line chart,
/// rectangles for the bar chart, and so on).
///
/// The concrete creators make [LineAndHotspotPresenter], [VerticalBarPresenter]
/// and other concrete instances, depending on the chart type.
abstract class PresenterCreator {

  /// The layouter is generally needed for the creation of Presenters, as
  /// presenters may need some layout values.
  ChartLayouter _layouter;
  PresenterCreator({ChartLayouter layouter,})  {
    this._layouter = layouter;
  }

  Presenter createPointPresenter({
    StackableValuePoint point,
    StackableValuePoint nextRightColumnValuePoint,
    int rowIndex,
    ChartLayouter layouter,
  });

}

