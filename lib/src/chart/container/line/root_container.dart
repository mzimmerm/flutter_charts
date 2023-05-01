// base libraries
import '../root_container.dart';
import '../axis_container.dart';
import '../data_container.dart';
import '../legend_container.dart';
import '../../view_maker.dart';


/// The container-hierarchy root container of the line chart.
class LineChartRootContainer extends ChartRootContainer {
  LineChartRootContainer({
    required LegendContainer    legendContainer,
    required TransposingAxisContainer      horizontalAxisContainer,
    required TransposingAxisContainer      verticalAxisContainerFirst,
    required TransposingAxisContainer      verticalAxisContainer,
    required DataContainer   dataContainer,
    required ChartViewMaker  chartViewMaker,
  }) : super(
    legendContainer: legendContainer,
    horizontalAxisContainer: horizontalAxisContainer,
    verticalAxisContainerFirst: verticalAxisContainerFirst,
    verticalAxisContainer: verticalAxisContainer,
    dataContainer: dataContainer,
    chartViewMaker: chartViewMaker,
    );

}
