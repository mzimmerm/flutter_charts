import 'dart:ui' as ui show Paint, PaintingStyle;

import 'package:flutter_charts/src/chart/options.dart';
import 'container.dart';

import 'package:flutter_charts/src/util/collection.dart' as custom_collection
    show CustomList;

// todo-1 refactor - can this be a behavior?
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
  // Not actually stored here, but could be
  // todo-00-last-unused
  StackableValuePoint point;
  StackableValuePoint? nextRightColumnValuePoint;
  int rowIndex;
  ChartContainer container;

  Presenter({
    required StackableValuePoint point,
    StackableValuePoint? nextRightColumnValuePoint,
    required int rowIndex,
    required ChartContainer container,
  })   : this.point = point,
        this.nextRightColumnValuePoint = nextRightColumnValuePoint,
        this.rowIndex = rowIndex,
        // todo-00 do we need to store the container, or just pass?
        this.container = container;
}

/// Manages and presents one "visual column" on the chart.
///
/// By one "visual column" here we mean the area above one label, which
/// shows all data value at that label, each value in one instance of
/// [Presenter].
class PresentersColumn {
  List<Presenter> presenters = new List.empty(growable: true);
  List<Presenter> positivePresenters = new List.empty(growable: true);
  List<Presenter> negativePresenters = new List.empty(growable: true);
  PresentersColumn? nextRightPointsColumn;

  PresentersColumn({
    required PointsColumn pointsColumn,
    required ChartContainer container,
    required PresenterCreator presenterCreator,
  }) {
    // setup the contained presenters from points
    _createPresentersInColumn(
        fromPoints: pointsColumn.stackableValuePoints,
        toPresenters: this.presenters,
        pointsColumn: pointsColumn,
        presenterCreator: presenterCreator,
        container: container);
    _createPresentersInColumn(
        fromPoints: pointsColumn.stackedPositivePoints,
        toPresenters: this.positivePresenters,
        pointsColumn: pointsColumn,
        presenterCreator: presenterCreator,
        container: container);
    _createPresentersInColumn(
        fromPoints: pointsColumn.stackedNegativePoints,
        toPresenters: this.negativePresenters,
        pointsColumn: pointsColumn,
        presenterCreator: presenterCreator,
        container: container);
  }

  void _createPresentersInColumn({
    required List<StackableValuePoint> fromPoints,
    required List toPresenters,
    required PointsColumn pointsColumn,
    required PresenterCreator presenterCreator,
    required ChartContainer container,
  }) {
    int rowIndex = 0;
    fromPoints.forEach((StackableValuePoint point) {
      // todo-2 nextRightPointsColumn IS LIKELY UNUSED, REMOVE.
      var nextRightColumnValuePoint = pointsColumn.nextRightPointsColumn != null
          ? pointsColumn.nextRightPointsColumn!.stackableValuePoints[rowIndex]
          : null;

      Presenter presenter = presenterCreator.createPointPresenter(
        point: point,
        nextRightColumnValuePoint: nextRightColumnValuePoint,
        rowIndex: point.dataRowIndex,
        container: container,
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
///   walk without the [presentersColumns] list.
class PresentersColumns extends custom_collection.CustomList<PresentersColumn> {
  PresentersColumns({
    required PointsColumns pointsColumns,
    required ChartContainer container,
    required PresenterCreator presenterCreator,
  }) {
    // iterate "column oriented", that is, over valuePointsColumns.
    PresentersColumn? leftPresentersColumn;
    pointsColumns.forEach((PointsColumn pointsColumn) {
      var presentersColumn = new PresentersColumn(
        pointsColumn: pointsColumn,
        container: container,
        presenterCreator: presenterCreator,
      );
      this.add(presentersColumn);
      leftPresentersColumn?.nextRightPointsColumn = presentersColumn;
      leftPresentersColumn = presentersColumn;
    });
  }
}

/// Maker of [Presenter] instances.
///
/// It's core method [createPointPresenter] creates [Presenter]s,
/// the visuals painted on each chart column that
/// represent data, (points and lines for the line chart,
/// rectangles for the bar chart, and so on).
///
/// The concrete creators make [LineAndHotspotPresenter], [VerticalBarPresenter]
/// and other concrete instances, depending on the chart type.
abstract class PresenterCreator {
  /// The container is generally needed for the creation of Presenters, as
  /// presenters may need some layout values.
  PresenterCreator(); // same as  {}

  Presenter createPointPresenter({
    required StackableValuePoint point,
    StackableValuePoint? nextRightColumnValuePoint,
    required int rowIndex,
    required ChartContainer container,
  });
}
