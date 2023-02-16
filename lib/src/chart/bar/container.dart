// base libraries
import '../container.dart';
import '../model/data_model_new.dart';
import '../view_maker.dart';

import '../options.dart';
import '../iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
import 'container_new.dart';
import 'presenter.dart'; // OLD


/// Container of the vertical bar chart.
///
/// The core override is setting the [pointPresenterCreator] -
/// object which makes instances of [VerticalBarPointPresenter]s,
/// which are, in turn, used to present each data value.
class VerticalBarChartRootContainer extends ChartRootContainer {
  VerticalBarChartRootContainer({
    required LegendContainer legendContainer,
    required XContainer      xContainer,
    required YContainer      yContainer,
    required DataContainer   dataContainer,
    required ChartViewMaker  chartViewMaker,
    required NewModel        chartData,
    required ChartOptions    chartOptions,
    required bool            isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
    legendContainer: legendContainer,
    xContainer: xContainer,
    yContainer: yContainer,
    dataContainer: dataContainer,
    chartViewMaker: chartViewMaker,
          chartData: chartData,
          chartOptions: chartOptions,
          isStacked: isStacked,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        ) {
    chartViewMaker.pointPresenterCreator = VerticalBarLeafPointPresenterCreator();
  }

  /* todo-00-last-last-last : moved to ChartViewMaker and extensions
  @override
  DataContainer createDataContainer({
    required ChartViewMaker chartViewMakerOnChartArea,
  }) {
    if (chartViewMakerOnChartArea.isUseOldDataContainer) {
      return VerticalBarChartDataContainer(
        chartViewMakerOnChartArea: chartViewMakerOnChartArea,
      );
    } else {
      return VerticalBarChartNewDataContainer(
        chartViewMakerOnChartArea: chartViewMakerOnChartArea,
      );
    }
  }
  */


/* todo-00-last-last : moved to VerticalBarChartViewMaker, as it controls view creation
  /// Implements [ChartBehavior] mixin abstract method.
  ///
  /// Overridden to [false] on this bar chart container, where the y axis must start from 0.
  ///
  @override
  bool get extendAxisToOrigin => true;
  */
}
