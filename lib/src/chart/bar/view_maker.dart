import '../view_maker.dart';
import '../model/new_data_model.dart';
import 'container.dart';

import '../iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

/// Concrete [ChartViewMaker] for [VerticalBarChart].
///
/// See [ChartViewMaker] for help.
class VerticalBarChartViewMaker extends ChartViewMaker {

  VerticalBarChartViewMaker({
    required NewModel chartData,
    required bool isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
    chartData: chartData,
    isStacked: true, // only supported for now
    xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
  ) {
    print('$runtimeType created');
  }

  /// Concrete implementation returns the root for vertical bar chart.
  @override
  VerticalBarChartRootContainer createRootContainer({required ChartViewMaker chartViewMaker}) {

    return VerticalBarChartRootContainer(
      chartViewMaker: chartViewMaker,
      chartData: chartData,
      chartOptions: chartViewMaker.chartOptions,
      isStacked: isStacked,
      xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
    );
  }
}
