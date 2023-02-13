// import 'new_data_container.dart';
import '../container.dart';
import '../model/new_data_model.dart';
import '../view_maker.dart';

import '../options.dart';

import 'presenter.dart'; // OLD

import '../iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

/// Container of the vertical bar chart.
///
/// The core override is setting the [pointPresenterCreator] -
/// object which makes instances of [VerticalBarPointPresenter]s,
/// which are, in turn, used to present each data value.
class VerticalBarChartRootContainer extends ChartRootContainer {
  VerticalBarChartRootContainer({
    required ChartViewMaker chartViewMaker,
    required NewModel chartData,
    required ChartOptions chartOptions,
    required bool isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
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
    if (chartRootContainer.isUseOldDataContainer) {
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
