import 'package:logger/logger.dart' as logger;

// base libraries
import '../../../chart/view_maker.dart';
import '../../../chart/container/legend_container.dart';
import '../../../coded_layout/chart/axis_container.dart';
import '../../../coded_layout/chart/data_container.dart';
import '../../../chart/model/data_model.dart';

import '../../../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
import '../../../coded_layout/chart/bar/root_container.dart';

import '../../../morphic/container/chart_support/chart_style.dart';
import '../../view_maker_cl.dart'; // OLD

class SwitchBarChartViewMakerCL extends SwitchChartViewMakerCL {
  SwitchBarChartViewMakerCL({
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
  BarChartRootContainerCL makeChartRootContainer({required ChartViewMaker chartViewMaker}) {
    return BarChartRootContainerCL(
      legendContainer: LegendContainer(chartViewMaker: this),
      horizontalAxisContainer: HorizontalAxisContainerCL(chartViewMaker: this),
      verticalAxisContainerFirst: VerticalAxisContainerCL(chartViewMaker: this),
      verticalAxisContainer: VerticalAxisContainerCL(chartViewMaker: this),
      dataContainer: BarChartDataContainerCL(chartViewMaker: this),
      chartViewMaker: chartViewMaker,
      chartModel: chartModel,
      chartOptions: chartViewMaker.chartOptions,
      inputLabelLayoutStrategy: inputLabelLayoutStrategy,
    );
  }

  @override
  bool get extendAxisToOrigin => true;
}
