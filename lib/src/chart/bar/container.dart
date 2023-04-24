// base libraries
import '../container/data_container.dart';
import '../view_maker.dart';

class BarChartDataContainer extends DataContainer {
  BarChartDataContainer({
    required ChartViewMaker chartViewMaker,
  }) : super(
    chartViewMaker: chartViewMaker,
  );
}

