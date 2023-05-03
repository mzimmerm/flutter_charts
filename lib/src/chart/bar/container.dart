// base libraries
import '../container/data_container.dart';
import '../view_model.dart';

class BarChartDataContainer extends DataContainer {
  BarChartDataContainer({
    required ChartViewModel chartViewModel,
  }) : super(
    chartViewModel: chartViewModel,
  );
}

