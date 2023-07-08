import 'package:logger/logger.dart' as logger;

// base libraries
// import 'package:flutter_charts/src/chart/cartesian/container/legend_container.dart';
import 'package:flutter_charts/test/src/chart/cartesian/container/legend_container.dart' as testing_legend_container;
import 'package:flutter_charts/src/chart/cartesian/container/axislabels_axislines_gridlines_container.dart';
import 'package:flutter_charts/src/chart/view_model/view_model.dart';
import 'package:flutter_charts/src/switch_view_model/auto_layout/line/view_model.dart' as line_chart_view_model;
import 'package:flutter_charts/src/chart/model/data_model.dart';
import 'package:flutter_charts/src/chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
import 'package:flutter_charts/src/chart/cartesian/chart_type/line/container/data_container.dart';

import 'package:flutter_charts/src/chart/cartesian/chart_type/line/container/root_container.dart';

// this level: switch/auto_layout/bar
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';

/// Concrete [ChartViewModel] for [LineChart].
///
/// See [ChartViewModel] for help.
class SwitchLineChartViewModel extends line_chart_view_model.SwitchLineChartViewModel {
  SwitchLineChartViewModel({
    required ChartModel chartModel,
    required ChartType chartType,
    required ChartOrientation chartOrientation,
    required ChartStacking chartStacking,
    required LiveOrTesting liveOrTesting,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) : super(
    chartModel: chartModel,
    chartType: chartType,
    chartOrientation: chartOrientation,
    chartStacking: chartStacking,
    liveOrTesting: liveOrTesting,
    inputLabelLayoutStrategy: inputLabelLayoutStrategy,
  ) {
    logger.Logger().d('$runtimeType created');
  }

  /// Concrete implementation returns the root for vertical bar chart.
  @override
  LineChartRootContainer makeChartRootContainer({required ChartViewModel chartViewModel}) {
    return LineChartRootContainer(
      legendContainer: testing_legend_container.LegendContainer(chartViewModel: this),
      horizontalAxisContainer: TransposingAxisLabels.HorizontalAxis(chartViewModel: this),
      verticalAxisContainerFirst: TransposingAxisLabels.VerticalAxis(chartViewModel: this),
      verticalAxisContainer: TransposingAxisLabels.VerticalAxis(chartViewModel: this),
      dataContainer: LineChartDataContainer(chartViewModel: this),
      chartViewModel: chartViewModel,
    );
  }

}
