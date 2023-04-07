import 'dart:ui' as ui show Rect, Paint, Canvas;

// this level base libraries or equivalent
//import '../../morphic/container/chart_support/chart_orientation.dart';
import '../../morphic/container/chart_support/chart_orientation.dart';
import '../../morphic/ui2d/point.dart';
import '../../util/util_labels.dart';
import 'axis_container.dart';
import 'container_common.dart' as container_common_new;
import '../../morphic/container/container_layouter_base.dart';
import '../model/data_model.dart' as model;
import '../view_maker.dart';
import '../../morphic/container/container_edge_padding.dart';
import '../../morphic/container/layouter_one_dimensional.dart';
import '../options.dart';
import '../../morphic/container/container_key.dart';
//import 'line_segment_container.dart';

class DataContainer extends container_common_new.ChartAreaContainer {

  DataContainer({
    required ChartViewMaker chartViewMaker,
  }) : super(
    chartViewMaker: chartViewMaker,
  );

  // todo-011 : why do we construct in buildAndReplaceChildren here in DataContainer, while construct in constructor in NewYContainer???
  @override
  void buildAndReplaceChildren() {
    var options = chartViewMaker.chartOptions;
    var padGroup = ChartPaddingGroup(fromChartOptions: options);
    var yLabelsGenerator = chartViewMaker.yLabelsGenerator;
    var xLabelsGenerator = chartViewMaker.xLabelsGenerator;
    // todo-00
    //    - added chartSeriesOrientation (done)
    //    - FIND A METHOD TO SET AND PROPAGATE chartSeriesOrientation. MAYBE IT IS ON VERY TOP BARCHART (BARCHARTPAINTER?)
    var chartSeriesOrientation = ChartSeriesOrientation.column;

    // Generate list of containers, each container represents one bar (chartViewMaker defines if horizontal or vertical)
    // This is the entry point where this container's [chartViewMaker] starts to generate this container (view).
    addChildren([
      // Pad DataContainer on top and bottom from options. Children are height and width sizers
      Padder(
        edgePadding: EdgePadding.withSides(
          top: padGroup.heightPadTopOfYAndData(),
          bottom: padGroup.heightPadBottomOfYAndData(),
        ),
        child: HeightSizerLayouter(
          children: [
            WidthSizerLayouter(
              children: [
                // Column's first Row shows positive Bars, second Row negative Bars, X axis line between them
                // Column(
                _buildLevel1PosNegAreasContainerAsRowOrColumn (
                  chartSeriesOrientation: chartSeriesOrientation,
                  children: [
                    // Row with columns of positive values
                    // todo-00 : done : pulled method equivalent to ChartEmbedLevel.level2Bars
                    _buildLevel2PosOrNegBarsContainerAsRowOrColumn(
                      chartSeriesOrientation:           chartSeriesOrientation,
                      crossPointsModelPointsSign:       model.CrossPointsModelPointsSign.positiveOr0,
                      chartViewMaker:                   chartViewMaker,
                      xLabelsGenerator:                 xLabelsGenerator,
                      yLabelsGenerator:                 yLabelsGenerator,
                    ),
                    // X axis line. Could place in Row with main constraints weight=0.0
/* todo-00-last-done-keep
                    XAxisLineContainer(
                      xLabelsGenerator: xLabelsGenerator,
                      yLabelsGenerator: yLabelsGenerator,
                      chartViewMaker: chartViewMaker,
                    ),
*/
                    // Row with columns of negative values
                    _buildLevel2PosOrNegBarsContainerAsRowOrColumn(
                      chartSeriesOrientation:           chartSeriesOrientation,
                      crossPointsModelPointsSign:       model.CrossPointsModelPointsSign.negative,
                      chartViewMaker:                   chartViewMaker,
                      xLabelsGenerator:                 xLabelsGenerator,
                      yLabelsGenerator:                 yLabelsGenerator,
                    ),
                    /* KEEP for now
                    Row(
                      mainAxisConstraintsWeight:
                          ConstraintsWeight(weight: labelsGeneratorAlongSeries.dataRange.ratioOfNegativePortion()),
                      crossAxisAlign: Align.start, // cross default is matrjoska, non-default start aligned.
                      children: chartViewMaker.makeViewsForDataContainer_Bars(
                        crossPointsModelList: chartViewMaker.chartModel.crossPointsModelNegativeList,
                        pointsLayouterAlign: Align.start,
                        isPointsReversed: false,
                      ),
                    ),*/
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ]);
  }

  RollingBoxLayouter _buildLevel1PosNegAreasContainerAsRowOrColumn ({
    required ChartSeriesOrientation chartSeriesOrientation,
    required List<BoxContainer>     children,
  }) {
    switch(chartSeriesOrientation) {
      case ChartSeriesOrientation.column:
        return Column(
          children: children,

/* default
          Align mainAxisAlign = Align.start,
          Packing mainAxisPacking = Packing.tight,
          Align crossAxisAlign = Align.start,
          Packing crossAxisPacking = Packing.matrjoska,
          ConstraintsWeight mainAxisConstraintsWeight = ConstraintsWeight.defaultWeight,
*/
        );
      case ChartSeriesOrientation.row:
        return Row(
          children: children.reversed.toList(), // todo-00-done-added reversed
          mainAxisAlign: Align.end, // todo-00-done-added - start pulls bars to the left end to the right
          // crossAxisAlign: Align.end,// todo-00-done-added - start, end, center : no real difference
// todo-00-last-progress
/* default
          Align mainAxisAlign = Align.start,
          Packing mainAxisPacking = Packing.tight,
          Align crossAxisAlign = Align.center,
          Packing crossAxisPacking = Packing.matrjoska,
          ConstraintsWeight mainAxisConstraintsWeight = ConstraintsWeight.defaultWeight,
*/


        );
    }
  }


  /// For column chart, ([ChartSeriesOrientation.column]), build row    of (column) bars
  /// For row    chart, ([ChartSeriesOrientation.row])     build column of (row)    bars
  ///
  /// Either are build for only positive or only negative values,
  /// depending on
  RollingBoxLayouter _buildLevel2PosOrNegBarsContainerAsRowOrColumn({
    required ChartSeriesOrientation chartSeriesOrientation,
    required model.CrossPointsModelPointsSign         crossPointsModelPointsSign,
    required ChartViewMaker                           chartViewMaker,
    required DataRangeLabelInfosGenerator             xLabelsGenerator,
    required DataRangeLabelInfosGenerator             yLabelsGenerator,
  }) {

    DataRangeLabelInfosGenerator labelsGeneratorAcrossSeries;

    switch(chartSeriesOrientation) {
      case ChartSeriesOrientation.column:
        labelsGeneratorAcrossSeries = yLabelsGenerator;
        break;
      case ChartSeriesOrientation.row:
        // todo-00-last-last-last : done : maybe remove this section, and use y to define the ratio.  labelsGeneratorAcrossSeries = xLabelsGenerator;
        labelsGeneratorAcrossSeries = yLabelsGenerator;
        break;
    }

    double ratioOfPositiveOrNegativePortion;
    bool isPointsReversed;
    // todo-00-last-last-last : clarify main and cross, what they should be in all situations
    Align crossAxisAlign;
    Align mainAxisAlign;
    List<model.CrossPointsModel> crossPointsModels;

    switch(crossPointsModelPointsSign) {
      case model.CrossPointsModelPointsSign.positiveOr0:
        crossPointsModels = chartViewMaker.chartModel.crossPointsModelPositiveList;
        ratioOfPositiveOrNegativePortion = labelsGeneratorAcrossSeries.dataRange.ratioOfPositivePortion();
        isPointsReversed = true;
        mainAxisAlign = Align.end; // main does not really matter here. cross aligns to put negative and positive together.
        crossAxisAlign = Align.end;
        break;
      case model.CrossPointsModelPointsSign.negative:
        crossPointsModels = chartViewMaker.chartModel.crossPointsModelNegativeList;
        ratioOfPositiveOrNegativePortion = labelsGeneratorAcrossSeries.dataRange.ratioOfNegativePortion();
        isPointsReversed = false;
        mainAxisAlign = Align.start;
        crossAxisAlign = Align.start;
        break;
      case model.CrossPointsModelPointsSign.any:
        throw StateError('Invalid sign in this context.');
    }

    switch (chartSeriesOrientation) {
      case ChartSeriesOrientation.column:
        return Row(
          /* default
    Align mainAxisAlign = Align.start,
    Packing mainAxisPacking = Packing.tight,
    Align crossAxisAlign = Align.center,
    Packing crossAxisPacking = Packing.matrjoska,
    ConstraintsWeight mainAxisConstraintsWeight = ConstraintsWeight.defaultWeight,
           */
          mainAxisConstraintsWeight: ConstraintsWeight(
            weight: ratioOfPositiveOrNegativePortion,
          ),
          crossAxisAlign: crossAxisAlign,
          children: chartViewMaker.makeViewsForDataContainer_Bars(
            crossPointsModelList: crossPointsModels,
            crossPointsModelPointsSign: crossPointsModelPointsSign,
            // todo-00-last-last-experiment : why is this start??? It should be end : pointsLayouterAlign: Align.start,
            pointsLayouterAlign: Align.start,
            isPointsReversed: isPointsReversed,
          ),
        );
      case ChartSeriesOrientation.row:
        // todo-00-finish this. So far, I just changed Row to Column
        return Column(
          /*
    Align mainAxisAlign = Align.start,
    Packing mainAxisPacking = Packing.tight,
    Align crossAxisAlign = Align.start,
    Packing crossAxisPacking = Packing.matrjoska,
           */
          mainAxisAlign: otherEndAlign(mainAxisAlign), // todo-00-last-added
          mainAxisConstraintsWeight: ConstraintsWeight(
            weight: ratioOfPositiveOrNegativePortion,
          ),
          crossAxisAlign: otherEndAlign(crossAxisAlign),
          children: chartViewMaker.makeViewsForDataContainer_Bars(
            crossPointsModelList: crossPointsModels,
            crossPointsModelPointsSign: crossPointsModelPointsSign,
            pointsLayouterAlign: Align.start,
            isPointsReversed: isPointsReversed,
          ),
        );
    }
  }

}

class CrossPointsContainer extends container_common_new.ChartAreaContainer {

  CrossPointsContainer({
    required ChartViewMaker chartViewMaker,
    required this.crossPointsModel,
    List<BoxContainer>? children,
    ContainerKey? key,
    // We want to proportionally (evenly) layout if wrapped in Column, so make weight available.
    required ConstraintsWeight constraintsWeight,
  }) : super(
    chartViewMaker: chartViewMaker,
    children: children,
    key: key,
    constraintsWeight: constraintsWeight,
  );

  /// Model backing this container.
  model.CrossPointsModel crossPointsModel;
}

abstract class PointContainer extends container_common_new.ChartAreaContainer {

  PointContainer({
    required this.pointModel,
    required ChartViewMaker chartViewMaker,
    required this.chartSeriesOrientation,
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    chartViewMaker: chartViewMaker,
    children: children,
    key: key,
  );

  /// The [PointModel] presented by this container.
  model.PointModel pointModel;

  /// Orientation of the chart bars: horizontal or vertical.
  final ChartSeriesOrientation chartSeriesOrientation;
}

/// Container presents it's [pointModel] as a point on a line, or a rectangle in a bar chart.
///
/// See [LegendIndicatorRectContainer] for similar implementation.
///
/// It implements the mixins [WidthSizerLayouterChildMixin] and [HeightSizerLayouterChildMixin]
/// needed to lextr the [pointModel] to a position on the chart.
class BarPointContainer extends PointContainer with WidthSizerLayouterChildMixin, HeightSizerLayouterChildMixin {

  BarPointContainer({
    required model.PointModel pointModel,
    required ChartViewMaker chartViewMaker,
    required ChartSeriesOrientation chartSeriesOrientation,
    // todo-01 Do we need children and key? LineSegmentContainer does not have it.
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    pointModel: pointModel,
    chartViewMaker: chartViewMaker,
    chartSeriesOrientation: chartSeriesOrientation,
    children: children,
    key: key,
  );

  /// Full [layout] implementation calculates and set the final [_rectangleSize],
  /// the width and height of the Rectangle that represents data as pixels.
  @override
  void layout() {
    buildAndReplaceChildren();

    DataRangeLabelInfosGenerator xLabelsGenerator = chartViewMaker.xLabelsGenerator;
    DataRangeLabelInfosGenerator yLabelsGenerator = chartViewMaker.yLabelsGenerator;

    // Create PointOffset from this [pointModel] by giving it a range,
    // positions the [pointModel] on the x axis on it's label x coordinate.
    // The [pointOffset] can be lextr-ed to it's target value depending on chart direction.
    PointOffset pointOffset = pointModel.asPointOffsetOnInputRange(
          dataRangeLabelInfosGenerator: xLabelsGenerator,
        );
    PointOffset pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartSeriesOrientation: chartSeriesOrientation,
      constraintsOnImmediateOwner: constraints,
      inputDataRange: xLabelsGenerator.dataRange,
      outputDataRange: yLabelsGenerator.dataRange,
      heightToLextr: heightToLextr,
      widthToLextr: widthToLextr,
      isLextrOnlyToValueSignPortion: false,
      isLextrUseSizerInsteadOfConstraint: false,
    );

    // In the bar container, we only need the [pixelPointOffset.barPointRectSize]
    // which is the size of the rectangle presenting the point.
    // The offset, [pixelPointOffset] is used in line chart

    // The layoutSize is also the size of the rectangle, which, when positioned
    // by the parent layouter, presents the value of the [pointModel] on a bar chart.
    layoutSize = pixelPointOffset.barPointRectSize;
  }

  @override paint(ui.Canvas canvas) {

    ui.Rect rect = offset & layoutSize;

    // Rectangle color should be from pointModel's color.
    ui.Paint paint = ui.Paint();
    paint.color = pointModel.color;

    canvas.drawRect(rect, paint);
  }
}

/* KEEP : comment out to allow ChartRootContainer.isUseOldDataContainer
class _NewSourceYContainerAndYContainerToSinkDataContainer {
  final int valuesColumnsCount;

  _NewSourceYContainerAndYContainerToSinkDataContainer({
    required this.valuesColumnsCount,
  });
}
*/
