import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/chart/container_layouter_base.dart';

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
  _NewSourceYContainerAndYContainerToSinkDataContainer findSourceContainersReturnLayoutResultsToBuildSelf() {
    return _NewSourceYContainerAndYContainerToSinkDataContainer(
      dataColumnsCount:
          chartRootContainer.dataColumnsCount,
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

// void applyParentConstraints - default
// void applyParentOffset - default
// void paint(Canvas convas) - default
}

class _NewSourceYContainerAndYContainerToSinkDataContainer {
  final int dataColumnsCount;

  _NewSourceYContainerAndYContainerToSinkDataContainer({
    required this.dataColumnsCount,
  });
}
