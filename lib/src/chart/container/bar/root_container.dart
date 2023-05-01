// base libraries
import '../root_container.dart';
import '../axis_container.dart';
import '../data_container.dart';
import '../legend_container.dart';
import '../../model/data_model.dart';
import '../../view_maker.dart';
import '../../iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

/// The container-hierarchy root container of the vertical bar chart.
class BarChartRootContainer extends ChartRootContainer {

  BarChartRootContainer({
    required LegendContainer legendContainer,
    required TransposingAxisContainer horizontalAxisContainer,
    required TransposingAxisContainer verticalAxisContainerFirst,
    required TransposingAxisContainer verticalAxisContainer,
    required DataContainer dataContainer,
    required ChartViewMaker chartViewMaker,
    required ChartModel chartModel,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) : super(
          legendContainer: legendContainer,
          horizontalAxisContainer: horizontalAxisContainer,
          verticalAxisContainerFirst: verticalAxisContainerFirst,
          verticalAxisContainer: verticalAxisContainer,
          dataContainer: dataContainer,
          chartViewMaker: chartViewMaker,
          chartModel: chartModel,
          inputLabelLayoutStrategy: inputLabelLayoutStrategy,
        );
}
