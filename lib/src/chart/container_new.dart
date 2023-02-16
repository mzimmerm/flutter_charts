import 'dart:ui' as ui show Size, Rect, Paint, Canvas;

// this level or equivalent
import 'container.dart' as container;
import 'container_layouter_base.dart' as container_base;
import 'model/data_model_new.dart' as model;
import 'view_maker.dart' as view_maker;
import 'layouter_one_dimensional.dart';
import '../container/container_key.dart';
import '../util/util_dart.dart';
import '../util/util_labels.dart' show DataRangeLabelsGenerator;

// todo-done-last-3 : replaces PointsColumns
class NewDataContainer extends container.DataContainer {
  // constructor:
  // create with all children: List<NewBarOfPointsContainer> + ChartRootContainer

  NewDataContainer({
    required view_maker.ChartViewMaker chartViewMakerOnChartArea,
    // required List<BoxContainer> children,
  }) : super(
    chartViewMakerOnChartArea: chartViewMakerOnChartArea,
    //children: children,
  );

  @override
  void buildAndAddChildren_DuringParentLayout() {
    // Get at my maker thru my root container.
    // The makes starts it's work on me down. todo-00 : The maker should start it's work on ChartRootContainer
    view_maker.ChartViewMaker chartViewMaker = chartViewMakerOnChartArea;

    // Generate list of containers, each container represents one bar (chartViewMaker defines if horizontal or vertical)
    // This is the entry point where this container's [chartViewMaker] starts to generate this container (view).
    // todo-00 move this up when higher containers converted to new.
    addChildren([
      container_base.Row(
        crossAxisAlign: Align.end, // cross axis is default matrjoska, non-default end aligned.
        children: chartViewMaker.makeViewsForDataAreaBars_As_BarOfPoints_List(
          chartViewMakerOnChartArea,
          chartViewMakerOnChartArea.chartData.barOfPointsList,
        ),
      )
    ]);
  }

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

class NewBarOfPointsContainer extends container.ChartAreaContainer {
  model.NewBarOfPointsModel backingDataBarOfPointsModel;

  NewBarOfPointsContainer({
    required view_maker.ChartViewMaker chartViewMakerOnChartArea,
    required this.backingDataBarOfPointsModel,
    List<container_base.BoxContainer>? children,
    ContainerKey? key,
    // We want to proportionally (evenly) layout if wrapped in Column, so make weight available.
    required container_base.ConstraintsWeight constraintsWeight,
  }) : super(
    chartViewMakerOnChartArea: chartViewMakerOnChartArea,
    children: children,
    key: key,
    constraintsWeight: constraintsWeight,
  );
}

class NewPointContainer extends container.ChartAreaContainer {
  model.NewPointModel newPointModel;

  NewPointContainer({
    required view_maker.ChartViewMaker chartViewMakerOnChartArea,
    required this.newPointModel,
    List<container_base.BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    chartViewMakerOnChartArea: chartViewMakerOnChartArea,
    children: children,
    key: key,
  );
}

/// See [LegendIndicatorRectContainer] for similar implementation
class NewHBarPointContainer extends NewPointContainer {

  /// The rectangle representing the value.
  ///
  /// It's height represents [newPointModel.dataValue] scaled from the value range to the
  /// pixel height available for data in the vertical direction.
  ///
  /// It's size should be calculated in [layout], and used in [paint];
  late final ui.Size _rectangleSize;

  NewHBarPointContainer({
    required view_maker.ChartViewMaker chartViewMakerOnChartArea,
    required model.NewPointModel newPointModel,
    List<container_base.BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    newPointModel: newPointModel,
    chartViewMakerOnChartArea: chartViewMakerOnChartArea,
    children: children,
    key: key,
  );

  @override
  void layout() {
    // Calculate [_indicatorSize], the width and height of the Rectangle that represents data:

    // Rectangle width is from constraints
    double width = constraints.width;

    // Rectangle height is Y scaled from newPointModel.dataValue using chartRootContainer.yLabelsGenerator
    DataRangeLabelsGenerator yLabelsGenerator = chartViewMakerOnChartArea.yContainer.yLabelsGenerator;

    container.YContainer yContainer = chartViewMakerOnChartArea.yContainer;

    var lerp = ToPixelsExtrapolation1D(
      fromValuesMin: yLabelsGenerator.dataRange.min,
      fromValuesMax: yLabelsGenerator.dataRange.max,
      toPixelsMin: yContainer.axisPixelsRange.min,
      toPixelsMax: yContainer.axisPixelsRange.max,
    );

    // Extrapolate the absolute value of data to height of the rectangle, representing the value in pixels.
    // We convert data to positive positive size, the direction above/below axis is determined by layouters.
    double height = lerp.applyAsLength(newPointModel.dataValue.abs());

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
