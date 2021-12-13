import 'package:flutter_charts/src/chart/options.dart';
import 'package:flutter_charts/src/chart/data.dart';
import 'package:flutter_charts/src/chart/iterative_layout_strategy.dart'
    as strategy show LabelLayoutStrategy;
import '../container.dart';

import 'presenter.dart';

/// Container of the vertical bar chart.
///
/// The core override is setting the [presenterCreator] -
/// object which makes instances of [VerticalBarPresenter]s,
/// which are, in turn, used to present each data value.
class VerticalBarChartContainer extends ChartContainer {
  VerticalBarChartContainer({
    required ChartData chartData,
    required ChartOptions chartOptions,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
          chartData: chartData,
          chartOptions: chartOptions,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        ) {
    presenterCreator = VerticalBarLeafCreator();
  }

  VerticalBarChartDataContainer createDataContainer({
    required ChartContainer parentContainer,
  }) {
    return VerticalBarChartDataContainer(
      parentContainer: parentContainer,
    );
  }
  
}
