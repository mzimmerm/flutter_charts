// base libraries
import '../container.dart';
import '../../../switch_view_maker/view_maker_cl.dart';
import '../../../chart/container/legend_container.dart';
import '../../../chart/container/root_container.dart';
import '../../../chart/model/data_model.dart';
import '../../../chart/view_maker.dart';
import '../../../chart/options.dart';
import '../../../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
import 'presenter.dart'; // OLD


/// The container-hierarchy root container of the vertical bar chart in the coded_layout legacy version.
class BarChartRootContainerCL extends ChartRootContainerCL implements ChartRootContainer {
  BarChartRootContainerCL({
    required LegendContainer legendContainer,
    required HorizontalAxisContainerCL      horizontalAxisContainer,
    required VerticalAxisContainerCL      verticalAxisContainerFirst,
    required VerticalAxisContainerCL      verticalAxisContainer,
    required DataContainerCL   dataContainer,
    required ChartViewMaker  chartViewMaker,
    required ChartModel        chartModel,
    required ChartOptions    chartOptions,
    required bool            isStacked,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) : super(
    legendContainer: legendContainer,
    horizontalAxisContainer: horizontalAxisContainer,
    verticalAxisContainerFirst: verticalAxisContainerFirst,
    verticalAxisContainer: verticalAxisContainer,
    dataContainer: dataContainer,
    chartViewMaker: chartViewMaker,
          chartModel: chartModel,
          isStacked: isStacked,
          inputLabelLayoutStrategy: inputLabelLayoutStrategy,
        ) {
    (chartViewMaker as SwitchChartViewMakerCL).pointPresenterCreator = VerticalBarLeafPointPresenterCreator();
  }

}
