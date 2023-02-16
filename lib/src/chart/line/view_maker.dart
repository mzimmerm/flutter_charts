// base libraries
import '../view_maker.dart';
import '../container.dart';
import '../model/data_model_new.dart';

import '../iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
import 'container.dart';
import 'container_new.dart';

/// Concrete [ChartViewMaker] for [LineChart].
///
/// See [ChartViewMaker] for help.
class LineChartViewMaker extends ChartViewMaker {

  LineChartViewMaker({
    required NewModel chartData,
    required bool isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
    chartData: chartData,
    isStacked: false, // line chart only supports non-stacked for now
    xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
  );

  /// Concrete implementation returns the root for line chart.
  @override
  LineChartRootContainer makeViewRoot({required ChartViewMaker chartViewMaker}) {

    // Side-effect: Common place for creation of [legendContainer] [xContainer] [yContainer] [dataContainer]
    super.makeViewRootChildren(chartViewMaker: chartViewMaker);

    return LineChartRootContainer(
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

  @override
  DataContainer makeViewForDataContainer({
    required ChartViewMaker chartViewMaker,
  }) {
    if (chartViewMaker.isUseOldDataContainer) {
      return LineChartDataContainer(
        chartViewMaker: chartViewMaker,
      );
    } else {
      return LineChartNewDataContainer(
        chartViewMaker: chartViewMaker,
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
