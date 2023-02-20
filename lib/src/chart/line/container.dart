import 'package:flutter_charts/src/chart/data.dart';
import 'package:flutter_charts/src/chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
import '../container.dart';
import '../options.dart';

import 'presenter.dart';

/// Container of the line chart.
///
/// The core override is setting the [presenterCreator] -
/// object which makes instances of [LineAndHotspotPresenter]s,
/// which are, in turn, used to present each data value.
class LineChartTopContainer extends ChartTopContainer {
  LineChartTopContainer({
    required ChartData chartData,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
          chartData: chartData,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        ) {
    presenterCreator = LineAndHotspotLeafCreator();
  }

  @override
  LineChartDataContainer createDataContainer({
    required ChartTopContainer chartTopContainer,
  }) {
    return LineChartDataContainer(
      chartTopContainer: chartTopContainer,
    );
  }

  /// Implements [ChartBehavior] mixin abstract method.
  ///
  /// If resolved to [true], Y axis will start on the minimum of Y values, otherwise at [0.0].
  ///
  /// This is the method used in code logic when building the Y labels and axis.
  ///
  /// The related variable [DataContainerOptions.startYAxisAtDataMinRequested],
  /// is merely a request that may not be granted in some situations.
  ///
  /// On this line chart container, allow the y axis start from 0 if requested by options.
  @override
  bool get startYAxisAtDataMinAllowed => data.chartOptions.dataContainerOptions.startYAxisAtDataMinRequested;
}
