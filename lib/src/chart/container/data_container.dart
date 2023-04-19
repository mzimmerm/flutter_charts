import 'dart:ui' as ui show Rect, Paint, Canvas;

// this level base libraries or equivalent
//import '../../morphic/container/chart_support/chart_orientation.dart';
import '../../morphic/container/chart_support/chart_orientation.dart';
import '../../morphic/ui2d/point.dart';
import '../../util/util_labels.dart';
import 'axis_container.dart';
import 'container_common.dart' as container_common;
import '../../morphic/container/container_layouter_base.dart';
import '../model/data_model.dart' as model;
import '../view_maker.dart';
import '../../morphic/container/container_edge_padding.dart';
import '../../morphic/container/layouter_one_dimensional.dart';
import '../options.dart';
import '../../morphic/container/container_key.dart';
//import 'line_segment_container.dart';

class DataContainer extends container_common.ChartAreaContainer {

  DataContainer({
    required ChartViewMaker chartViewMaker,
  }) : super(
    chartViewMaker: chartViewMaker,
  );

  // todo-011 : why do we construct in buildAndReplaceChildren here in DataContainer, while construct in constructor in NewVerticalAxisContainer???
  @override
  void buildAndReplaceChildren() {
    var options = chartViewMaker.chartOptions;
    var padGroup = ChartPaddingGroup(fromChartOptions: options);
    var outputLabelsGenerator = chartViewMaker.outputLabelsGenerator;
    var inputLabelsGenerator = chartViewMaker.inputLabelsGenerator;
    var chartSeriesOrientation = chartViewMaker.chartSeriesOrientation;

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
                // RowOrColumn's first item shows positive Bars, second item negative Bars, X axis line between them
                _buildLevel1PosNegAreasContainerAsRowOrColumn (
                  chartSeriesOrientation: chartSeriesOrientation,
                  children: [
                    // Row with columns of positive values
                    _buildLevel2PosOrNegBarsContainerAsRowOrColumn(
                      chartSeriesOrientation:           chartSeriesOrientation,
                      crossPointsModelPointsSign:       model.CrossPointsModelPointsSign.positiveOr0,
                      chartViewMaker:                   chartViewMaker,
                      inputLabelsGenerator:                 inputLabelsGenerator,
                      outputLabelsGenerator:                 outputLabelsGenerator,
                    ),
                    // X axis line. Could place in Row with main constraints weight=0.0
                    /* todo-00-KEEP */
                    TransposingInputAxisLineContainer(
                      inputLabelsGenerator: inputLabelsGenerator,
                      outputLabelsGenerator: outputLabelsGenerator,
                      chartViewMaker: chartViewMaker,
                    ),
                    /* */
                    // Row with columns of negative values
                    _buildLevel2PosOrNegBarsContainerAsRowOrColumn(
                      chartSeriesOrientation:           chartSeriesOrientation,
                      crossPointsModelPointsSign:       model.CrossPointsModelPointsSign.negative,
                      chartViewMaker:                   chartViewMaker,
                      inputLabelsGenerator:                 inputLabelsGenerator,
                      outputLabelsGenerator:                 outputLabelsGenerator,
                    ),
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
    /* todo-00-last-done :  replace w Transposing
       switch(chartSeriesOrientation) {
      case ChartSeriesOrientation.column:
        return Column(
          children: children,
          // Default. Both start and end work, as pos+neg fill whole area. Same applies fro crossAxisAlign, not set.
          mainAxisAlign: Align.start,
        );
      case ChartSeriesOrientation.row:
        return Row(
          // Reverse children compared to Column
          children: children.reversed.toList(),
          // Both start and end work, as pos+neg fill whole area. So use opposite of what Column uses.
          mainAxisAlign: Align.end,
        );
    }
    */

    /* */
    return TransposingRoller.Column(
      chartSeriesOrientation: chartSeriesOrientation,
      mainAxisAlign: Align.start, // todo-00-last-done : should not need, default
      children: children,
    );
    /* */

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
    required DataRangeLabelInfosGenerator             inputLabelsGenerator,
    required DataRangeLabelInfosGenerator             outputLabelsGenerator,
  }) {

    double ratioOfPositiveOrNegativePortion;
    bool isPointsReversed;
    Align mainAxisAlign;
    Align crossAxisAlign;
    List<model.CrossPointsModel> crossPointsModels;

    switch(crossPointsModelPointsSign) {
      case model.CrossPointsModelPointsSign.positiveOr0:
        crossPointsModels = chartViewMaker.chartModel.crossPointsModelPositiveList;
        ratioOfPositiveOrNegativePortion = outputLabelsGenerator.dataRange.ratioOfPositivePortion();
        isPointsReversed = true;
        mainAxisAlign = Align.end;  // main align does not matter, as bars fill up the whole bar area
        crossAxisAlign = Align.end; // cross align end for pos / start for neg push negative and positive together.
        break;
      case model.CrossPointsModelPointsSign.negative:
        crossPointsModels = chartViewMaker.chartModel.crossPointsModelNegativeList;
        ratioOfPositiveOrNegativePortion = outputLabelsGenerator.dataRange.ratioOfNegativePortion();
        isPointsReversed = false;
        mainAxisAlign = Align.start;
        crossAxisAlign = Align.start;
        break;
      case model.CrossPointsModelPointsSign.any:
        throw StateError('Invalid sign in this context.');
    }

    /* todo-00-last-done : replace w Transposing
    switch (chartSeriesOrientation) {
      case ChartSeriesOrientation.column:
        return Row(
          mainAxisConstraintsWeight: ConstraintsWeight(
            weight: ratioOfPositiveOrNegativePortion,
          ),
          mainAxisAlign: mainAxisAlign,
          crossAxisAlign: crossAxisAlign,
          children: chartViewMaker.makeViewsForDataContainer_Bars(
            crossPointsModelList: crossPointsModels,
            barsContainerMainAxisAlign: mainAxisAlign,
            isPointsReversed: isPointsReversed,
          ),
        );
      case ChartSeriesOrientation.row:
        return Column(
          mainAxisAlign: otherEndAlign(mainAxisAlign),
          crossAxisAlign: otherEndAlign(crossAxisAlign),
          mainAxisConstraintsWeight: ConstraintsWeight(
            weight: ratioOfPositiveOrNegativePortion,
          ),
          children: chartViewMaker.makeViewsForDataContainer_Bars(
            crossPointsModelList: crossPointsModels,
            barsContainerMainAxisAlign: otherEndAlign(mainAxisAlign),
            isPointsReversed: isPointsReversed,
          ).reversed.toList(),
        );
    }
   */


/* */
    var barsContainerMainAxisAlign1 = chartSeriesOrientation == ChartSeriesOrientation.column ? Align.start : Align.end; // todo-00-last-last-progress : added
    return TransposingRoller.Row(
      chartSeriesOrientation: chartSeriesOrientation,
      mainAxisConstraintsWeight: ConstraintsWeight(
        weight: ratioOfPositiveOrNegativePortion,
      ),
      mainAxisAlign: barsContainerMainAxisAlign1, // todo-00-last-last-progress : modified : mainAxisAlign, no luck
      crossAxisAlign: crossAxisAlign,
      children: chartViewMaker.makeViewsForDataContainer_Bars(
        crossPointsModelList: crossPointsModels,
        // todo-00-last : original code does otherEndAlign. do we need to resolve? Follow all the way down.
        barsContainerMainAxisAlign: mainAxisAlign,
        isPointsReversed: isPointsReversed,
      ),
    );
/* */

  }

}

class CrossPointsContainer extends container_common.ChartAreaContainer {

  CrossPointsContainer({
    required ChartViewMaker chartViewMaker,
    required this.crossPointsModel,
    List<BoxContainer>? children,
    ContainerKey? key,
    // We want to proportionally (evenly) layout if wrapped in Column or Row, so make weight available.
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

abstract class PointContainer extends container_common.ChartAreaContainer {

  PointContainer({
    required this.pointModel,
    required ChartViewMaker chartViewMaker,
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    chartViewMaker: chartViewMaker,
    children: children,
    key: key,
  );

  /// The [PointModel] presented by this container.
  model.PointModel pointModel;
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
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    pointModel: pointModel,
    chartViewMaker: chartViewMaker,
    children: children,
    key: key,
  );

  /// Full [layout] implementation calculates and set the final [_rectangleSize],
  /// the width and height of the Rectangle that represents data as pixels.
  @override
  void layout() {
    buildAndReplaceChildren();

    DataRangeLabelInfosGenerator inputLabelsGenerator = chartViewMaker.inputLabelsGenerator;
    DataRangeLabelInfosGenerator outputLabelsGenerator = chartViewMaker.outputLabelsGenerator;

    // Create PointOffset from this [pointModel] by giving it a range,
    // positions the [pointModel] on the x axis on it's label x coordinate.
    // The [pointOffset] can be lextr-ed to it's target value depending on chart direction.
    PointOffset pointOffset = pointModel.asPointOffsetOnInputRange(
          dataRangeLabelInfosGenerator: inputLabelsGenerator,
        );
    PointOffset pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartSeriesOrientation: chartViewMaker.chartSeriesOrientation,
      constraintsOnImmediateOwner: constraints,
      inputDataRange: inputLabelsGenerator.dataRange,
      outputDataRange: outputLabelsGenerator.dataRange,
      heightToLextr: heightToLextr,
      widthToLextr: widthToLextr,
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
