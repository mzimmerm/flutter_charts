import 'package:logger/logger.dart' as logger;


// base libraries
import '../../../chart/container/legend_container.dart';
import '../../../chart/container/axis_and_grid_container.dart';
import '../../../chart/view_model/view_model.dart';
import '../../../chart/model/data_model.dart';
import '../../../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
// import '../../../chart/line/container_delete.dart';
// import '../../../chart/container/line/data_container.dart';
import '../../../chart/chart_type/line/container/data_container.dart';

import '../../../chart/chart_type/line/container/root_container.dart';

// this level: switch/auto_layout/bar
import '../../../morphic/container/chart_support/chart_style.dart';
import '../../view_model.dart'; // NEW SWITCH

/// Concrete [ChartViewModel] for [LineChart].
///
/// See [ChartViewModel] for help.
class SwitchLineChartViewModel extends SwitchChartViewModel {
  SwitchLineChartViewModel({
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
  LineChartRootContainer makeChartRootContainer({required ChartViewModel chartViewModel}) {
    return LineChartRootContainer(
      legendContainer: LegendContainer(chartViewModel: this),
      horizontalAxisContainer: TransposingAxis.HorizontalAxis(chartViewModel: this),
      verticalAxisContainerFirst: TransposingAxis.VerticalAxis(chartViewModel: this),
      verticalAxisContainer: TransposingAxis.VerticalAxis(chartViewModel: this),
      dataContainer: LineChartDataContainer(chartViewModel: this),
      chartViewModel: chartViewModel,
    );
  }

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
