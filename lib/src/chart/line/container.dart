import 'package:flutter_charts/src/chart/options.dart';
import 'package:flutter_charts/src/chart/data.dart';
import 'package:flutter_charts/src/chart/iterative_layout_strategy.dart'
    as strategy show LabelLayoutStrategy;
import '../container.dart';

import 'presenter.dart';

/// Container of the line chart.
///
/// The core override is setting the [presenterCreator] -
/// object which makes instances of [LineAndHotspotPresenter]s,
/// used to present each data value.
class LineChartContainer extends ChartContainer {
  LineChartContainer({
    required ChartData chartData,
    required ChartOptions chartOptions,
    required strategy.LabelLayoutStrategy xContainerLabelLayoutStrategy,
  }) : super(
          chartData: chartData,
          chartOptions: chartOptions,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        ) {
    presenterCreator = new LineAndHotspotLeafCreator();
  }
}
