// base libraries
import '../container/data_container.dart';
import '../view_model.dart';

class LineChartDataContainer extends DataContainer {
  LineChartDataContainer({
    required ChartViewModel chartViewModel,
  }) : super(
    chartViewModel: chartViewModel,
  );
}

