// import 'dart:ui' as ui show Paint, PaintingStyle;

// this level or equivalent
import 'container.dart';
import '../../chart/view_maker.dart';
// import '../../chart/options.dart';
import '../../util/collection.dart' as custom_collection show CustomList;

// todo-00-last-done : moved to options
/*
ui.Paint gridLinesPaint(ChartOptions options) {
  ui.Paint paint = ui.Paint();
  paint.color = options.dataContainerOptions.gridLinesColor;
  paint.style = ui.PaintingStyle.stroke;
  paint.strokeWidth = 1.0;

  return paint;
}
*/

/// The visual element representing one data value on the chart.
///
/// It serves the same role as view - the [BoxContainer] - in the auto-layout version.
///
/// PointPresenter of the atomic/leaf element of one data point on the chart.
///
/// For example, on a bar chart, this is one rectangle;
/// on a line chart this is a point with line connecting to the next
/// value point.
class PointPresenter {
  // Not actually stored here, but could be
  // todo-04 : SURPRISINGLY, PointPresenter DOES NOT HOLD ONTO [StackableValuePoint point]. WHERE DOES IT GET IT FROM??
  // StackableValuePoint point;
  StackableValuePoint? nextRightColumnValuePoint;
  int rowIndex;

  PointPresenter({
    this.nextRightColumnValuePoint,
    required this.rowIndex,
    required ChartViewMaker chartViewMaker,
  });
}

/// Manages and presents one "visual column" on the chart.
///
/// By one "visual column" here we mean the area above one label, which
/// shows all data value at that label, each value in one instance of
/// [PointPresenter].
class PointPresentersColumn {
  List<PointPresenter> pointPresenters = List.empty(growable: true);
  List<PointPresenter> positivePointPresenters = List.empty(growable: true);
  List<PointPresenter> negativePointPresenters = List.empty(growable: true);
  PointPresentersColumn? nextRightPointsColumn;

  PointPresentersColumn({
    required PointsColumn pointsColumn,
    required ChartViewMaker chartViewMaker,
    required PointPresenterCreator pointPresenterCreator,
  }) {
    // setup the contained pointPresenters from points
    _createPointPresentersInColumn(
        fromPoints: pointsColumn.stackableValuePoints,
        toPointPresenters: pointPresenters,
        pointsColumn: pointsColumn,
        pointPresenterCreator: pointPresenterCreator,
        chartViewMaker: chartViewMaker);
    _createPointPresentersInColumn(
        fromPoints: pointsColumn.stackedPositivePoints,
        toPointPresenters: positivePointPresenters,
        pointsColumn: pointsColumn,
        pointPresenterCreator: pointPresenterCreator,
        chartViewMaker: chartViewMaker);
    _createPointPresentersInColumn(
        fromPoints: pointsColumn.stackedNegativePoints,
        toPointPresenters: negativePointPresenters,
        pointsColumn: pointsColumn,
        pointPresenterCreator: pointPresenterCreator,
        chartViewMaker: chartViewMaker);
  }

  void _createPointPresentersInColumn({
    required List<StackableValuePoint> fromPoints,
    required List toPointPresenters,
    required PointsColumn pointsColumn,
    required PointPresenterCreator pointPresenterCreator,
    required ChartViewMaker chartViewMaker,
  }) {
    int rowIndex = 0;
    for (StackableValuePoint point in fromPoints) {
      // todo-04-last nextRightPointsColumn IS LIKELY UNUSED, REMOVE.
      StackableValuePoint? nextRightColumnValuePoint = pointsColumn.nextRightPointsColumn != null
          ? pointsColumn.nextRightPointsColumn!.stackableValuePoints[rowIndex]
          : null;

      PointPresenter pointPresenter = pointPresenterCreator.createPointPresenter(
        point: point,
        nextRightColumnValuePoint: nextRightColumnValuePoint,
        rowIndex: point.valuesRowIndex,
        chartViewMaker: chartViewMaker,
      );
      toPointPresenters.add(pointPresenter);
      rowIndex++;
    }
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
/// to display each data value. This is provided with the passed
/// [PointPresenterCreator], which "create" methods know how to create the concrete
/// instances of the "atomic stacked display widget of the data value" using
///
///   [PointPresenterCreator.createPointPresenter]
///
/// Notes:
///   - Each [PointPresentersColumn] element of [pointPresentersColumns]
///     manages a link to the [PointPresentersColumn] on it's right, allowing
///     walk without the [pointPresentersColumns] list.
// todo-04-last : Convert PointPresentersColumns to BoxContainer, add methods 1) _createChildrenOfPointsColumns 2) buildAndReplaceChildren 3) layout
//                - each child is PointPresentersColumn
//                - still use everything in it the same
//                - find where to a) create this instance and b) where to call the newly added methods
///
class PointPresentersColumns extends custom_collection.CustomList<PointPresentersColumn> {
  PointPresentersColumns({
    required PointsColumns pointsColumns,
    required ChartViewMaker chartViewMaker,
    required PointPresenterCreator pointPresenterCreator,
  }) : super(growable: true)
  {
    // iterate "column oriented", that is, over valuePointsColumns.
    PointPresentersColumn? leftPointPresentersColumn;
    for (PointsColumn pointsColumn in pointsColumns) {
      var pointPresentersColumn = PointPresentersColumn(
        pointsColumn: pointsColumn,
        chartViewMaker: chartViewMaker,
        pointPresenterCreator: pointPresenterCreator,
      );
      add(pointPresentersColumn);
      leftPointPresentersColumn?.nextRightPointsColumn = pointPresentersColumn;
      leftPointPresentersColumn = pointPresentersColumn;
    }
  }
}

/// Maker of [PointPresenter] instances.
///
/// It serves the same role as [ChartViewMaker] in the auto-layout version.
///
/// It's core method [createPointPresenter] creates [PointPresenter]s,
/// the visuals painted on each chart column that
/// represent data, (points and lines for the line chart,
/// rectangles for the bar chart, and so on).
///
/// The concrete creators make [LineAndHotspotPointPresenter], [VerticalBarPointPresenter]
/// and other concrete instances, depending on the chart type.
abstract class PointPresenterCreator {
  /// The container is generally needed for the creation of PointPresenters, as
  /// pointPresenters may need some layout values.
  PointPresenterCreator(); // same as  {}

  PointPresenter createPointPresenter({
    // Point is needed for VerticalBarPointPresenter to obtain scaledFrom and scaledTo for stacking
    required StackableValuePoint point,
    StackableValuePoint? nextRightColumnValuePoint,
    required int rowIndex,
    required ChartViewMaker chartViewMaker,
  });
}
