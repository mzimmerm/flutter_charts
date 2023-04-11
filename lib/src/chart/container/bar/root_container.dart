// base libraries
import '../root_container.dart';
import '../axis_container.dart';
import '../data_container.dart';
import '../legend_container.dart';
import '../../model/data_model.dart';
import '../../view_maker.dart';
import '../../options.dart';
import '../../iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

/// The container-hierarchy root container of the vertical bar chart.
class VerticalBarChartRootContainer extends ChartRootContainer {

  VerticalBarChartRootContainer({
    required LegendContainer legendContainer,
    /* todo-00-last-done
    required XContainer xContainer,
    required YContainer yContainerFirst,
    required YContainer yContainer,
    */
    required TransposingAxisContainer xContainer,
    required TransposingAxisContainer yContainerFirst,
    required TransposingAxisContainer yContainer,
    required DataContainer dataContainer,
    required ChartViewMaker chartViewMaker,
    required ChartModel chartModel,
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
          chartModel: chartModel,
          isStacked: isStacked,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        );
}
