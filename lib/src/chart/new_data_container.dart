import 'dart:ui' as ui show Size, Rect, Paint, Canvas;

import 'container.dart';
import 'container_layouter_base.dart';
import 'layouter_one_dimensional.dart';
import 'model/new_data_model.dart';

import '../container/container_key.dart';
import '../util/util_dart.dart';
import '../util/util_labels.dart' show DataRangeLabelsGenerator;

// todo-done-last-3 : replaces PointsColumns
class NewDataContainer extends DataContainer {
  // constructor:
  // create with all children: List<NewBarOfPointsContainer> + ChartRootContainer

  NewDataContainer({
    required ChartRootContainer chartRootContainer,
    // required List<BoxContainer> children,
  }) : super(
    chartRootContainer: chartRootContainer,
    //children: children,
  );

  @override
  void buildAndAddChildren_DuringParentLayout() {

   NewModel dataModel = chartRootContainer.chartViewMaker.chartData;

   List<NewBarOfPointsContainer>  viewColumnList = dataModel.generateViewChildren_Of_NewDataContainer_As_NewBarOfPointsContainer_List(chartRootContainer);

    addChildren([
      Row(
        children: viewColumnList,
        crossAxisAlign: Align.end, // cross axis is default matrjoska, non-default end aligned.
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

class NewBarOfPointsContainer extends ChartAreaContainer {
  NewBarOfPointsModel backingDataBarOfPointsModel;

  NewBarOfPointsContainer({
    required ChartRootContainer chartRootContainer,
    required this.backingDataBarOfPointsModel,
    List<BoxContainer>? children,
    ContainerKey? key,
    // We want to proportionally (evenly) layout if wrapped in Column, so make weight available.
    required ConstraintsWeight constraintsWeight,
  }) : super(
    chartRootContainer: chartRootContainer,
    children: children,
    key: key,
    constraintsWeight: constraintsWeight,
  );
}

class NewPointContainer extends ChartAreaContainer {
  NewPointModel newPointModel;

  NewPointContainer({
    required ChartRootContainer chartRootContainer,
    required this.newPointModel,
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    chartRootContainer: chartRootContainer,
    children: children,
    key: key,
  );
}

/// See [LegendIndicatorRectContainer] for similar implementaion
class NewHBarPointContainer extends NewPointContainer {

  /// The rectangle representing the value.
  ///
  /// It's height represents [newPointModel.dataValue] scaled from the value range to the
  /// pixel height available for data in the vertical direction.
  ///
  /// It's size should be calculated in [layout], and used in [paint];
  late final ui.Size _rectangleSize;

  NewHBarPointContainer({
    required ChartRootContainer chartRootContainer,
    required NewPointModel newPointModel,
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    newPointModel: newPointModel,
    chartRootContainer: chartRootContainer,
    children: children,
    key: key,
  );

  @override
  void layout() {
    // Calculate [_indicatorSize], the width and height of the Rectangle that represents data:

    // Rectangle width is from constraints
    double width = constraints.width;

    // Rectangle height is Y scaled from newPointModel.dataValue using chartRootContainer.yLabelsGenerator
    DataRangeLabelsGenerator yLabelsGenerator = chartRootContainer.yContainer.yLabelsGenerator;

    YContainer yContainer = chartRootContainer.yContainer;

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
