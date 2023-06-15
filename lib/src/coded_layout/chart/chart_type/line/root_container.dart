// base libraries
import '../../../../switch_view_model/view_model_cl.dart';
import '../../container.dart';
import '../../axis_container.dart';
import '../../data_container.dart';
import '../../../../chart/container/legend_container.dart';
import '../../../../chart/container/root_container.dart';
import '../../../../chart/view_model/view_model.dart';

// this level
import 'presenter.dart'; // OLD

/// The container-hierarchy root container of the line chart in the coded_layout legacy version.
class LineChartRootContainerCL extends ChartRootContainerCL implements ChartRootContainer {
  LineChartRootContainerCL({
    required LegendContainer legendContainer,
    required InputAxisContainerCL inputAxisContainer,
    required OutputAxisContainerCL outputAxisContainerFirst,
    required OutputAxisContainerCL outputAxisContainer,
    required DataContainerCL dataContainer,
    required ChartViewModel chartViewModel,
  }) : super(
          legendContainer: legendContainer,
          inputAxisContainer: inputAxisContainer,
          outputAxisContainerFirst: outputAxisContainerFirst,
          outputAxisContainer: outputAxisContainer,
          dataContainer: dataContainer,
          chartViewModel: chartViewModel,
        ) {
    (chartViewModel as SwitchChartViewModelCL).pointPresenterCreator = LineAndHotspotLeafPointPresenterCreator();
  }
}
