// base libraries
import '../view_maker.dart';
import '../container.dart';
import '../model/data_model_new.dart';

import '../iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
import 'container.dart';
import 'container_new.dart';


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
  VerticalBarChartRootContainer makeViewRoot({required ChartViewMaker chartViewMaker}) {

    legendContainer = makeViewForLegendContainer();
    xContainer      = makeViewForDomainAxis();
    yContainer      = makeViewForRangeAxis();
    dataContainer   = makeViewForDataContainer();

    return VerticalBarChartRootContainer(
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
  DataContainer makeViewForDataContainer() {
    if (isUseOldDataContainer) {
      return VerticalBarChartDataContainer(
        chartViewMaker: this,
      );
    } else {
      return VerticalBarChartNewDataContainer(
        chartViewMaker: this,
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
