import 'package:logger/logger.dart' as logger;

import 'package:flutter_charts/src/chart/cartesian/container/legend_container.dart';
import 'package:flutter_charts/src/chart/cartesian/container/axislabels_axislines_gridlines_container.dart';

// base libraries
import 'package:flutter_charts/src/chart/view_model/view_model.dart';
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';
import 'package:flutter_charts/src/chart/cartesian/chart_type/bar/container/root_container.dart';
import 'package:flutter_charts/src/chart/model/data_model.dart';
import 'package:flutter_charts/src/chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
import 'package:flutter_charts/src/chart/cartesian/chart_type/bar/container/data_container.dart';

// this level: switch/auto_layout/bar
import 'package:flutter_charts/src/switch_view_model/view_model.dart'; // NEW SWITCH

/// Concrete [ChartViewModel] for [BarChart].
///
/// See [ChartViewModel] for help.
class SwitchBarChartViewModel extends SwitchChartViewModel {
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
  ) {
    logger.Logger().d('$runtimeType created');
  }

  /// Concrete implementation returns the root for vertical bar chart.
  @override
  BarChartRootContainer makeChartRootContainer({required ChartViewModel chartViewModel}) {
    return BarChartRootContainer(
      legendContainer: LegendContainer(chartViewModel: this),
      horizontalAxisContainer: TransposingAxisLabels.HorizontalAxis(chartViewModel: this),
      verticalAxisContainerFirst: TransposingAxisLabels.VerticalAxis(chartViewModel: this),
      verticalAxisContainer: TransposingAxisLabels.VerticalAxis(chartViewModel: this),
      dataContainer: BarChartDataContainer(chartViewModel: this),
      chartViewModel: chartViewModel,
    );
  }

  /// Implements [ChartBehavior] mixin abstract method.
  ///
  /// Overridden to [false] on this bar chart container, where the y axis must start from 0.
  ///
  @override
  bool get extendAxisToOrigin => true;
}
