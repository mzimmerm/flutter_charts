// base libraries
import '../../../container/root_container.dart';
import '../../../container/axis_and_grid_container.dart';
import '../../../container/data_container.dart';
import '../../../container/legend_container.dart';
import '../../../view_model/view_model.dart';

/// The container-hierarchy root container of the vertical bar chart.
class BarChartRootContainer extends ChartRootContainer {

  BarChartRootContainer({
    required LegendContainer legendContainer,
    required TransposingAxisLabelsOrGridLines inputAxisContainer,
    required TransposingAxisLabelsOrGridLines outputAxisContainerFirst,
    required TransposingAxisLabelsOrGridLines outputAxisContainer,
    required DataContainer dataContainer,
    required ChartViewModel chartViewModel,
  }) : super(
          legendContainer: legendContainer,
          inputAxisContainer: inputAxisContainer,
          outputAxisContainerFirst: outputAxisContainerFirst,
          outputAxisContainer: outputAxisContainer,
          dataContainer: dataContainer,
          chartViewModel: chartViewModel,
        );
}
