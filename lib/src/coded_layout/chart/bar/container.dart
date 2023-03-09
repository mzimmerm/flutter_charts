// base libraries
import '../container.dart';
import '../../../chart/container_new/legend_container_new.dart';
import '../../../chart/model/data_model_new.dart';
import '../../../chart/view_maker.dart';

import '../../../chart/options.dart';
import '../../../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
// import 'data_container_new.dart';
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
    required YContainer      yContainerFirst,
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
    yContainerFirst: yContainerFirst,
    yContainer: yContainer,
    dataContainer: dataContainer,
    chartViewMaker: chartViewMaker,
          chartData: chartData,
          isStacked: isStacked,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        ) {
    chartViewMaker.pointPresenterCreator = VerticalBarLeafPointPresenterCreator();
  }

}
