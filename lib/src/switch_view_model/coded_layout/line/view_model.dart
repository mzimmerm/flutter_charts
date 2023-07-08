import 'package:logger/logger.dart' as logger;

// base libraries
import 'package:flutter_charts/src/chart/view_model/view_model.dart';
import 'package:flutter_charts/src/coded_layout/chart/axis_container.dart';
import 'package:flutter_charts/src/coded_layout/chart/data_container.dart';
import 'package:flutter_charts/src/chart/model/data_model.dart';

import 'package:flutter_charts/src/chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
import 'package:flutter_charts/src/coded_layout/chart/chart_type/line/root_container.dart';

import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';
import 'package:flutter_charts/src/switch_view_model/view_model_cl.dart'; // OLD
import 'package:flutter_charts/src/switch_view_model/view_model.dart' show directionWrapperAroundCL;

import 'package:flutter_charts/test/src/chart/cartesian/container/legend_container.dart' as testing_legend_container;

class SwitchLineChartViewModelCL extends SwitchChartViewModelCL {
  SwitchLineChartViewModelCL({
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

  @override
  LineChartRootContainerCL makeChartRootContainer({required ChartViewModel chartViewModel}) {
    return LineChartRootContainerCL(
      legendContainer: testing_legend_container.LegendContainer(chartViewModel: this),
      horizontalAxisContainer: HorizontalAxisContainerCL(
        chartViewModel: this,
        directionWrapperAround: directionWrapperAroundCL,
      ),
      verticalAxisContainerFirst: OutputAxisContainerCL(
        chartViewModel: this,
        directionWrapperAround: directionWrapperAroundCL,
      ),
      verticalAxisContainer: OutputAxisContainerCL(
        chartViewModel: this,
        directionWrapperAround: directionWrapperAroundCL,
      ),
      dataContainer: LineChartDataContainerCL(chartViewModel: this),
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
