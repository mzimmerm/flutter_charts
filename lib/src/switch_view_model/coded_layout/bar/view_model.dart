import 'package:logger/logger.dart' as logger;

// this level
import 'package:flutter_charts/src/coded_layout/chart/chart_type/bar/root_container.dart';

// base libraries
import 'package:flutter_charts/src/chart/view_model/view_model.dart';
import 'package:flutter_charts/src/chart/cartesian/container/legend_container.dart';
import 'package:flutter_charts/src/coded_layout/chart/axis_container.dart';
import 'package:flutter_charts/src/coded_layout/chart/data_container.dart';
import 'package:flutter_charts/src/chart/model/data_model.dart';
import 'package:flutter_charts/src/chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

import 'package:flutter_charts/src/switch_view_model/view_model_cl.dart'; // OLD
import 'package:flutter_charts/src/switch_view_model/view_model.dart' show directionWrapperAroundCL;

import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';

class SwitchBarChartViewModelCL extends SwitchChartViewModelCL {
  SwitchBarChartViewModelCL({
    required ChartModel chartModel,
    required ChartType chartType,
    required ChartOrientation chartOrientation,
    required ChartStacking chartStacking,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) : super(
          chartModel: chartModel,
          chartType: chartType,
          chartOrientation: chartOrientation,
          chartStacking: chartStacking,
          inputLabelLayoutStrategy: inputLabelLayoutStrategy,
        ) {
    logger.Logger().d('$runtimeType created');
  }

  @override
  BarChartRootContainerCL makeChartRootContainer({required ChartViewModel chartViewModel}) {
    return BarChartRootContainerCL(
      legendContainer: LegendContainer(chartViewModel: this),
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
      dataContainer: BarChartDataContainerCL(chartViewModel: this),
      chartViewModel: chartViewModel,
    );
  }

  @override
  bool get extendAxisToOrigin => true;
}
