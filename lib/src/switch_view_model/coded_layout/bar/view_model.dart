import 'package:logger/logger.dart' as logger;

// base libraries
import '../../../chart/view_model.dart';
import '../../../chart/container/legend_container.dart';
import '../../../coded_layout/chart/axis_container.dart';
import '../../../coded_layout/chart/data_container.dart';
import '../../../chart/model/data_model.dart';

import '../../../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
import '../../../coded_layout/chart/bar/root_container.dart';

import '../../../morphic/container/chart_support/chart_style.dart';
import '../../view_model_cl.dart'; // OLD

class SwitchBarChartViewModelCL extends SwitchChartViewModelCL {
  SwitchBarChartViewModelCL({
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
  BarChartRootContainerCL makeChartRootContainer({required ChartViewModel chartViewModel}) {
    return BarChartRootContainerCL(
      legendContainer: LegendContainer(chartViewModel: this),
      horizontalAxisContainer: HorizontalAxisContainerCL(chartViewModel: this),
      verticalAxisContainerFirst: VerticalAxisContainerCL(chartViewModel: this),
      verticalAxisContainer: VerticalAxisContainerCL(chartViewModel: this),
      dataContainer: BarChartDataContainerCL(chartViewModel: this),
      chartViewModel: chartViewModel,
    );
  }

  @override
  bool get extendAxisToOrigin => true;
}