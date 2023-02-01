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

   List<NewValuesColumnContainer>  children = dataModel.createNewValuesColumnContainerList();

   addChildren(children);

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
  }) : super(
    chartRootContainer: chartRootContainer,
    children: children,
    key: key,
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

  @override
  void post_Leaf_SetSize_FromInternals() {
    layoutSize = const ui.Size(200.0, 200.0); // todo-00-last : implement this right - layoutSize should be from constraints, and all painting must fit within constraints
  }

  @override paint(ui.Canvas canvas) {
    // for now, put the offset calculation and scaling here . todo-00-last - where should they go?

    // todo-00-last : rect width should be from constraints

    // todo-00-last : rect height should be scaled from dataModelPoint.dataValue using chartRootContainer.yLabelsCreator
    double width = 180.0;
    YLabelsCreatorAndPositioner scaler = dataModelPoint.ownerSeries.dataModel.chartRootContainer.yLabelsCreator;
    // todo-00-last : double height = scaler.scaleY(value: dataModelPoint.dataValue);
    var transform = LinearTransform1D(
      fromDomainMin: scaler.fromDomainMin,
      fromDomainMax: scaler.fromDomainMax,
      toDomainMin: scaler.toDomainMax, // YES - min and max are flipped in scaler
      toDomainMax: scaler.toDomainMin,);
    double height = transform.transformValueToPixels(dataModelPoint.dataValue);

    ui.Rect rect = ui.Rect.fromLTWH(0.0, 0.0, width, height);

    // todo-00-last : rect color should be from dataModelPoint.
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
