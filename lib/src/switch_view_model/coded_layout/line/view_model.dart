import 'package:logger/logger.dart' as logger;

// base libraries
import '../../../chart/view_model/view_model.dart';
import '../../../chart/container/legend_container.dart';
import '../../../coded_layout/chart/axis_container.dart';
import '../../../coded_layout/chart/data_container.dart';
import '../../../chart/model/data_model.dart';

import '../../../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
import '../../../coded_layout/chart/chart_type/line/root_container.dart';

import '../../../morphic/container/chart_support/chart_style.dart';
import '../../view_model_cl.dart'; // OLD
import '../../view_model.dart' show directionWrapperAroundCL;

class SwitchLineChartViewModelCL extends SwitchChartViewModelCL {
  SwitchLineChartViewModelCL({
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
  LineChartRootContainerCL makeChartRootContainer({required ChartViewModel chartViewModel}) {
    return LineChartRootContainerCL(
      legendContainer: LegendContainer(chartViewModel: this),
      inputAxisContainer: InputAxisContainerCL(
        chartViewModel: this,
        directionWrapperAround: directionWrapperAroundCL,
      ),
      outputAxisContainerFirst: OutputAxisContainerCL(
        chartViewModel: this,
        directionWrapperAround: directionWrapperAroundCL,
        isShowOutputAxisLine: false,
      ),
      outputAxisContainer: OutputAxisContainerCL(
        chartViewModel: this,
        directionWrapperAround: directionWrapperAroundCL,
        isShowOutputAxisLine: false,
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
