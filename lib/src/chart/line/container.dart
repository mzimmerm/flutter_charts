// base libraries
import '../container/data_container.dart';
import '../view_maker.dart';

class LineChartDataContainer extends DataContainer {
  LineChartDataContainer({
    required ChartViewMaker chartViewMaker,
  }) : super(
    chartViewMaker: chartViewMaker,
  );
}

