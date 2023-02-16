// base libraries
import '../container.dart';
import '../model/data_model_new.dart';
import '../view_maker.dart';

import '../options.dart';
import '../iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
import 'container_new.dart';
import 'presenter.dart'; // OLD


/// Container of the line chart.
///
/// The core override is setting the [pointPresenterCreator] -
/// object which makes instances of [LineAndHotspotPointPresenter]s,
/// which are, in turn, used to present each data value.
class LineChartRootContainer extends ChartRootContainer {
  LineChartRootContainer({
    // todo-00-last-last-last : put back : required LegendContainer legendContainer,
    // todo-00-last-last-last : put back : required XContainer      xContainer,
    // todo-00-last-last-last : put back : required YContainer      yContainer,
    // todo-00-last-last-last : put back : required DataContainer   dataContainer,
    required ChartViewMaker  chartViewMaker,
    required NewModel        chartData,
    required bool            isStacked,
    required ChartOptions   chartOptions,
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
    pointPresenterCreator = LineAndHotspotLeafPointPresenterCreator();
  }

  @override
  DataContainer createDataContainer({
    required ChartRootContainer chartRootContainer,
  }) {
    if (chartRootContainer.chartViewMaker.isUseOldDataContainer) {
      return LineChartDataContainer(
        chartRootContainer: chartRootContainer,
      );
    } else {
      return LineChartNewDataContainer(
        chartRootContainer: chartRootContainer,
      );
    }
  }

  /// Implements [ChartBehavior] mixin abstract method.
  ///
  /// If resolved to [true], Y axis will start on the minimum of Y values, otherwise at [0.0].
  ///
  /// This is the method used in code logic when building the Y labels and axis.
  ///
  /// The related variable [DataContainerOptions.extendAxisToOriginRequested],
  /// is merely a request that may not be granted in some situations.
  ///
  /// On this line chart container, allow the y axis start from 0 if requested by options.
  @override
  bool get extendAxisToOrigin => chartOptions.dataContainerOptions.extendAxisToOriginRequested;
}
