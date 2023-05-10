// base libraries
import '../../../container/root_container.dart';
import '../../../container/axis_container.dart';
import '../../../container/data_container.dart';
import '../../../container/legend_container.dart';
import '../../../view_model.dart';

/// The container-hierarchy root container of the vertical bar chart.
class BarChartRootContainer extends ChartRootContainer {

  BarChartRootContainer({
    required LegendContainer legendContainer,
    required TransposingAxisContainer horizontalAxisContainer,
    required TransposingAxisContainer verticalAxisContainerFirst,
    required TransposingAxisContainer verticalAxisContainer,
    required DataContainer dataContainer,
    required ChartViewModel chartViewModel,
  }) : super(
          legendContainer: legendContainer,
          horizontalAxisContainer: horizontalAxisContainer,
          verticalAxisContainerFirst: verticalAxisContainerFirst,
          verticalAxisContainer: verticalAxisContainer,
          dataContainer: dataContainer,
          chartViewModel: chartViewModel,
        );
}
