// base libraries
import '../container.dart';
import '../model/data_model_new.dart';
import '../view_maker.dart';

import '../options.dart';
import '../iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
import 'container_new.dart';
import 'presenter.dart'; // OLD


/// Container of the vertical bar chart.
///
/// The core override is setting the [pointPresenterCreator] -
/// object which makes instances of [VerticalBarPointPresenter]s,
/// which are, in turn, used to present each data value.
class VerticalBarChartRootContainer extends ChartRootContainer {
  VerticalBarChartRootContainer({
    // todo-00-last-last-last : put back : required LegendContainer legendContainer,
    // todo-00-last-last-last : put back : required XContainer      xContainer,
    // todo-00-last-last-last : put back : required YContainer      yContainer,
    // todo-00-last-last-last : put back : required DataContainer   dataContainer,
    required ChartViewMaker  chartViewMaker,
    required NewModel        chartData,
    required ChartOptions    chartOptions,
    required bool            isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
          // todo-00-last-last-last : put back : legendContainer: legendContainer,
          // todo-00-last-last-last : put back : xContainer: xContainer,
          // todo-00-last-last-last : put back : yContainer: yContainer,
          // todo-00-last-last-last : put back : dataContainer: dataContainer,
          chartViewMaker: chartViewMaker,
          chartData: chartData,
          chartOptions: chartOptions,
          isStacked: isStacked,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        ) {
    pointPresenterCreator = VerticalBarLeafPointPresenterCreator();
  }

  @override
  DataContainer createDataContainer({
    required ChartRootContainer chartRootContainer,
  }) {
    if (chartRootContainer.chartViewMaker.isUseOldDataContainer) {
      return VerticalBarChartDataContainer(
        chartRootContainer: chartRootContainer,
      );
    } else {
      return VerticalBarChartNewDataContainer(
        chartRootContainer: chartRootContainer,
      );
    }
  }

  /// Implements [ChartBehavior] mixin abstract method.
  ///
  /// Overridden to [false] on this bar chart container, where the y axis must start from 0.
  ///
  @override
  bool get extendAxisToOrigin => true;
}
