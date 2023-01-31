import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/chart/container_layouter_base.dart';
import 'package:flutter_charts/src/chart/model/new_data_model.dart';

import '../container/container_key.dart';

// todo-00-document The container of chart columns.
class NewValuesColumnsContainer extends ChartAreaContainer with BuilderOfChildrenDuringParentLayout {
  // constructor:
  // create with all children: List<NewValuesColumnContainer> + ChartRootContainer


  NewValuesColumnsContainer({
    required ChartRootContainer chartRootContainer,
    // required List<BoxContainer> children,
  }) : super(
    chartRootContainer: chartRootContainer,
    //children: children,
  ) {
    // todo-00-last:
    // build
  }

  @override
  _NewSourceYContainerAndYContainerToSinkDataContainer findSourceContainersReturnLayoutResultsToBuildSelf() {
    return _NewSourceYContainerAndYContainerToSinkDataContainer(
      dataColumnsCount: chartRootContainer.dataColumnsCount,
    );
  }

  @override
  void layout() {
    //
  }

  @override
  void buildAndAddChildren_DuringParentLayout() {
    //
  }

// todo-00
// void applyParentConstraints - default
// void applyParentOffset - default
// void paint(Canvas convas) - default
}

// todo-00
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
