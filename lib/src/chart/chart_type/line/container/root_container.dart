// base libraries
import '../../../container/root_container.dart';
import '../../../container/axis_container.dart';
import '../../../container/data_container.dart';
import '../../../container/legend_container.dart';
import '../../../view_model.dart';


/// The container-hierarchy root container of the line chart.
class LineChartRootContainer extends ChartRootContainer {
  LineChartRootContainer({
    required LegendContainer    legendContainer,
    required TransposingAxisContainer      horizontalAxisContainer,
    required TransposingAxisContainer      verticalAxisContainerFirst,
    required TransposingAxisContainer      verticalAxisContainer,
    required DataContainer   dataContainer,
    required ChartViewModel  chartViewModel,
  }) : super(
    legendContainer: legendContainer,
    horizontalAxisContainer: horizontalAxisContainer,
    verticalAxisContainerFirst: verticalAxisContainerFirst,
    verticalAxisContainer: verticalAxisContainer,
    dataContainer: dataContainer,
    chartViewModel: chartViewModel,
    );

}
