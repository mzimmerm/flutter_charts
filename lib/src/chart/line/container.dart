import 'new_data_container.dart';
import '../container.dart';
import '../model/new_data_model.dart';
import '../view_maker.dart';

import '../options.dart';

import 'presenter.dart'; // OLD

import '../iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

/// Container of the line chart.
///
/// The core override is setting the [pointPresenterCreator] -
/// object which makes instances of [LineAndHotspotPointPresenter]s,
/// which are, in turn, used to present each data value.
class LineChartRootContainer extends ChartRootContainer {
  LineChartRootContainer({
    required ChartViewMaker chartViewMaker,
    required NewModel chartData,
    required bool isStacked,
    required ChartOptions chartOptions,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
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
    if (chartRootContainer.isUseOldDataContainer) {
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
  // todo-00-last-done :   bool get extendAxisToOrigin => chartNewModelOnContainer.chartOptions.dataContainerOptions.extendAxisToOriginRequested;
  bool get extendAxisToOrigin => chartOptions.dataContainerOptions.extendAxisToOriginRequested;
}
