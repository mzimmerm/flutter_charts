import 'package:logger/logger.dart' as logger;

// base libraries
import '../../../chart/view_maker.dart';
// todo-00-last-last-done : import '../../../chart/container/data_container.dart';
import '../../../chart/container/legend_container.dart';
// todo-00-last-last-done : import '../../../chart/container/axis_container.dart';
import '../../../coded_layout/chart/container.dart';
import '../../../chart/model/data_model.dart';

import '../../../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
import '../../../coded_layout/chart/line/container.dart';

import '../../../morphic/container/chart_support/chart_style.dart';
import '../../view_maker_cl.dart'; // OLD

class SwitchLineChartViewMakerCL extends SwitchChartViewMakerCL {
  SwitchLineChartViewMakerCL({
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

  @override
  LineChartRootContainerCL makeChartRootContainer({required ChartViewMaker chartViewMaker}) {
    return LineChartRootContainerCL(
      legendContainer: LegendContainer(chartViewMaker: this),
      horizontalAxisContainer: HorizontalAxisContainerCL(chartViewMaker: this),
      verticalAxisContainerFirst: VerticalAxisContainerCL(chartViewMaker: this),
      verticalAxisContainer: VerticalAxisContainerCL(chartViewMaker: this),
      dataContainer: LineChartDataContainerCL(chartViewMaker: this),
      chartViewMaker: chartViewMaker,
      chartModel: chartModel,
      inputLabelLayoutStrategy: inputLabelLayoutStrategy,
    );
  }

/* todo-00-last-last-last-done
  @override
  DataContainerCL makeViewForDataContainer() {
    return LineChartDataContainerCL(chartViewMaker: this);
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
