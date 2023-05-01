// base libraries
import '../root_container.dart';
import '../axis_container.dart';
import '../data_container.dart';
import '../legend_container.dart';
import '../../view_maker.dart';

/// The container-hierarchy root container of the vertical bar chart.
class BarChartRootContainer extends ChartRootContainer {

  BarChartRootContainer({
    required LegendContainer legendContainer,
    required TransposingAxisContainer horizontalAxisContainer,
    required TransposingAxisContainer verticalAxisContainerFirst,
    required TransposingAxisContainer verticalAxisContainer,
    required DataContainer dataContainer,
    required ChartViewMaker chartViewMaker,
  }) : super(
          legendContainer: legendContainer,
          horizontalAxisContainer: horizontalAxisContainer,
          verticalAxisContainerFirst: verticalAxisContainerFirst,
          verticalAxisContainer: verticalAxisContainer,
          dataContainer: dataContainer,
          chartViewMaker: chartViewMaker,
        );
}
