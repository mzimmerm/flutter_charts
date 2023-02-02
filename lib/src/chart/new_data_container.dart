import 'dart:ui' as ui show Size, Rect, Paint, Canvas;
import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/chart/container_layouter_base.dart';
import 'package:flutter_charts/src/chart/model/new_data_model.dart';

import '../container/container_key.dart';

// todo-01-document The container of chart columns. NewValuesColumnsContainer - but we use the name NewDataContainer
class NewDataContainer extends ChartAreaContainer with BuilderOfChildrenDuringParentLayout {
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

   List<NewValuesColumnContainer>  viewColumnList = dataModel.generateViewChildrenAsNewValuesColumnContainerList();

    addChildren([
      Row(
        children: viewColumnList,
      )
    ]);
  }

  @override
  _NewSourceYContainerAndYContainerToSinkDataContainer findSourceContainersReturnLayoutResultsToBuildSelf() {
    return _NewSourceYContainerAndYContainerToSinkDataContainer(
      dataColumnsCount: chartRootContainer.dataColumnsCount,
    );
  }

// void layout() - default
// void applyParentConstraints - default
// void applyParentOffset - default
// void paint(Canvas convas) - default
}

class NewValuesColumnContainer extends ChartAreaContainer {
  NewDataModelSeries backingDataModelSeries;

  NewValuesColumnContainer({
    required ChartRootContainer chartRootContainer,
    required this.backingDataModelSeries,
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
    YLabelsCreatorAndPositioner scaler = dataModelPoint.ownerSeries.dataModel.chartRootContainer.yLabelsCreator;
    // double height = scaler.scaleY(value: dataModelPoint.dataValue);
    var transform = LinearTransform1D(
      fromDomainMin: scaler.fromDomainMin,
      fromDomainMax: scaler.fromDomainMax,
      toDomainMin: scaler.toDomainMax, // YES - min and max are flipped in scaler
      toDomainMax: scaler.toDomainMin,);
    double height = transform.scaleValueToYPixels(dataModelPoint.dataValue);

    _rectangleSize = ui.Size(width, height);

    layoutSize = _rectangleSize; // todo-00-last : implement this right - layoutSize should be from constraints, and all painting must fit within constraints
  }

  @override paint(ui.Canvas canvas) {
    // for now, put the offset calculation and scaling here . todo-00-last - where should they go?

    ui.Rect rect = offset & _rectangleSize;

    // Rectangle color should be from dataModelPoint's color.
    ui.Paint paint = ui.Paint();
    paint.color = dataModelPoint.color;

    canvas.drawRect(rect, paint);
  }
}

class _NewSourceYContainerAndYContainerToSinkDataContainer {
  final int dataColumnsCount;

  _NewSourceYContainerAndYContainerToSinkDataContainer({
    required this.dataColumnsCount,
  });
}
