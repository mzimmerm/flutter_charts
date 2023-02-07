import 'dart:ui' as ui show Size, Rect, Paint, Canvas;
import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/chart/container_layouter_base.dart';
import 'package:flutter_charts/src/chart/layouter_one_dimensional.dart';
import 'package:flutter_charts/src/chart/model/new_data_model.dart';

import '../container/container_key.dart';

// todo-01-switch-from-command-arg class NewDataContainer extends ChartAreaContainer with BuilderOfChildrenDuringParentLayout {
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

   NewDataModel dataModel = chartRootContainer.data;

   List<NewValuesColumnContainer>  viewColumnList = dataModel.generateViewChildrenAsNewValuesColumnContainerList(chartRootContainer);

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
      dataColumnsCount: chartRootContainer.dataColumnsCount,
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

    // Rectangle height is Y scaled from dataModelPoint.dataValue using chartRootContainer.yLabelsCreator
    YLabelsCreatorAndPositioner yLabelsCreator = chartRootContainer.yContainer.yLabelsCreator;

    YContainer yContainer = chartRootContainer.yContainer;

    // todo-00-last : remove dependence on pixels (toDomain). Review where yLabelsCreator comes from and if needed
    var transform = DomainExtrapolation1D.valuesToPixels(
      fromValuesStart: yLabelsCreator.mergedIntervalsFromLabelsAndValues.min,
      fromValuesEnd: yLabelsCreator.mergedIntervalsFromLabelsAndValues.max,
      toPixelsStart: yContainer.yContainerAxisPixelsYMin,
      toPixelsEnd: yContainer.yContainerAxisPixelsYMin,
    ); // scaler.toDomainMax,);
    double height = transform.apply(dataModelPoint.dataValue);

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
