// base libraries
import '../../../switch_view_maker/view_maker_cl.dart';
import '../container.dart';
import '../../../chart/container/legend_container.dart';
import '../../../chart/container/root_container.dart';
import '../../../chart/model/data_model.dart';
import '../../../chart/view_maker.dart';
import '../../../chart/options.dart';
import '../../../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
import 'presenter.dart'; // OLD

/// The container-hierarchy root container of the line chart in the coded_layout legacy version.
class LineChartRootContainerCL extends ChartRootContainerCL implements ChartRootContainer {
  LineChartRootContainerCL({
    required LegendContainer legendContainer,
    required HorizontalAxisContainerCL horizontalAxisContainer,
    required VerticalAxisContainerCL verticalAxisContainerFirst,
    required VerticalAxisContainerCL verticalAxisContainer,
    required DataContainerCL dataContainer,
    required ChartViewMaker chartViewMaker,
    required ChartModel chartModel,
    required ChartOptions chartOptions,
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
        ) {
    (chartViewMaker as SwitchChartViewMakerCL).pointPresenterCreator = LineAndHotspotLeafPointPresenterCreator();
  }
}
