// base libraries
import '../container.dart';
import '../../../chart/container_new/legend_container_new.dart';
import '../../../chart/container_new/root_container_new.dart';
//import '../../../chart/container_new/container_common_new.dart';
//import '../../../chart/container_new/data_container_new.dart';
//import '../../../chart/container_new/axis_container_new.dart';
//import '../../../chart/container_new/line/root_container_new.dart';
//import '../../../chart/container_new/bar/root_container_new.dart';
import '../../../chart/model/data_model_new.dart';
import '../../../chart/view_maker.dart';

import '../../../chart/options.dart';
import '../../../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
// import 'data_container_new.dart';
import 'presenter.dart'; // OLD

/// Container of the line chart.
///
/// The core override is setting the [pointPresenterCreator] -
/// object which makes instances of [LineAndHotspotPointPresenter]s,
/// which are, in turn, used to present each data value.
// todo-00-last-last-done : class LineChartRootContainerCL extends ChartRootContainerCL {
// todo-00-last-last-progress : was : class LineChartRootContainerCL extends ChartRootContainerCL implements NewLineChartRootContainer {
class LineChartRootContainerCL extends ChartRootContainerCL implements NewChartRootContainer {
  LineChartRootContainerCL({
    required LegendContainer legendContainer,
    required XContainerCL xContainer,
    required YContainerCL yContainerFirst,
    required YContainerCL yContainer,
    required DataContainerCL dataContainer,
    required ChartViewMaker chartViewMaker,
    required NewModel chartData,
    required bool isStacked,
    required ChartOptions chartOptions,
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
    chartViewMaker.pointPresenterCreator = LineAndHotspotLeafPointPresenterCreator();
  }
}
