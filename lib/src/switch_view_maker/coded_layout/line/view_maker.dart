import 'package:logger/logger.dart' as logger;

// base libraries
import '../../../chart/view_maker.dart';
import '../../../coded_layout/chart/container.dart';
import '../../../chart/model/data_model_new.dart';

import '../../../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

// this level
import '../../../coded_layout/chart/line/container.dart';

import '../../view_maker_cl.dart'; // OLD

class SwitchLineChartViewMakerCL extends SwitchChartViewMakerCL {
  SwitchLineChartViewMakerCL({
    required ChartModel chartModel,
    required bool isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
          chartModel: chartModel,
          isStacked: false, // only supported for now for line chart
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        ) {
    logger.Logger().d('$runtimeType created');
  }

  @override
  LineChartRootContainerCL makeViewRoot({required ChartViewMaker chartViewMaker}) {
    var legendContainer = makeViewForLegendContainer();
    var xContainer = makeViewForDomainAxis();
    var yContainerFirst = makeViewForYContainerFirst();
    var yContainer = makeViewForRangeAxis();
    var dataContainer = makeViewForDataContainer();

    // todo-00-switch-remove : assert(isUseOldDataContainer == true);

    return LineChartRootContainerCL(
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
    return LineChartDataContainerCL(
      chartViewMaker: this,
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