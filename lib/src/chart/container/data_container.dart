import 'dart:ui' as ui show Size, Rect, Paint, Canvas;

// this level base libraries or equivalent
import 'container_common.dart' as container_common_new;
import '../../morphic/container/container_layouter_base.dart';
import '../model/data_model.dart' as model;
import '../view_maker.dart';
import '../../morphic/container/container_edge_padding.dart';
import '../../morphic/container/layouter_one_dimensional.dart';
import '../options.dart';
import '../../morphic/container/container_key.dart';
import '../../util/util_dart.dart';

class DataContainer extends container_common_new.ChartAreaContainer {

  DataContainer({
    required ChartViewMaker chartViewMaker,
  }) : super(
    chartViewMaker: chartViewMaker,
  );

  // todo-00-last-01 : why do we construct in buildAndReplaceChildre here, but in constuctor in NewYContainer???
  @override
  void buildAndReplaceChildren() {

    var options = chartViewMaker.chartOptions;
    var padGroup = ChartPaddingGroup(fromChartOptions: options);

    // Generate list of containers, each container represents one bar (chartViewMaker defines if horizontal or vertical)
    // This is the entry point where this container's [chartViewMaker] starts to generate this container (view).
    // todo-00!! move this up when higher containers converted to new.
    addChildren([
      Padder(
        edgePadding: EdgePadding.withSides(
          top: padGroup.heightPadTopOfYAndData(),
          bottom: padGroup.heightPadBottomOfYAndData(),
        ),
        child: HeightSizerLayouter(
          children: [
            WidthSizerLayouter(
              children: [
                Row(
                  crossAxisAlign: Align.end, // cross axis is default matrjoska, non-default end aligned.
                  children: chartViewMaker.makeViewsForDataAreaBars_As_CrossSeriesPoints_List(
                    chartViewMaker.chartModel.crossSeriesPointsList,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ]);
  }

}

class CrossSeriesPointsContainer extends container_common_new.ChartAreaContainer {
  model.CrossSeriesPointsModel backingDataCrossSeriesPointsModel;

  CrossSeriesPointsContainer({
    required ChartViewMaker chartViewMaker,
    required this.backingDataCrossSeriesPointsModel,
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
/// todo-00-last-00 : For some new containers (those that need to be sized from values to pixels),
///                          add an interface that expresses: This is the provided of 'toPixelsMax', 'toPixelsMin' - basically the domain (scope) to which we extrapolate
///                          Maybe the interface should provide: direction (vertical, horizontal), boolean verticalProvided, horizontal provided, and Size - valued object for each direction (if boolean says so)
///                          For children of DataContainer, it will be DataContainer.constraints.
///                          For children of YContainer, it will be YContainer.constraints (???)
///                          Generally it must be an object that is known at layout time, and will not change - for example last cell in table,
class HBarPointContainer extends PointContainer with HeightSizerLayouterChild {

  /// The rectangle representing the value.
  ///
  /// It's height represents [pointModel.dataValue] extrapolated from the value range to the
  /// pixel height available for data in the vertical direction.
  ///
  /// It's size should be calculated in [layout], and used in [paint];
  late final ui.Size _rectangleSize;

  HBarPointContainer({
    required model.PointModel pointModel,
    required ChartViewMaker chartViewMaker,
    // todo-00!! Do we need children and key? LineSegmentContainer does not have it.
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

    // Rectangle height is Y extrapolated from pointModel.dataValue using chartRootContainer.yLabelsGenerator
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
    double height = lextr.applyAsLength(pointModel.dataValue.abs());

    // print('height=$height, value=${pointModel.dataValue.abs()}, '
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
