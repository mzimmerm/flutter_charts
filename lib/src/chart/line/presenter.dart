import 'dart:ui' as ui show Offset, Paint, Color;

import '../presenter.dart';
import '../container.dart';
import '../../chart/line_container.dart';

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
  double innerRadius = 0.0;
  double outerRadius = 0.0;

  late ui.Paint rowDataPaint;

  LineAndHotspotPresenter({
    required StackableValuePoint point,
    StackableValuePoint? nextRightColumnValuePoint,
    required int rowIndex,
    required ChartRootContainer chartRootContainer,
  }) : super(
          point: point,
          nextRightColumnValuePoint: nextRightColumnValuePoint,
          rowIndex: rowIndex,
          chartRootContainer: chartRootContainer,
        ) {
    var options = chartRootContainer.data.chartOptions;

    // todo-1 move colors creation to super (shared for VerticalBar and LineAndHotspot)
    rowDataPaint = ui.Paint();
    List<ui.Color> dataRowsColors = chartRootContainer.data.dataRowsColors; //!;
    rowDataPaint.color = dataRowsColors[rowIndex % dataRowsColors.length];

    ui.Offset fromPoint = point.scaledTo;
    ui.Offset? toPoint = nextRightColumnValuePoint?.scaledTo;
    toPoint ??= fromPoint;
    lineContainer = LineContainer(
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
    required ChartRootContainer chartRootContainer,
  }) {
    return LineAndHotspotPresenter(
      point: point,
      nextRightColumnValuePoint: nextRightColumnValuePoint,
      rowIndex: rowIndex,
      chartRootContainer: chartRootContainer,
    );
  }
}
