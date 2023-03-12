// base libraries
import '../root_container_new.dart';
import '../axis_container_new.dart';
import '../data_container_new.dart';
import '../legend_container_new.dart';
import '../../model/data_model_new.dart';
import '../../view_maker.dart';
import '../../options.dart';
import '../../iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

/// The container-hierarchy root container of the vertical bar chart.
class NewVerticalBarChartRootContainer extends NewChartRootContainer {

  NewVerticalBarChartRootContainer({
    required LegendContainer legendContainer,
    required NewXContainer xContainer,
    required NewYContainer yContainerFirst,
    required NewYContainer yContainer,
    required NewDataContainer dataContainer,
    required ChartViewMaker chartViewMaker,
    required NewModel chartData,
    required ChartOptions chartOptions,
    required bool isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
          legendContainer: legendContainer,
          xContainer: xContainer,
          yContainerFirst: yContainerFirst,
          yContainer: yContainer,
          dataContainer: dataContainer,
          chartViewMaker: chartViewMaker,
          chartData: chartData,
          isStacked: isStacked,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        );
}
