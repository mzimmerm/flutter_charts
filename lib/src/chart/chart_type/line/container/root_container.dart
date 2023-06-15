// base libraries
import '../../../container/root_container.dart';
import '../../../container/axis_and_grid_container.dart';
import '../../../container/data_container.dart';
import '../../../container/legend_container.dart';
import '../../../view_model/view_model.dart';


/// The container-hierarchy root container of the line chart.
class LineChartRootContainer extends ChartRootContainer {
  LineChartRootContainer({
    required LegendContainer    legendContainer,
    required TransposingAxisOrGrid      inputAxisContainer,
    required TransposingAxisOrGrid      outputAxisContainerFirst,
    required TransposingAxisOrGrid      outputAxisContainer,
    required DataContainer   dataContainer,
    required ChartViewModel  chartViewModel,
  }) : super(
    legendContainer: legendContainer,
    inputAxisContainer: inputAxisContainer,
    outputAxisContainerFirst: outputAxisContainerFirst,
    outputAxisContainer: outputAxisContainer,
    dataContainer: dataContainer,
    chartViewModel: chartViewModel,
    );

}
