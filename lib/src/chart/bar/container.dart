import 'package:flutter_charts/flutter_charts.dart';
import '../iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
import 'presenter.dart';

import 'package:flutter_charts/src/chart/model/new_data_model.dart';

/// Concrete [ChartAnchor] for [VerticalBarChart].
///
/// See [ChartAnchor] for help.
class VerticalBarChartAnchor extends ChartAnchor {

  VerticalBarChartAnchor({
    required NewDataModel chartData, // todo-done-last-1 ChartData chartData,
    required bool isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
    chartData: chartData,
    isStacked: true, // only supported for now
    xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
  );

  /// Concrete implementation returns the root for vertical bar chart.
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
/// The core override is setting the [pointPresenterCreator] -
/// object which makes instances of [VerticalBarPointPresenter]s,
/// which are, in turn, used to present each data value.
class VerticalBarChartRootContainer extends ChartRootContainer {
  VerticalBarChartRootContainer({
    required NewDataModel chartData, // todo-done-last-1 ChartData chartData,
    required bool isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
          chartData: chartData,
          isStacked: isStacked,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        ) {
    pointPresenterCreator = VerticalBarLeafPointPresenterCreator();
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
