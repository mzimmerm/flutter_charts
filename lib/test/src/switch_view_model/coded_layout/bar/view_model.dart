// import 'package:logger/logger.dart' as logger;

import 'package:flutter_charts/test/src/chart/cartesian/container/legend_container.dart' as testing_legend_container;
import 'package:flutter_charts/src/chart/cartesian/container/axislabels_axislines_gridlines_container.dart';

// base libraries
import 'package:flutter_charts/src/chart/view_model/view_model.dart';
import 'package:flutter_charts/src/switch_view_model/auto_layout/bar/view_model.dart' as bar_chart_view_model;
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';
import 'package:flutter_charts/src/chart/cartesian/chart_type/bar/container/root_container.dart';
import 'package:flutter_charts/src/chart/model/data_model.dart';
import 'package:flutter_charts/src/chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
import 'package:flutter_charts/src/chart/cartesian/chart_type/bar/container/data_container.dart';

/// Concrete [ChartViewModel] for [BarChart].
///
/// See [ChartViewModel] for help.
class SwitchBarChartViewModel extends bar_chart_view_model.SwitchBarChartViewModel {
  SwitchBarChartViewModel({
    required ChartModel chartModel,
    required ChartType chartType,
    required ChartOrientation chartOrientation,
    required LiveOrTesting liveOrTesting,
    required ChartStacking chartStacking,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) : super(
    chartModel: chartModel,
    chartType: chartType,
    chartOrientation: chartOrientation,
    chartStacking: chartStacking,
    liveOrTesting: liveOrTesting,
    inputLabelLayoutStrategy: inputLabelLayoutStrategy,
  );

  /// Concrete implementation returns the root for vertical bar chart.
  @override
  BarChartRootContainer makeChartRootContainer({required ChartViewModel chartViewModel}) {
    return BarChartRootContainer(
      legendContainer: testing_legend_container.LegendContainer(chartViewModel: this),
      horizontalAxisContainer: TransposingAxisLabels.HorizontalAxis(chartViewModel: this),
      verticalAxisContainerFirst: TransposingAxisLabels.VerticalAxis(chartViewModel: this),
      verticalAxisContainer: TransposingAxisLabels.VerticalAxis(chartViewModel: this),
      dataContainer: BarChartDataContainer(chartViewModel: this),
      chartViewModel: chartViewModel,
    );
  }

}
