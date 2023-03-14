import 'package:logger/logger.dart' as logger;

// base libraries
import '../../../chart/view_maker.dart';
import '../../../coded_layout/chart/container.dart';
import '../../../chart/model/data_model_new.dart';

import '../../../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
import '../../../coded_layout/chart/bar/container.dart';

import '../../view_maker_cl.dart'; // OLD

class SwitchVerticalBarChartViewMakerCL extends SwitchChartViewMakerCL {
  SwitchVerticalBarChartViewMakerCL({
    required ChartModel chartModel,
    required bool isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
          chartModel: chartModel,
          isStacked: true, // only supported for now for bar chart
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        ) {
    logger.Logger().d('$runtimeType created');
  }

  @override
  VerticalBarChartRootContainerCL makeViewRoot({required ChartViewMaker chartViewMaker}) {
    var legendContainer = makeViewForLegendContainer();
    var xContainer = makeViewForDomainAxis();
    var yContainerFirst = makeViewForYContainerFirst();
    var yContainer = makeViewForRangeAxis();
    var dataContainer = makeViewForDataContainer();

    // todo-00-switch-remove : assert(isUseOldDataContainer == true);

    return VerticalBarChartRootContainerCL(
      legendContainer: legendContainer,
      xContainer: xContainer,
      yContainerFirst: yContainerFirst,
      yContainer: yContainer,
      dataContainer: dataContainer,
      chartViewMaker: chartViewMaker,
      chartModel: chartModel,
      chartOptions: chartViewMaker.chartOptions,
      isStacked: isStacked,
      xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
    );
  }

  @override
  DataContainerCL makeViewForDataContainer() {
    // todo-00-switch-remove : assert(isUseOldDataContainer == true);
    return VerticalBarChartDataContainerCL(
      chartViewMaker: this,
    );
  }

  @override
  bool get extendAxisToOrigin => true;
}