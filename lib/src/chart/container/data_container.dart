import 'dart:ui' as ui show Size, Rect, Paint, Canvas;

// this level base libraries or equivalent
import '../../morphic/container/chart_support/chart_series_orientation.dart';
import '../../morphic/ui2d/point.dart';
import 'container_common.dart' as container_common_new;
import '../../morphic/container/container_layouter_base.dart';
import '../model/data_model.dart' as model;
import '../view_maker.dart';
import '../../morphic/container/container_edge_padding.dart';
import '../../morphic/container/layouter_one_dimensional.dart';
import '../options.dart';
import '../../morphic/container/container_key.dart';
import '../../util/util_dart.dart';
import 'line_segment_container.dart';

class DataContainer extends container_common_new.ChartAreaContainer {

  DataContainer({
    required ChartViewMaker chartViewMaker,
  }) : super(
    chartViewMaker: chartViewMaker,
  );

  // todo-01-next : why do we construct in buildAndReplaceChildren here in DataContainer, while construct in constructor in NewYContainer???
  @override
  void buildAndReplaceChildren() {
    var options = chartViewMaker.chartOptions;
    var padGroup = ChartPaddingGroup(fromChartOptions: options);

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
                // Column first Row lays out positives, second Row negatives
                Column(
                  children: [
                    // Row with columns of positive values
                    Row(
                      mainAxisConstraintsWeight: ConstraintsWeight(
                        weight: chartViewMaker.yLabelsGenerator.dataRange.ratioOfPositivePortion(),
                      ),
                      crossAxisAlign: Align.end, // cross default is matrjoska, non-default end aligned.
                      children: chartViewMaker.makeViewsForDataContainer_Bars_As_CrossPointsContainer_List(
                        crossPointsModelList: chartViewMaker.chartModel.crossPointsModelPositiveList,
                        pointsLayouterAlign: Align.start,
                        isPointsReversed: true,
                      ),
                    ),
                    // todo-00-last-progress adding LineSegment for axis line

/*
                    Row(
                      mainAxisConstraintsWeight: const ConstraintsWeight(weight: 0.0),
                      children: [
                        LineBetweenPointOffsetsContainer(
                          chartSeriesOrientation: ChartSeriesOrientation.column,
                          fromPointOffset: const PointOffset(inputValue: 0.0, outputValue: 0.0),
                          toPointOffset: const PointOffset(inputValue: 100.0, outputValue: 0.0),
                          linePaint: chartViewMaker.chartOptions.dataContainerOptions.gridLinesPaint(),
                          chartViewMaker: chartViewMaker,
                        ),
                      ],
                    ),
*/


                    // Row with columns of negative values
                    Row(
                      mainAxisConstraintsWeight: ConstraintsWeight(
                          weight: chartViewMaker.yLabelsGenerator.dataRange.ratioOfNegativePortion()),
                      crossAxisAlign: Align.start, // cross default is matrjoska, non-default start aligned.
                      children: chartViewMaker.makeViewsForDataContainer_Bars_As_CrossPointsContainer_List(
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

class PointContainer extends container_common_new.ChartAreaContainer {
  model.PointModel pointModel;

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
}

/// See [LegendIndicatorRectContainer] for similar implementation.
///
/// It implements the mixin [HeightSizerLayouterChildMixin] which expresses that this is the provided
/// of 'toPixelsMax', 'toPixelsMin' - basically the domain (scope) to which we extrapolate the height.
class HBarPointContainer extends PointContainer with HeightSizerLayouterChildMixin {

  /// The rectangle representing the value.
  ///
  /// It's height represents [pointModel.outputValue] extrapolated from the value range to the
  /// pixel height available for data in the vertical direction.
  ///
  /// It's size should be calculated in [layout], and used in [paint];
  late final ui.Size _rectangleSize;

  HBarPointContainer({
    required model.PointModel pointModel,
    required ChartViewMaker chartViewMaker,
    // todo-01 Do we need children and key? LineSegmentContainer does not have it.
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    pointModel: pointModel,
    chartViewMaker: chartViewMaker,
    children: children,
    key: key,
  );

  @override
  void layout() {
    buildAndReplaceChildren();
    // Calculate [_indicatorSize], the width and height of the Rectangle that represents data:

    // Rectangle width is from constraints
    double width = constraints.width;

    // Rectangle height is Y extrapolated from pointModel.outputValue using chartRootContainer.yLabelsGenerator
    Interval yDataRange = chartViewMaker.yLabelsGenerator.dataRange;

    // Using the pixel height [heightToLextr] of the [HeightSizerLayouter] (which wraps tightly the data container),
    //   lextr the data value to the [HeightSizerLayouter] pixel [length] (=[heightToLextr]) coordinates.
    //   Note: coordinates in self are always 0-based, so the [toPixelMin],
    //         which we lextr to in [HeightSizerLayouter], is 0.
    var lextr = ToPixelsExtrapolation1D(
      fromValuesMin: yDataRange.min,
      fromValuesMax: yDataRange.max,
      /* KEEP as example of working without HeightSizer
      var ownerDataContainerConstraints = chartViewMaker.chartRootContainer.dataContainer.constraints;
      var padGroup = ChartPaddingGroup(fromChartOptions: chartViewMaker.chartOptions);
      toPixelsMax: ownerDataContainerConstraints.size.height - padGroup.heightPadBottomOfYAndData(),
      toPixelsMin: padGroup.heightPadTopOfYAndData(),
      */
      toPixelsMin: 0.0,
      toPixelsMax: heightToLextr,
    );

    // Extrapolate the absolute value of data to height of the rectangle
    // (height represents the data value lextr-ed to data container pixels).
    // We convert data to positive size, the direction above/below axis is determined by the layouters
    //   in which the bars are located.
    double height = lextr.applyAsLength(pointModel.outputValue.abs());

    // print('height=$height, value=${pointModel.outputValue.abs()}, '
    //     'dataRange.min=${yLabelsGenerator.dataRange.min}, dataRange.max=${yLabelsGenerator.dataRange.max}'
    //     'yContainer.axisPixelsRange.min=${yContainer.axisPixelsRange.min}, yContainer.axisPixelsRange.max=${yContainer.axisPixelsRange.max}');

    _rectangleSize = ui.Size(width, height);

    layoutSize = _rectangleSize;
  }

  @override paint(ui.Canvas canvas) {

    ui.Rect rect = offset & _rectangleSize;

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
