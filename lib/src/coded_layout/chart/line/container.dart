// base libraries
import '../../../switch_view_maker/view_maker_cl.dart';
import '../container.dart';
import '../../../chart/container/legend_container.dart';
import '../../../chart/container/root_container.dart';
//import '../../../chart/container_new/container_common.dart';
//import '../../../chart/container_new/data_container.dart';
//import '../../../chart/container_new/axis_container.dart';
//import '../../../chart/container_new/line/root_container.dart';
//import '../../../chart/container_new/bar/root_container.dart';
import '../../../chart/model/data_model.dart';
import '../../../chart/view_maker.dart';
import '../../../chart/options.dart';
import '../../../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
import 'presenter.dart'; // OLD

/// The container-hierarchy root container of the line chart in the coded_layout legacy version.
class LineChartRootContainerCL extends ChartRootContainerCL implements ChartRootContainer {
  LineChartRootContainerCL({
    required LegendContainer legendContainer,
    required XContainerCL xContainer,
    required YContainerCL yContainerFirst,
    required YContainerCL yContainer,
    required DataContainerCL dataContainer,
    required ChartViewMaker chartViewMaker,
    required ChartModel chartModel,
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
          chartModel: chartModel,
          isStacked: isStacked,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        ) {
    (chartViewMaker as SwitchChartViewMakerCL).pointPresenterCreator = LineAndHotspotLeafPointPresenterCreator();
  }
}
