import 'package:flutter_charts/src/chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
import '../container.dart';
import '../options.dart';

import 'presenter.dart';

import 'package:flutter_charts/src/chart/model/new_data_model.dart';

/// Concrete [ChartAnchor] for [LineChart].
///
/// See [ChartAnchor] for help.
class LineChartAnchor extends ChartAnchor {

  LineChartAnchor({
    required NewDataModel chartData, // todo-done-last-2 ChartData chartData,
    required bool isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
    chartData: chartData,
    isStacked: false, // only supported for now
    xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
  );

  /// Concrete implementation returns the root for line chart.
  @override
  LineChartRootContainer createRootContainer({required ChartAnchor chartAnchor}) {

    return LineChartRootContainer(
      chartAnchor: chartAnchor,
      chartData: chartData,
      isStacked: isStacked,
      xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
    );

  }

}

/// Container of the line chart.
///
/// The core override is setting the [pointPresenterCreator] -
/// object which makes instances of [LineAndHotspotPointPresenter]s,
/// which are, in turn, used to present each data value.
class LineChartRootContainer extends ChartRootContainer {
  LineChartRootContainer({
    required ChartAnchor chartAnchor,
    required NewDataModel chartData, // todo-done-last-2 ChartData chartData,
    required bool isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
          chartAnchor: chartAnchor,
          chartData: chartData,
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
  bool get extendAxisToOrigin => data.chartOptions.dataContainerOptions.extendAxisToOriginRequested;
}
