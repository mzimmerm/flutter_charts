// base libraries
import '../root_container_new.dart';
import '../axis_container_new.dart';
import '../data_container_new.dart';
import '../legend_container_new.dart';
import '../../model/data_model_new.dart';
import '../../view_maker.dart';

import '../../bar/container.dart' as old_bar_container;

import '../../options.dart';
import '../../iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
// import 'data_container_new.dart';
// import 'presenter.dart'; // OLD


/// Container of the vertical bar chart.
///
/// The core override is setting the [pointPresenterCreator] -
/// object which makes instances of [VerticalBarPointPresenter]s,
/// which are, in turn, used to present each data value.
class NewVerticalBarChartRootContainer extends NewChartRootContainer implements old_bar_container.VerticalBarChartRootContainer {
  NewVerticalBarChartRootContainer({
    required LegendContainer    legendContainer,
    required NewXContainer      xContainer,
    required NewYContainer      yContainerFirst,
    required NewYContainer      yContainer,
    required NewDataContainer   dataContainer,
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
    // OLD gone : chartViewMaker.pointPresenterCreator = VerticalBarLeafPointPresenterCreator();
  }

}