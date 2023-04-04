import 'dart:ui' as ui show Rect, Paint, Canvas;

// this level base libraries or equivalent
//import '../../morphic/container/chart_support/chart_orientation.dart';
import '../../morphic/container/chart_support/chart_orientation.dart' as chart_orientation;
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
                // Column first Row lays out positives, second Row negatives, X axis line between them
                // todo-00 : pull out as method ? this will become ChartEmbedLevel.level1PositiveNegativeArea
                Column(
                  children: [
                    // Row with columns of positive values
                    // todo-00 : pull out as method ? this will become ChartEmbedLevel.level2Bars
                    Row(
                      mainAxisConstraintsWeight: ConstraintsWeight(
                        weight: yLabelsGenerator.dataRange.ratioOfPositivePortion(),
                      ),
                      crossAxisAlign: Align.end, // cross default is matrjoska, non-default end aligned.
                      children: chartViewMaker.makeViewsForDataContainer_Bars(
                        crossPointsModelList: chartViewMaker.chartModel.crossPointsModelPositiveList,
                        pointsLayouterAlign: Align.start,
                        isPointsReversed: true,
                      ),
                    ),
                    // X axis line. Could place in Row with main constraints weight=0.0
                    AxisLineContainer(
                      // Creating a horizontal line between inputValue x min and x max, with outputValue y max.
                      // The reason for using y max: We want to paint HORIZONTAL line with 0 thickness, so
                      //   the layoutSize.height of the AxisLineContainer must be 0.
                      // That means, the AxisLineContainer INNER y pixel coordinates of both end points
                      //   must be 0 after all transforms.
                      // To achieve the 0 inner y pixel coordinates after all transforms, we need to start at the point
                      //   in y dataRange which transforms to 0 pixels. That point is y dataRange MAX, which we use here.
                      // See documentation in [PointOffset.lextrInContextOf] column section for details.
                      fromPointOffset: PointOffset(inputValue: xLabelsGenerator.dataRange.min, outputValue: yLabelsGenerator.dataRange.max),
                      toPointOffset:   PointOffset(inputValue: xLabelsGenerator.dataRange.max, outputValue: yLabelsGenerator.dataRange.max),
                      chartSeriesOrientation: chart_orientation.ChartSeriesOrientation.column,
                      linePaint: chartViewMaker.chartOptions.dataContainerOptions.gridLinesPaint(),
                      chartViewMaker: chartViewMaker,
                      // isLextrOnlyToValueSignPortion: false, // default : Lextr from full Y range (negative + positive portion)
                      isLextrUseSizerInsteadOfConstraint: true, // Lextr to full Sizer Height, AND Ltransf, not Lscale
                    ),
                    // Row with columns of negative values
                    Row(
                      mainAxisConstraintsWeight:
                          ConstraintsWeight(weight: yLabelsGenerator.dataRange.ratioOfNegativePortion()),
                      crossAxisAlign: Align.start, // cross default is matrjoska, non-default start aligned.
                      children: chartViewMaker.makeViewsForDataContainer_Bars(
                        crossPointsModelList: chartViewMaker.chartModel.crossPointsModelNegativeList,
                        pointsLayouterAlign: Align.start,
                        isPointsReversed: false,
                      ),
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
  final chart_orientation.ChartSeriesOrientation chartSeriesOrientation;
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
    required chart_orientation.ChartSeriesOrientation chartSeriesOrientation,
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


/* todo-010 - KEEP for now
  void layout() {
    buildAndReplaceChildren();

    Interval yDataRange = chartViewMaker.yLabelsGenerator.dataRange;

    // Using the pixel height [heightToLextr] of the [HeightSizerLayouter] (which wraps tightly the data container),
    //   lextr the data value to the [HeightSizerLayouter] pixel [length] (=[heightToLextr]) coordinates.
    //   Note: coordinates in self are always 0-based, so the [toPixelMin],
    //         which we lextr to in [HeightSizerLayouter], is 0.
    var lextr = ToPixelsLTransform1D(
      fromValuesMin: yDataRange.min,
      fromValuesMax: yDataRange.max,
      // KEEP as example of working without HeightSizer
      // var ownerDataContainerConstraints = chartViewMaker.chartRootContainer.dataContainer.constraints;
      // var padGroup = ChartPaddingGroup(fromChartOptions: chartViewMaker.chartOptions);
      // toPixelsMax: ownerDataContainerConstraints.size.height - padGroup.heightPadBottomOfYAndData(),
      // toPixelsMin: padGroup.heightPadTopOfYAndData(),

      toPixelsMin: 0.0,
      toPixelsMax: heightToLextr,
    );

    // Extrapolate the absolute value of data to height of the rectangle
    // (height represents the data value lextr-ed to data container pixels).
    // We convert data to positive size, the direction above/below axis is determined by the layouters
    //   in which the bars are located.
    double height = lextr.applyOnlyScaleOnLength(pointModel.outputValue.abs());

    // print('height=$height, value=${pointModel.outputValue.abs()}, '
    //     'dataRange.min=${yLabelsGenerator.dataRange.min}, dataRange.max=${yLabelsGenerator.dataRange.max}'
    //     'yContainer.axisPixelsRange.min=${yContainer.axisPixelsRange.min}, yContainer.axisPixelsRange.max=${yContainer.axisPixelsRange.max}');

    _rectangleSize = ui.Size(constraints.width, height);

    layoutSize = _rectangleSize;
  }
*/


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
