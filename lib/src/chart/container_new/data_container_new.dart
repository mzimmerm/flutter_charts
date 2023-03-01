import 'dart:ui' as ui show Size, Rect, Paint, Canvas;

// this level base libraries or equivalent
import 'package:flutter_charts/src/chart/presenter.dart';

import 'container_common_new.dart' as container_common_new;
import '../container.dart' as container;
import '../container_layouter_base.dart' as container_base;
import '../model/data_model_new.dart' as model;
import '../view_maker.dart' as view_maker;
import '../layouter_one_dimensional.dart';
import '../../container/container_key.dart';
import '../../util/util_dart.dart';

class NewDataContainer extends container_common_new.ChartAreaContainer implements container.DataContainer {

  NewDataContainer({
    required view_maker.ChartViewMaker chartViewMaker,
  }) : super(
    chartViewMaker: chartViewMaker,
  );

  @override
  void buildAndReplaceChildren() {

    // Generate list of containers, each container represents one bar (chartViewMaker defines if horizontal or vertical)
    // This is the entry point where this container's [chartViewMaker] starts to generate this container (view).
    // todo-00!! move this up when higher containers converted to new.
    addChildren([
      container_base.Row(
        crossAxisAlign: Align.end, // cross axis is default matrjoska, non-default end aligned.
        children: chartViewMaker.makeViewsForDataAreaBars_As_CrossSeriesPoints_List(
          chartViewMaker,
          chartViewMaker.chartData.crossSeriesPointsList,
        ),
      )
    ]);
  }

  // --------------- overrides to implement legacy vvvvv
  @override
  PointPresentersColumns get pointPresentersColumns => throw UnimplementedError();
  @override
  set pointPresentersColumns(PointPresentersColumns _) => throw UnimplementedError();
  @override
  List<PointPresenter> optionalPaintOrderReverse(List<PointPresenter> pointPresenters) => throw UnimplementedError();
  // --------------- overrides to implement legacy ^^^^^

  /* KEEP : comment out to allow ChartRootContainer.isUseOldDataContainer
  @override
  _NewSourceYContainerAndYContainerToSinkDataContainer findSourceContainersReturnLayoutResultsToBuildSelf() {
    return _NewSourceYContainerAndYContainerToSinkDataContainer(
      dataBarsCount: chartRootContainer.chartViewMaker.chartDataBarsCount,
    );
  }
  */

// void layout() - default
// void applyParentConstraints - default
// void applyParentOffset - default
// void paint(Canvas convas) - default
}

class NewCrossSeriesPointsContainer extends container_common_new.ChartAreaContainer {
  model.NewCrossSeriesPointsModel backingDataCrossSeriesPointsModel;

  NewCrossSeriesPointsContainer({
    required view_maker.ChartViewMaker chartViewMaker,
    required this.backingDataCrossSeriesPointsModel,
    List<container_base.BoxContainer>? children,
    ContainerKey? key,
    // We want to proportionally (evenly) layout if wrapped in Column, so make weight available.
    required container_base.ConstraintsWeight constraintsWeight,
  }) : super(
    chartViewMaker: chartViewMaker,
    children: children,
    key: key,
    constraintsWeight: constraintsWeight,
  );
}

class NewPointContainer extends container_common_new.ChartAreaContainer {
  model.NewPointModel newPointModel;

  NewPointContainer({
    required this.newPointModel,
    required view_maker.ChartViewMaker chartViewMaker,
    List<container_base.BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    chartViewMaker: chartViewMaker,
    children: children,
    key: key,
  );
}

/// See [LegendIndicatorRectContainer] for similar implementation.
///
/// todo-00-last-last-last : For some new containers (those that need to be sized from values to pixels),
///                          add an interface that expresses: This is the provided of 'toPixelsMax', 'toPixelsMin' - basically the domain (scope) to which we extrapolate
///                          Maybe the interface should provide: direction (vertical, horizontal), boolean verticalProvided, horizontal provided, and Size - valued object for each direction (if boolean says so)
///                          For children of NewDataContainer, it will be NewDataContainer.constraints.
///                          For children of YContainer, it will be YContainer.constraints (???)
///                          Generally it must be an object that is known at layout time, and will not change - for example last cell in table,
class NewHBarPointContainer extends NewPointContainer {

  /// The rectangle representing the value.
  ///
  /// It's height represents [newPointModel.dataValue] extrapolated from the value range to the
  /// pixel height available for data in the vertical direction.
  ///
  /// It's size should be calculated in [layout], and used in [paint];
  late final ui.Size _rectangleSize;

  NewHBarPointContainer({
    required model.NewPointModel newPointModel,
    required view_maker.ChartViewMaker chartViewMaker,
    // todo-00!!! Do we need children and key? LineSegmentContainer does not have it.
    List<container_base.BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    newPointModel: newPointModel,
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

    // Rectangle height is Y extrapolated from newPointModel.dataValue using chartRootContainer.yLabelsGenerator
    Interval yDataRange = chartViewMaker.yLabelsGenerator.dataRange;

    // container.YContainer yContainer = chartViewMaker.chartRootContainer.yContainer; // todo-00-last-last : SHOULD WE BE ACCESSING yContainer here ?????

    // todo-00-last-last : This [layout] method we are in, is invoked BEFORE layoutSize of the owner DataContainer
    //                     is known (obviously). But we ASSUME that the owner DataContainer will use all it's constraints,
    //                     so that are the pixels we lextr to.
    var ownerDataContainerConstraints = chartViewMaker.chartRootContainer.dataContainer.constraints;

    var lextr = ToPixelsExtrapolation1D(
      fromValuesMin: yDataRange.min,
      fromValuesMax: yDataRange.max,
      /* todo-00-last-last : cannot ask for axisPixelsRange : Check in debugger how new layoutSize compares to axisPixelsRange
      toPixelsMin: yContainer.axisPixelsRange.min,
      toPixelsMax: yContainer.axisPixelsRange.max,
      toPixelsMin: 0.0,                          // yContainer.axisPixelsRange.min,
      toPixelsMax: yContainer.layoutSize.height, //  600.0, // yContainer.axisPixelsRange.max,
      */
      toPixelsMax: ownerDataContainerConstraints.size.height,
      toPixelsMin: 0.0, // ownerDataContainerConstraints.size.height
    );

    // Extrapolate the absolute value of data to height of the rectangle, representing the value in pixels.
    // We convert data to positive positive size, the direction above/below axis is determined by layouters.
    double height = lextr.applyAsLength(newPointModel.dataValue.abs());

    // print('height=$height, value=${newPointModel.dataValue.abs()}, '
    //     'dataRange.min=${yLabelsGenerator.dataRange.min}, dataRange.max=${yLabelsGenerator.dataRange.max}'
    //     'yContainer.axisPixelsRange.min=${yContainer.axisPixelsRange.min}, yContainer.axisPixelsRange.max=${yContainer.axisPixelsRange.max}');

    _rectangleSize = ui.Size(width, height);

    layoutSize = _rectangleSize;
  }

  @override paint(ui.Canvas canvas) {

    ui.Rect rect = offset & _rectangleSize;

    // Rectangle color should be from newPointModel's color.
    ui.Paint paint = ui.Paint();
    paint.color = newPointModel.color;

    canvas.drawRect(rect, paint);
  }
}

/* KEEP : comment out to allow ChartRootContainer.isUseOldDataContainer
class _NewSourceYContainerAndYContainerToSinkDataContainer {
  final int dataBarsCount;

  _NewSourceYContainerAndYContainerToSinkDataContainer({
    required this.dataBarsCount,
  });
}
*/
