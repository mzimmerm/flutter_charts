// import 'dart:ui' as ui show Paint, PaintingStyle;

// this level or equivalent
import 'package:flutter_charts/src/coded_layout/chart/container.dart';

import 'package:flutter_charts/src/chart/view_model/view_model.dart';
import 'package:flutter_charts/src/util/collection.dart' as custom_collection show CustomList;

/// The visual element representing one data value (data point) on the chart.
///
/// Note: The data value displayed by this visual element is NOT held on this abstract,
/// it must be passed to concrete extensions such as [VerticalBarPointPresenter]
/// [LineAndHotspotPointPresenter], in the form of  [StackableValuePointOCL] point!
///
/// The member [rowIndex] is an extra piece of
/// information which allows to peek directly to the source data.
///
/// It serves the same role as the view (the [BoxContainer])
/// of one leaf data point in the auto-layout version.
///
/// For example, on a bar chart, this is one rectangle;
/// on a line chart this is a point with line connecting to the next
/// value point.
abstract class PointPresenterOCL {
  // Not actually stored here, but could be? StackableValuePointOCL point;
  StackableValuePointOCL? nextRightColumnValuePoint;
  int rowIndex;

  PointPresenterOCL({
    this.nextRightColumnValuePoint,
    required this.rowIndex,
    required ChartViewModel chartViewModel,
  });
}

/// Manages and presents one "visual column" on the chart.
///
/// By one "visual column" here we mean the area above one X label, which
/// shows all data value at that label, each value is presented by one instance of
/// [PointPresenterOCL].
class PointPresentersColumnOCL {
  List<PointPresenterOCL> pointPresenters = List.empty(growable: true);
  List<PointPresenterOCL> positivePointPresenters = List.empty(growable: true);
  List<PointPresenterOCL> negativePointPresenters = List.empty(growable: true);
  PointPresentersColumnOCL? nextRightPointsColumn;

  PointPresentersColumnOCL({
    required PointsColumnOCL pointsColumn,
    required ChartViewModel chartViewModel,
    required PointPresenterCreatorOCL pointPresenterCreator,
  }) {
    // setup the contained pointPresenters from points
    _createPointPresentersInColumn(
        fromPoints: pointsColumn.stackableValuePoints,
        toPointPresenters: pointPresenters,
        pointsColumn: pointsColumn,
        pointPresenterCreator: pointPresenterCreator,
        chartViewModel: chartViewModel);
    _createPointPresentersInColumn(
        fromPoints: pointsColumn.stackedPositivePoints,
        toPointPresenters: positivePointPresenters,
        pointsColumn: pointsColumn,
        pointPresenterCreator: pointPresenterCreator,
        chartViewModel: chartViewModel);
    _createPointPresentersInColumn(
        fromPoints: pointsColumn.stackedNegativePoints,
        toPointPresenters: negativePointPresenters,
        pointsColumn: pointsColumn,
        pointPresenterCreator: pointPresenterCreator,
        chartViewModel: chartViewModel);
  }

  void _createPointPresentersInColumn({
    required List<StackableValuePointOCL> fromPoints,
    required List toPointPresenters,
    required PointsColumnOCL pointsColumn,
    required PointPresenterCreatorOCL pointPresenterCreator,
    required ChartViewModel chartViewModel,
  }) {
    int rowIndex = 0;
    for (StackableValuePointOCL point in fromPoints) {
      StackableValuePointOCL? nextRightColumnValuePoint = pointsColumn.nextRightPointsColumn != null
          ? pointsColumn.nextRightPointsColumn!.stackableValuePoints[rowIndex]
          : null;

      PointPresenterOCL pointPresenter = pointPresenterCreator.createPointPresenter(
        point: point,
        nextRightColumnValuePoint: nextRightColumnValuePoint,
        rowIndex: point.valuesRowIndex,
        chartViewModel: chartViewModel,
      );
      toPointPresenters.add(pointPresenter);
      rowIndex++;
    }
  }
}

/// List of data column visual presenters, each item is [PointPresentersColumnOCL].
///
/// We say 'data column' because the presented data is 'column oriented'
/// list of data is managed by the passed
/// [PointsColumnsOCL.pointsColumns], and is a "source" for creating this object.
/// In addition to [PointsColumnsOCL.pointsColumns], a constructor
/// of this object needs to be given a way to create each "visual atomic widget"
/// to display each data value. This is provided with the passed
/// [PointPresenterCreatorOCL], which "create" methods know how to create the concrete
/// instances of the "atomic stacked display widget of the data value" using
///
///   [PointPresenterCreatorOCL.createPointPresenter]
///
/// Notes:
///   - In auto-layout situation, this class would be a [BoxContainer]
///     that lays out and displays columns (or rows, depending on orientation).
///   - Each [PointPresentersColumnOCL] element of [pointPresentersColumns]
///     manages a link to the [PointPresentersColumnOCL] on it's right, allowing
///     walk without the [pointPresentersColumns] list.
///
class PointPresentersColumnsOCL extends custom_collection.CustomList<PointPresentersColumnOCL> {
  PointPresentersColumnsOCL({
    required PointsColumnsOCL pointsColumns,
    required ChartViewModel chartViewModel,
    required PointPresenterCreatorOCL pointPresenterCreator,
  }) : super(growable: true)
  {
    // iterate "column oriented", that is, over valuePointsColumns.
    PointPresentersColumnOCL? leftPointPresentersColumn;
    for (PointsColumnOCL pointsColumn in pointsColumns) {
      var pointPresentersColumn = PointPresentersColumnOCL(
        pointsColumn: pointsColumn,
        chartViewModel: chartViewModel,
        pointPresenterCreator: pointPresenterCreator,
      );
      add(pointPresentersColumn);
      leftPointPresentersColumn?.nextRightPointsColumn = pointPresentersColumn;
      leftPointPresentersColumn = pointPresentersColumn;
    }
  }
}

/// Maker of [PointPresenterOCL] instances.
///
/// It serves the same role as [ChartViewModel] in the auto-layout version.
///
/// It's core method [createPointPresenter] creates [PointPresenterOCL]s,
/// the visuals painted on each chart column that
/// represent data, (points and lines for the line chart,
/// rectangles for the bar chart, and so on).
///
/// The concrete creators make [LineAndHotspotPointPresenter], [VerticalBarPointPresenter]
/// and other concrete instances, depending on the chart type.
abstract class PointPresenterCreatorOCL {
  /// The container is generally needed for the creation of PointPresenters, as
  /// pointPresenters may need some layout values.
  PointPresenterCreatorOCL(); // same as  {}

  PointPresenterOCL createPointPresenter({
    // Point is needed for VerticalBarPointPresenter to obtain scaledFrom and scaledTo for stacking
    required StackableValuePointOCL point,
    StackableValuePointOCL? nextRightColumnValuePoint,
    required int rowIndex,
    required ChartViewModel chartViewModel,
  });
}
