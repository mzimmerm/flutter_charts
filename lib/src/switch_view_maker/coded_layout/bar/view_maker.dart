import 'package:logger/logger.dart' as logger;

// base libraries
import '../../../chart/view_maker.dart';
import '../../../coded_layout/chart/container.dart';
import '../../../chart/model/data_model.dart';

import '../../../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
import '../../../coded_layout/chart/bar/container.dart';

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
  BarChartRootContainerCL makeViewRoot({required ChartViewMaker chartViewMaker}) {
    var legendContainer = makeViewForLegendContainer();
    var horizontalAxisContainer = makeViewForHorizontalAxis();
    var verticalAxisContainerFirst = makeViewForVerticalAxisContainerFirst();
    var verticalAxisContainer = makeViewForVerticalAxis();
    var dataContainer = makeViewForDataContainer();

    return BarChartRootContainerCL(
      legendContainer: legendContainer,
      horizontalAxisContainer: horizontalAxisContainer,
      verticalAxisContainerFirst: verticalAxisContainerFirst,
      verticalAxisContainer: verticalAxisContainer,
      dataContainer: dataContainer,
      chartViewMaker: chartViewMaker,
      chartModel: chartModel,
      chartOptions: chartViewMaker.chartOptions,
      isStacked: isStacked,
      inputLabelLayoutStrategy: inputLabelLayoutStrategy,
    );
  }

  @override
  DataContainerCL makeViewForDataContainer() {
    return BarChartDataContainerCL(
      chartViewMaker: this,
    );
  }

  @override
  bool get extendAxisToOrigin => true;
}
