import '../data.dart';
import '../iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
import '../container.dart';

import 'presenter.dart';

class VerticalBarChartAnchor extends ChartAnchor {

/*
  VerticalBarChartAnchor({
    required ChartData chartData,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  })  : data = chartData,
        _cachedXContainerLabelLayoutStrategy = xContainerLabelLayoutStrategy,
        super() {
    parent = null;
  }
*/

  VerticalBarChartAnchor({
    required ChartData chartData,
    required bool isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
    chartData: chartData,
    isStacked: true, // only supported for now
    xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
  );

  @override
  VerticalBarChartRootContainer createRootContainer() {

    return VerticalBarChartRootContainer(
      chartData: chartData,
      isStacked: isStacked,
      xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
    );

  }

}

/// Container of the vertical bar chart.
///
/// The core override is setting the [presenterCreator] -
/// object which makes instances of [VerticalBarPresenter]s,
/// which are, in turn, used to present each data value.
class VerticalBarChartRootContainer extends ChartRootContainer {
  VerticalBarChartRootContainer({
    required ChartData chartData,
    required bool isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
          chartData: chartData,
          isStacked: isStacked,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        ) {
    presenterCreator = VerticalBarLeafCreator();
  }

  @override
  VerticalBarChartDataContainer createDataContainer({
    required ChartRootContainer chartRootContainer,
  }) {
    return VerticalBarChartDataContainer(
      chartRootContainer: chartRootContainer,
    );
  }

  /// Implements [ChartBehavior] mixin abstract method.
  ///
  /// Overridden to [false] on this bar chart container, where the y axis must start from 0.
  ///
  @override
  bool get startYAxisAtDataMinAllowed => false;
}
