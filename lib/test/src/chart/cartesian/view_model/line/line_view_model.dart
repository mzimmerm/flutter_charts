import 'package:logger/logger.dart' as logger;


// base libraries
import 'package:flutter_charts/src/chart/cartesian/container/axislabels_axislines_gridlines_container.dart';
import 'package:flutter_charts/src/chart/cartesian/view_model/view_model.dart' show ChartViewModel;
import 'package:flutter_charts/src/chart/model/data_model.dart';
import 'package:flutter_charts/src/chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
import 'package:flutter_charts/src/chart/cartesian/chart_type/line/container/data_container.dart';

import 'package:flutter_charts/src/chart/cartesian/chart_type/line/container/root_container.dart';

// this level: switch/auto_layout/bar
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';

import 'package:flutter_charts/test/src/chart/cartesian/container/legend_container.dart' as test_legend_container;

// parent live package
import 'package:flutter_charts/src/chart/cartesian/view_model/line/line_view_model.dart' as live_line_view_model;


/// Concrete [ChartViewModel] for [LineChart].
///
/// See [ChartViewModel] for help.
class LineChartViewModel extends live_line_view_model.LineChartViewModel {
  LineChartViewModel({
    required ChartModel chartModel,
    required ChartOrientation chartOrientation,
    required ChartStacking chartStacking,
    required strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
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
      legendContainer: test_legend_container.LegendContainer(
          chartViewModel: this
      ),
      horizontalAxisContainer: TransposingAxisLabels.HorizontalAxis(
          chartViewModel: this
      ),
      verticalAxisContainerFirstCL: TransposingAxisLabels.VerticalAxis(
          chartViewModel: this
      ),
      verticalAxisContainer: TransposingAxisLabels.VerticalAxis(
          chartViewModel: this
      ),
      dataContainer: LineChartDataContainer(
          chartViewModel: this
      ),
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
