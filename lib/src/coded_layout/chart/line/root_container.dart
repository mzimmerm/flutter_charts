// base libraries
import '../../../switch_view_maker/view_maker_cl.dart';
import '../container.dart';
import '../axis_container.dart';
import '../data_container.dart';
import '../../../chart/container/legend_container.dart';
import '../../../chart/container/root_container.dart';
import '../../../chart/view_maker.dart';

// this level
import 'presenter.dart'; // OLD

/// The container-hierarchy root container of the line chart in the coded_layout legacy version.
class LineChartRootContainerCL extends ChartRootContainerCL implements ChartRootContainer {
  LineChartRootContainerCL({
    required LegendContainer legendContainer,
    required HorizontalAxisContainerCL horizontalAxisContainer,
    required VerticalAxisContainerCL verticalAxisContainerFirst,
    required VerticalAxisContainerCL verticalAxisContainer,
    required DataContainerCL dataContainer,
    required ChartViewMaker chartViewMaker,
  }) : super(
          legendContainer: legendContainer,
          horizontalAxisContainer: horizontalAxisContainer,
          verticalAxisContainerFirst: verticalAxisContainerFirst,
          verticalAxisContainer: verticalAxisContainer,
          dataContainer: dataContainer,
          chartViewMaker: chartViewMaker,
        ) {
    (chartViewMaker as SwitchChartViewMakerCL).pointPresenterCreator = LineAndHotspotLeafPointPresenterCreator();
  }
}
