import 'package:logger/logger.dart' as logger;


// base libraries
import '../../../chart/container_new/line/root_container_new.dart';
//import '../../../chart/container_new/bar/root_container_new.dart';
import '../../../chart/container_new/data_container_new.dart';
import '../../../chart/view_maker.dart';
import '../../../chart/model/data_model_new.dart';
import '../../../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
import '../../../chart/line/container_new.dart'; // NEW BASE

// this level: switch/auto_layout/bar
import '../../view_maker.dart'; // NEW SWITCH

/// Concrete [ChartViewMaker] for [LineChart].
///
/// See [ChartViewMaker] for help.
class SwitchLineChartViewMaker extends SwitchChartViewMaker {
  SwitchLineChartViewMaker({
    required NewModel chartData,
    required bool isStacked,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
    chartData: chartData,
    isStacked: false, // only supported for now for line chart
    xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
  ) {
    logger.Logger().d('$runtimeType created');
  }

  /// Concrete implementation returns the root for vertical bar chart.
  @override
// todo-00-last-last-done :   LineChartRootContainerCL makeViewRoot({required ChartViewMaker chartViewMaker}) {
  NewLineChartRootContainer makeViewRoot({required ChartViewMaker chartViewMaker}) {
    var legendContainer = makeViewForLegendContainer();
    var xContainer = makeViewForDomainAxis();
    var yContainerFirst = makeViewForYContainerFirst();
    var yContainer = makeViewForRangeAxis();
    var dataContainer = makeViewForDataContainer();

    // todo-00-last-last-last-done : assert(isUseOldDataContainer == false);

    return NewLineChartRootContainer(
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
  NewDataContainer makeViewForDataContainer() {
    // todo-00-last-last-last-done : assert(isUseOldDataContainer == false);

    return NewLineChartDataContainer(
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
