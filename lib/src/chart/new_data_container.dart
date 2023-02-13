import 'dart:ui' as ui show Size, Rect, Paint, Canvas;
import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/chart/container_layouter_base.dart';
import 'package:flutter_charts/src/chart/layouter_one_dimensional.dart';
import 'package:flutter_charts/src/chart/model/new_data_model.dart';

import '../container/container_key.dart';

// todo-done-last-3 : replaces PointsColumns
class NewDataContainer extends DataContainer {
  // constructor:
  // create with all children: List<NewValuesColumnContainer> + ChartRootContainer

  NewDataContainer({
    required ChartRootContainer chartRootContainer,
    // required List<BoxContainer> children,
  }) : super(
    chartRootContainer: chartRootContainer,
    //children: children,
  );

  @override
  void buildAndAddChildren_DuringParentLayout() {

   NewDataModel dataModel = chartRootContainer.chartViewMaker.chartData;

   List<NewValuesColumnContainer>  viewColumnList = dataModel.generateViewChildren_Of_NewDataContainer_As_NewValuesColumnContainer_List(chartRootContainer);

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
      dataColumnsCount: chartRootContainer.chartViewMaker.chartDataColumnsCount,
    );
  }
  */

// void layout() - default
// void applyParentConstraints - default
// void applyParentOffset - default
// void paint(Canvas convas) - default
}

class NewValuesColumnContainer extends ChartAreaContainer {
  NewDataModelSameXValues backingDataModelSameXValues;

  NewValuesColumnContainer({
    required ChartRootContainer chartRootContainer,
    required this.backingDataModelSameXValues,
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

class NewValueContainer extends ChartAreaContainer {
  NewDataModelPoint dataModelPoint;

  NewValueContainer({
    required ChartRootContainer chartRootContainer,
    required this.dataModelPoint,
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    chartRootContainer: chartRootContainer,
    children: children,
    key: key,
  );
}

/// See [LegendIndicatorRectContainer] for similar implementaion
class NewValueHBarContainer extends NewValueContainer {

  /// The rectangle representing the value.
  ///
  /// It's height represents [dataModelPoint.dataValue] scaled from the value range to the
  /// pixel height available for data in the vertical direction.
  ///
  /// It's size should be calculated in [layout], and used in [paint];
  late final ui.Size _rectangleSize;

  NewValueHBarContainer({
    required ChartRootContainer chartRootContainer,
    required NewDataModelPoint dataModelPoint,
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    dataModelPoint: dataModelPoint,
    chartRootContainer: chartRootContainer,
    children: children,
    key: key,
  );

  @override
  void layout() {
    // Calculate [_indicatorSize], the width and height of the Rectangle that represents data:

    // Rectangle width is from constraints
    double width = constraints.width;

    // Rectangle height is Y scaled from dataModelPoint.dataValue using chartRootContainer.yLabelsGenerator
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
    double height = lerp.applyAsLength(dataModelPoint.dataValue.abs());

    // print('height=$height, value=${dataModelPoint.dataValue.abs()}, '
    //     'dataRange.min=${yLabelsGenerator.dataRange.min}, dataRange.max=${yLabelsGenerator.dataRange.max}'
    //     'yContainer.axisPixelsRange.min=${yContainer.axisPixelsRange.min}, yContainer.axisPixelsRange.max=${yContainer.axisPixelsRange.max}');

    _rectangleSize = ui.Size(width, height);

    layoutSize = _rectangleSize;
  }

  @override paint(ui.Canvas canvas) {

    ui.Rect rect = offset & _rectangleSize;

    // Rectangle color should be from dataModelPoint's color.
    ui.Paint paint = ui.Paint();
    paint.color = dataModelPoint.color;

    canvas.drawRect(rect, paint);
  }
}

/* KEEP : comment out to allow ChartRootContainer.isUseOldDataContainer
class _NewSourceYContainerAndYContainerToSinkDataContainer {
  final int dataColumnsCount;

  _NewSourceYContainerAndYContainerToSinkDataContainer({
    required this.dataColumnsCount,
  });
}
*/
