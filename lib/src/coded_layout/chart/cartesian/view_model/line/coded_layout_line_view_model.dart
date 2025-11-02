import 'package:logger/logger.dart' as logger;


// todo-00-last-remove
// import '../../../../../../test/src/chart/cartesian/container/legend_container.dart' as test_legend_container;


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
      // todo-00-done: legendContainer: test_legend_container.LegendContainer(chartViewModel: this),
      legendContainer: legend_container.LegendContainer.liveLegendIsRowStartTightItemIsRowStartTightDefault(
          chartViewModel: this
      ),

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
