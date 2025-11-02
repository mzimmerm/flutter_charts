import 'package:logger/logger.dart' as logger;

import 'package:flutter_charts/src/chart/model/data_model.dart';
import 'package:flutter_charts/src/chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
// ChartViewModel passed to makeChartRootContainer is from auto_layout
import 'package:flutter_charts/src/chart/cartesian/view_model/view_model.dart' show ChartViewModel;

import 'package:flutter_charts/src/coded_layout/chart/cartesian/view_model/coded_layout_view_model.dart';
import 'package:flutter_charts/src/coded_layout/chart/cartesian/chart_type/line/root_container.dart';
import 'package:flutter_charts/src/coded_layout/chart/axis_container.dart';
import 'package:flutter_charts/src/coded_layout/chart/data_container.dart';

import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';

import 'package:flutter_charts/test/src/chart/cartesian/container/legend_container.dart' as test_legend_container;

// parent live package
import 'package:flutter_charts/src/coded_layout/chart/cartesian/view_model/line/coded_layout_line_view_model.dart' as live_line_view_model;

class LineChartViewModelCL extends live_line_view_model.LineChartViewModelCL {
  LineChartViewModelCL({
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
  LineChartRootContainerCL makeChartRootContainer({required ChartViewModel chartViewModel}) {
    return LineChartRootContainerCL(
      legendContainer: test_legend_container.LegendContainer(chartViewModel: this),
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

  @override
  bool get extendAxisToOrigin => true;
}
