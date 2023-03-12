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
    required NewModel chartData,
    required bool isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
          chartData: chartData,
          isStacked: true, // only supported for now
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        ) {
    logger.Logger().d('$runtimeType created');
  }

  @override
  // todo-00-last-last-done :   LineChartRootContainerCL makeViewRoot({required ChartViewMaker chartViewMaker}) {
  LineChartRootContainerCL makeViewRoot({required ChartViewMaker chartViewMaker}) {
    var legendContainer = makeViewForLegendContainer();
    var xContainer = makeViewForDomainAxis();
    var yContainerFirst = makeViewForYContainerFirst();
    var yContainer = makeViewForRangeAxis();
    var dataContainer = makeViewForDataContainer();

    // todo-00-last-last-last-done : assert(isUseOldDataContainer == true);

    return LineChartRootContainerCL(
      legendContainer: legendContainer,
      xContainer: xContainer,
      yContainerFirst: yContainerFirst,
      yContainer: yContainer,
      dataContainer: dataContainer,
      chartViewMaker: chartViewMaker,
      chartData: chartData,
      chartOptions: chartViewMaker.chartOptions,
      isStacked: isStacked,
      xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
    );
  }

  @override
  DataContainerCL makeViewForDataContainer() {
    // todo-00-last-last-last-done : assert(isUseOldDataContainer == true);
    // todo-00-last-last : rename to CL
    return LineChartDataContainer(
      chartViewMaker: this,
    );
  }

  @override
  bool get extendAxisToOrigin => true;
}
