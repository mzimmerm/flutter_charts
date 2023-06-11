import 'package:logger/logger.dart' as logger;

import '../../../chart/container/legend_container.dart';
import '../../../chart/container/axis_and_grid_container.dart';

// base libraries
import '../../../chart/view_model/view_model.dart';
import '../../../morphic/container/chart_support/chart_style.dart';
import '../../../chart/chart_type/bar/container/root_container.dart';
import '../../../chart/model/data_model.dart';
import '../../../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
// import '../../../chart/bar/container_delete.dart';
import '../../../chart/chart_type/bar/container/data_container.dart';

// this level: switch/auto_layout/bar
import '../../view_model.dart'; // NEW SWITCH

/// Concrete [ChartViewModel] for [BarChart].
///
/// See [ChartViewModel] for help.
class SwitchBarChartViewModel extends SwitchChartViewModel {
  SwitchBarChartViewModel({
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
  BarChartRootContainer makeChartRootContainer({required ChartViewModel chartViewModel}) {
    return BarChartRootContainer(
      legendContainer: LegendContainer(chartViewModel: this),
      horizontalAxisContainer: TransposingAxisOrGrid.HorizontalAxis(chartViewModel: this),
      verticalAxisContainerFirst: TransposingAxisOrGrid.VerticalAxis(chartViewModel: this),
      verticalAxisContainer: TransposingAxisOrGrid.VerticalAxis(chartViewModel: this),
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
