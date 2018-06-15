import 'dart:ui' as ui show Size;

import 'package:flutter_charts/src/chart/options.dart';
import 'package:flutter_charts/src/chart/data.dart';
import 'package:flutter_charts/src/chart/iterative_layout_strategy.dart'
  as strategy show LabelLayoutStrategy;
import '../container.dart';

import 'presenter.dart';


/// Container of the vertical bar chart.
///
/// The core override is setting the [presenterCreator] -
/// object which makes instances of [VerticalBarPresenter]s,
/// used to present each data value.
class VerticalBarChartContainer extends ChartContainer {
  VerticalBarChartContainer({
    ui.Size chartArea,
    ChartData chartData,
    ChartOptions chartOptions,
    strategy.LabelLayoutStrategy xContainerLabelLayoutStrategy,
  })
      : super(
    chartArea: chartArea,
    chartData: chartData,
    chartOptions: chartOptions,
    xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
  ) {
    presenterCreator = new VerticalBarLeafCreator();
  }
}
