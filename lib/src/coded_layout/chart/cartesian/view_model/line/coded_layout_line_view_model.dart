import 'package:logger/logger.dart' as logger;

// base libraries
import 'package:flutter_charts/src/chart/model/data_model.dart';
import 'package:flutter_charts/src/chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
import 'package:flutter_charts/src/chart/cartesian/view_model/view_model.dart' show ChartViewModel; // auto_layout
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';
import 'package:flutter_charts/src/chart/cartesian/container/legend_container.dart' as legend_container;

// base coded_layout libraries
import 'package:flutter_charts/src/coded_layout/chart/cartesian/view_model/coded_layout_view_model.dart';
import 'package:flutter_charts/src/coded_layout/chart/cartesian/chart_type/line/root_container.dart';
import 'package:flutter_charts/src/coded_layout/chart/axis_container.dart';
import 'package:flutter_charts/src/coded_layout/chart/data_container.dart';


class LineChartViewModelCL extends ChartViewModelCL {
  LineChartViewModelCL({
    required ChartModel chartModel,
    // todo-00-done: required ChartType chartType,
    required ChartOrientation chartOrientation,
    required ChartStacking chartStacking,
    strategy.LabelLayoutStrategy? inputLabelLayoutStrategy,
  }) : super(
    chartModel: chartModel,
    // todo-00-done: chartType: chartType,
    chartOrientation: chartOrientation,
    chartStacking: chartStacking,
    inputLabelLayoutStrategy: inputLabelLayoutStrategy,
  ) {
    logger.Logger().d('$runtimeType created');
  }

  @override
  LineChartRootContainerCL makeChartRootContainer({required ChartViewModel chartViewModel}) {
    return LineChartRootContainerCL(
      legendContainer: legend_container.LegendContainer.wrappingRow(
          chartViewModel: this
      ),
      horizontalAxisContainer: HorizontalAxisContainerCL(
        chartViewModel: this,
        directionWrapperAround: directionWrapperAroundCL,
      ),
      verticalAxisContainerFirstCL: OutputAxisContainerCL(
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
