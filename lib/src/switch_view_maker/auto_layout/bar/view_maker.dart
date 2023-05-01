import 'package:logger/logger.dart' as logger;

import '../../../chart/container/legend_container.dart';
import '../../../chart/container/axis_container.dart';

// base libraries
import '../../../chart/view_maker.dart';
import '../../../morphic/container/chart_support/chart_style.dart';
import '../../../chart/container/bar/root_container.dart';
import '../../../chart/model/data_model.dart';
import '../../../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
import '../../../chart/bar/container.dart';

// this level: switch/auto_layout/bar
import '../../view_maker.dart'; // NEW SWITCH

/// Concrete [ChartViewMaker] for [BarChart].
///
/// See [ChartViewMaker] for help.
class SwitchBarChartViewMaker extends SwitchChartViewMaker {
  SwitchBarChartViewMaker({
    required ChartModel chartModel,
    required ChartOrientation chartOrientation,
    required ChartStacking chartStacking,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) : super(
    chartModel: chartModel,
    chartOrientation: chartOrientation,
    chartStacking: chartStacking,
    inputLabelLayoutStrategy: inputLabelLayoutStrategy,
  ) {
    logger.Logger().d('$runtimeType created');
  }

  /// Concrete implementation returns the root for vertical bar chart.
  @override
  BarChartRootContainer makeChartRootContainer({required ChartViewMaker chartViewMaker}) {
    return BarChartRootContainer(
      legendContainer: LegendContainer(chartViewMaker: this),
      horizontalAxisContainer: TransposingAxisContainer.Horizontal(chartViewMaker: this),
      verticalAxisContainerFirst: TransposingAxisContainer.Vertical(chartViewMaker: this),
      verticalAxisContainer: TransposingAxisContainer.Vertical(chartViewMaker: this),
      dataContainer: BarChartDataContainer(chartViewMaker: this),
      chartViewMaker: chartViewMaker,
      chartModel: chartModel,
      inputLabelLayoutStrategy: inputLabelLayoutStrategy,
    );
  }

  /// Implements [ChartBehavior] mixin abstract method.
  ///
  /// Overridden to [false] on this bar chart container, where the y axis must start from 0.
  ///
  @override
  bool get extendAxisToOrigin => true;
}
