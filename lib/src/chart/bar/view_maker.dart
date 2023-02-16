// base libraries
import '../view_maker.dart';
import '../container.dart';
import '../model/data_model_new.dart';

import '../iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
import 'container.dart';
import 'container_new.dart';


/// Concrete [ChartViewMaker] for [VerticalBarChart].
///
/// See [ChartViewMaker] for help.
class VerticalBarChartViewMaker extends ChartViewMaker {

  VerticalBarChartViewMaker({
    required NewModel chartData,
    required bool isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
    chartData: chartData,
    isStacked: true, // only supported for now
    xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
  ) {
    print('$runtimeType created');
  }

  /// Concrete implementation returns the root for vertical bar chart.
  // todo-00-last : to super, move creation on XContainer, YContainer, etc, call super here explicitly
  @override
  VerticalBarChartRootContainer makeViewRoot({required ChartViewMaker chartViewMaker}) {

    // todo-00-last-last
    // Side-effect: Common place for creation of [legendContainer] [xContainer] [yContainer] [dataContainer]
    super.makeViewRootChildren(chartViewMaker: chartViewMaker);

    // todo-00-last : add args XContainer, YContainer, etc, values from chartViewMaker.makeViewForDomainAxis etc.

    return VerticalBarChartRootContainer(
      legendContainer: legendContainer,
      xContainer: xContainer,
      yContainer: yContainer,
      dataContainer: dataContainer,
      chartViewMaker: chartViewMaker,
      chartData: chartData,
      chartOptions: chartViewMaker.chartOptions,
      isStacked: isStacked,
      xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
    );
  }

  // todo-00-last-last-last : moved to ChartViewMaker and extensions
  @override
  DataContainer createDataContainer({
    required ChartViewMaker chartViewMakerOnChartArea,
  }) {
    if (chartViewMakerOnChartArea.isUseOldDataContainer) {
      return VerticalBarChartDataContainer(
        chartViewMakerOnChartArea: chartViewMakerOnChartArea,
      );
    } else {
      return VerticalBarChartNewDataContainer(
        chartViewMakerOnChartArea: chartViewMakerOnChartArea,
      );
    }
  }

  // todo-00-last-last : moved from ChartRootContainer, as it controls view creation
  /// Implements [ChartBehavior] mixin abstract method.
  ///
  /// Overridden to [false] on this bar chart container, where the y axis must start from 0.
  ///
  @override
  bool get extendAxisToOrigin => true;
}
