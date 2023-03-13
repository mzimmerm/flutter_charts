// base libraries
import '../root_container_new.dart';
import '../axis_container_new.dart';
import '../data_container_new.dart';
import '../legend_container_new.dart';
import '../../model/data_model_new.dart';
import '../../view_maker.dart';
import '../../options.dart';
import '../../iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;


/// The container-hierarchy root container of the line chart.
class LineChartRootContainer extends ChartRootContainer {
  LineChartRootContainer({
    required LegendContainer    legendContainer,
    required XContainer      xContainer,
    required YContainer      yContainerFirst,
    required YContainer      yContainer,
    required DataContainer   dataContainer,
    required ChartViewMaker  chartViewMaker,
    required ChartModel        chartModel,
    required ChartOptions    chartOptions,
    required bool            isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
    legendContainer: legendContainer,
    xContainer: xContainer,
    yContainerFirst: yContainerFirst,
    yContainer: yContainer,
    dataContainer: dataContainer,
    chartViewMaker: chartViewMaker,
          chartModel: chartModel,
          isStacked: isStacked,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        );

}
