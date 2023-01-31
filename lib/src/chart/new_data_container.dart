import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/chart/container_layouter_base.dart';
import 'package:flutter_charts/src/chart/model/new_data_model.dart';

import '../container/container_key.dart';

// todo-01-document The container of chart columns.
class NewValuesColumnsContainer extends ChartAreaContainer with BuilderOfChildrenDuringParentLayout {
  // constructor:
  // create with all children: List<NewValuesColumnContainer> + ChartRootContainer

  NewValuesColumnsContainer({
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

class NewValuesColumnContainer extends BoxContainer {
  NewDataModelSeries backingDataModelSeries;

  NewValuesColumnContainer({
    required this.backingDataModelSeries,
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    children: children,
    key: key,
  );
}

class NewValueContainer extends BoxContainer {
  NewDataModelPoint dataModelPoint;

  NewValueContainer({
    required this.dataModelPoint,
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    children: children,
    key: key,
  );
}

class _NewSourceYContainerAndYContainerToSinkDataContainer {
  final int dataColumnsCount;

  _NewSourceYContainerAndYContainerToSinkDataContainer({
    required this.dataColumnsCount,
  });
}
