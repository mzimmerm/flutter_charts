// base libraries
import '../../../switch_view_maker/view_maker_cl.dart';
import '../container.dart';
import '../../../chart/container_new/legend_container_new.dart';
import '../../../chart/container_new/root_container_new.dart';
//import '../../../chart/container_new/data_container_new.dart';
//import '../../../chart/container_new/axis_container_new.dart';
//import '../../../chart/container_new/line/root_container_new.dart';
//import '../../../chart/container_new/bar/root_container_new.dart';
import '../../../chart/model/data_model_new.dart';
import '../../../chart/view_maker.dart';
import '../../../chart/options.dart';
import '../../../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
import 'presenter.dart'; // OLD


/// The container-hierarchy root container of the vertical bar chart in the coded_layout legacy version.
class VerticalBarChartRootContainerCL extends ChartRootContainerCL implements NewChartRootContainer {
  VerticalBarChartRootContainerCL({
    required LegendContainer legendContainer,
    required XContainerCL      xContainer,
    required YContainerCL      yContainerFirst,
    required YContainerCL      yContainer,
    required DataContainerCL   dataContainer,
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
    // todo-00-last-last-done : (chartViewMaker as SwitchChartViewMakerCL) : chartViewMaker.pointPresenterCreator = VerticalBarLeafPointPresenterCreator();
    (chartViewMaker as SwitchChartViewMakerCL).pointPresenterCreator = VerticalBarLeafPointPresenterCreator();
  }

}
