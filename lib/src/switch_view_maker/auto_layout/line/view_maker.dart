import 'package:logger/logger.dart' as logger;


// base libraries
// todo-00-last-last-done : import '../../../chart/container/data_container.dart';
import '../../../chart/container/legend_container.dart';
import '../../../chart/container/axis_container.dart';
import '../../../chart/view_maker.dart';
import '../../../chart/model/data_model.dart';
import '../../../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
import '../../../chart/line/container.dart'; // NEW BASE
import '../../../chart/container/line/root_container.dart';

// this level: switch/auto_layout/bar
import '../../../morphic/container/chart_support/chart_style.dart';
import '../../view_maker.dart'; // NEW SWITCH

/// Concrete [ChartViewMaker] for [LineChart].
///
/// See [ChartViewMaker] for help.
class SwitchLineChartViewMaker extends SwitchChartViewMaker {
  SwitchLineChartViewMaker({
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
  LineChartRootContainer makeChartRootContainer({required ChartViewMaker chartViewMaker}) {
    return LineChartRootContainer(
      legendContainer: LegendContainer(chartViewMaker: this),
      horizontalAxisContainer: TransposingAxisContainer.Horizontal(chartViewMaker: this),
      verticalAxisContainerFirst: TransposingAxisContainer.Vertical(chartViewMaker: this),
      verticalAxisContainer: TransposingAxisContainer.Vertical(chartViewMaker: this),
      dataContainer: LineChartDataContainer(chartViewMaker: this),
      chartViewMaker: chartViewMaker,
      chartModel: chartModel,
      chartOptions: chartViewMaker.chartOptions,
      inputLabelLayoutStrategy: inputLabelLayoutStrategy,
    );
  }

/* todo-00-last-last-last-done
  @override
  DataContainer makeViewForDataContainer() {
    return LineChartDataContainer(chartViewMaker: this,);
  }
*/

  /// Implements [ChartBehavior] mixin abstract method.
  ///
  /// If resolved to [true], Y axis will start on the minimum of Y values, otherwise at [0.0].
  ///
  /// This is the method used in code logic when building the Y labels and axis.
  ///
  /// The related variable [DataContainerOptions.extendAxisToOriginRequested],
  /// is merely a request that may not be granted in some situations.
  ///
  /// On this line chart container, allow the y axis start from 0 if requested by options.
  @override
  bool get extendAxisToOrigin => chartOptions.dataContainerOptions.extendAxisToOriginRequested;
}
