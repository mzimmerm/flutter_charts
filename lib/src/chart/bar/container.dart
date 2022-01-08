import '../data.dart';
import '../iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
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

  /// Implements [ChartBehavior] mixin abstract method.
  /// 
  /// Overriden to [false] on this bar chart container, where the y axis must start from 0.
  /// 
  @override
  bool get startYAxisAtDataMinAllowed => false;
}
