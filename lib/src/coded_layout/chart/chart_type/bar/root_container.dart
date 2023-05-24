// base libraries
import '../../container.dart';
import '../../axis_container.dart';
import '../../data_container.dart';
import '../../../../switch_view_model/view_model_cl.dart';
import '../../../../chart/container/legend_container.dart';
import '../../../../chart/container/root_container.dart';
import '../../../../chart/view_model/view_model.dart';

// this level
import 'presenter.dart'; // OLD


/// The container-hierarchy root container of the vertical bar chart in the coded_layout legacy version.
class BarChartRootContainerCL extends ChartRootContainerCL implements ChartRootContainer {
  BarChartRootContainerCL({
    required LegendContainer legendContainer,
    required HorizontalAxisContainerCL      horizontalAxisContainer,
    required VerticalAxisContainerCL      verticalAxisContainerFirst,
    required VerticalAxisContainerCL      verticalAxisContainer,
    required DataContainerCL   dataContainer,
    required ChartViewModel  chartViewModel,
  }) : super(
    legendContainer: legendContainer,
    horizontalAxisContainer: horizontalAxisContainer,
    verticalAxisContainerFirst: verticalAxisContainerFirst,
    verticalAxisContainer: verticalAxisContainer,
    dataContainer: dataContainer,
    chartViewModel: chartViewModel,
  ) {
    (chartViewModel as SwitchChartViewModelCL).pointPresenterCreator = VerticalBarLeafPointPresenterCreator();
  }

}
