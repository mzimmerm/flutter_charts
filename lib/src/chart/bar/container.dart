import 'package:flutter_charts/src/chart/data.dart';
import 'package:flutter_charts/src/chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
import '../container.dart';

import 'presenter.dart';

/// Container of the vertical bar chart.
///
/// The core override is setting the [presenterCreator] -
/// object which makes instances of [VerticalBarPresenter]s,
/// which are, in turn, used to present each data value.
class VerticalBarChartTopContainer extends ChartTopContainer {
  VerticalBarChartTopContainer({
    required ChartData chartData,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
          chartData: chartData,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        ) {
    presenterCreator = VerticalBarLeafCreator();
  }

  @override
  VerticalBarChartDataContainer createDataContainer({
    required ChartTopContainer chartTopContainer,
  }) {
    return VerticalBarChartDataContainer(
      chartTopContainer: chartTopContainer,
    );
  }
}
