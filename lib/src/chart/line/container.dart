// base libraries
import '../container.dart';
import '../container_new/legend_container_new.dart';
import '../model/data_model_new.dart';
import '../view_maker.dart';

import '../options.dart';
import '../iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
// import 'data_container_new.dart';
import 'presenter.dart'; // OLD

/// Container of the line chart.
///
/// The core override is setting the [pointPresenterCreator] -
/// object which makes instances of [LineAndHotspotPointPresenter]s,
/// which are, in turn, used to present each data value.
class LineChartRootContainer extends ChartRootContainer {
  LineChartRootContainer({
    required LegendContainer legendContainer,
    required XContainer xContainer,
    required YContainer yContainerFirst,
    required YContainer yContainer,
    required DataContainer dataContainer,
    required ChartViewMaker chartViewMaker,
    required NewModel chartData,
    required bool isStacked,
    required ChartOptions chartOptions,
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
        ) {
    chartViewMaker.pointPresenterCreator = LineAndHotspotLeafPointPresenterCreator();
  }
}
